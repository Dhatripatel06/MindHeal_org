import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/signal_processing_service.dart';
import '../../../../shared/models/heart_rate_measurement.dart';

enum MeasurementState {
  idle,
  initializing,
  measuring,
  processing,
  completed,
  error,
}

class CameraHeartRateProvider extends ChangeNotifier {
  CameraController? _controller;
  bool _isDisposed = false;

  MeasurementState _state = MeasurementState.idle;
  String _statusMessage = 'Tap to start measurement';
  int _currentBPM = 0;
  double _confidence = 0.0;
  List<double> _waveformData = [];
  int _measurementProgress = 0;

  final SignalProcessingService _signalProcessor = SignalProcessingService();
  Timer? _measurementTimer;
  StreamSubscription<CameraImage>? _imageSubscription;

  static const int _measurementDuration = 15; // seconds
  static const int _frameSkip = 2; // Process every 3rd frame for performance
  int _frameCounter = 0;

  // Getters
  MeasurementState get state => _state;
  String get statusMessage => _statusMessage;
  int get currentBPM => _currentBPM;
  double get confidence => _confidence;
  List<double> get waveformData => _waveformData;
  int get measurementProgress => _measurementProgress;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  CameraController? get controller => _controller;

  /// Initialize camera with flashlight
  Future<void> initializeCamera() async {
    if (_isDisposed) return;

    try {
      _updateState(MeasurementState.initializing, 'Initializing camera...');

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Use back camera
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.low, // Low resolution for better performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      // Enable flashlight
      if (_controller!.value.flashMode != FlashMode.torch) {
        await _controller!.setFlashMode(FlashMode.torch);
      }

      _updateState(MeasurementState.idle, 'Ready to measure');
    } catch (e) {
      _updateState(MeasurementState.error, 'Camera initialization failed: $e');
    }
  }

  /// Start heart rate measurement
  Future<void> startMeasurement() async {
    if (_isDisposed ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    try {
      _updateState(MeasurementState.measuring,
          'Place finger over camera and flashlight');

      // Reset data
      _signalProcessor.reset();
      _currentBPM = 0;
      _confidence = 0.0;
      _measurementProgress = 0;
      _frameCounter = 0;

      // Start image stream processing
      await _controller!.startImageStream(_processImage);

      // Start measurement timer
      _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isDisposed) {
          timer.cancel();
          return;
        }

        _measurementProgress = timer.tick;

        // Calculate BPM every 3 seconds after initial 3 seconds
        if (_measurementProgress >= 3 && _measurementProgress % 3 == 0) {
          _calculateCurrentBPM();
        }

        _updateState(MeasurementState.measuring,
            'Measuring... ${_measurementProgress}/${_measurementDuration}s');

        if (_measurementProgress >= _measurementDuration) {
          _completeMeasurement();
        }
      });
    } catch (e) {
      _updateState(MeasurementState.error, 'Measurement failed: $e');
    }
  }

  /// Stop measurement
  Future<void> stopMeasurement() async {
    _measurementTimer?.cancel();
    _measurementTimer = null;

    if (_controller != null) {
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        debugPrint('Error stopping image stream: $e');
      }
    }

    _updateState(MeasurementState.idle, 'Measurement stopped');
  }

  /// Process camera image for heart rate detection
  void _processImage(CameraImage image) {
    if (_isDisposed || _state != MeasurementState.measuring) return;

    // Skip frames for performance
    if (_frameCounter % _frameSkip != 0) {
      _frameCounter++;
      return;
    }
    _frameCounter++;

    // Extract red channel intensity on background thread
    compute(_extractRedIntensity, image).then((intensity) {
      if (_isDisposed || _state != MeasurementState.measuring) return;

      // Add data point to signal processor
      _signalProcessor.addDataPoint(intensity);

      // Update waveform data for UI
      _waveformData = _signalProcessor.getWaveformData();
      notifyListeners();
    }).catchError((error) {
      debugPrint('Error processing image: $error');
    });
  }

  /// Extract red channel intensity from camera image
  static double _extractRedIntensity(CameraImage image) {
    try {
      // Convert YUV420 to RGB and extract red channel
      final int width = image.width;
      final int height = image.height;
      final Uint8List yPlane = image.planes[0].bytes;
      final Uint8List uPlane = image.planes[2].bytes;
      final Uint8List vPlane = image.planes[1].bytes;

      // Sample from center region (50x50 pixels)
      final int centerX = width ~/ 2;
      final int centerY = height ~/ 2;
      final int sampleSize = 25;

      double totalRed = 0;
      int pixelCount = 0;

      for (int y = centerY - sampleSize; y < centerY + sampleSize; y++) {
        for (int x = centerX - sampleSize; x < centerX + sampleSize; x++) {
          if (x >= 0 && x < width && y >= 0 && y < height) {
            final int yIndex = y * width + x;
            final int uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

            // YUV to RGB conversion
            final int yValue = yPlane[yIndex];
            // final int uValue = uPlane[uvIndex] - 128; // Unused
            final int vValue = vPlane[uvIndex] - 128;

            // Convert to RGB
            int red = (yValue + (1.402 * vValue)).round().clamp(0, 255);

            totalRed += red;
            pixelCount++;
          }
        }
      }

      return pixelCount > 0 ? totalRed / pixelCount : 0;
    } catch (e) {
      debugPrint('Error extracting red intensity: $e');
      return 0;
    }
  }

  /// Calculate current BPM
  void _calculateCurrentBPM() {
    final result = _signalProcessor.calculateBPM();
    _currentBPM = result.bpm;
    _confidence = result.confidence;

    // Update status message based on confidence
    if (_confidence > 0.7) {
      _statusMessage = 'Good signal quality';
    } else if (_confidence > 0.4) {
      _statusMessage = 'Keep finger steady';
    } else {
      _statusMessage = 'Adjust finger position';
    }

    notifyListeners();
  }

  /// Complete measurement
  Future<void> _completeMeasurement() async {
    await stopMeasurement();

    _updateState(MeasurementState.processing, 'Processing results...');

    // Wait a moment for UI feedback
    await Future.delayed(const Duration(seconds: 1));

    final result = _signalProcessor.calculateBPM();
    _currentBPM = result.bpm;
    _confidence = result.confidence;

    if (_currentBPM > 0 && _confidence > 0.3) {
      _updateState(MeasurementState.completed, 'Measurement complete!');
    } else {
      _updateState(
          MeasurementState.error, 'Measurement failed. Please try again.');
    }
  }

  /// Get final measurement result
  HeartRateMeasurement? getFinalResult() {
    if (_state != MeasurementState.completed || _currentBPM <= 0) {
      return null;
    }

    return HeartRateMeasurement(
      userId: '', // Will be set by the service
      bpm: _currentBPM,
      method: MeasurementMethod.camera,
      timestamp: DateTime.now(),
      confidenceScore: _confidence,
      metadata: {
        'measurement_duration': _measurementDuration,
        'data_points': _signalProcessor.getWaveformData().length,
      },
    );
  }

  /// Reset to initial state
  void reset() {
    _measurementTimer?.cancel();
    _measurementTimer = null;

    if (_controller != null) {
      try {
        _controller!.stopImageStream();
      } catch (e) {
        debugPrint('Error stopping image stream during reset: $e');
      }
    }

    _signalProcessor.reset();
    _currentBPM = 0;
    _confidence = 0.0;
    _waveformData.clear();
    _measurementProgress = 0;

    _updateState(MeasurementState.idle, 'Ready to measure');
  }

  /// Update state and status message
  void _updateState(MeasurementState newState, String message) {
    if (_isDisposed) return;

    _state = newState;
    _statusMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _measurementTimer?.cancel();
    _imageSubscription?.cancel();

    if (_controller != null) {
      try {
        _controller!.stopImageStream();
        _controller!.setFlashMode(FlashMode.off);
        _controller!.dispose();
      } catch (e) {
        debugPrint('Error disposing camera controller: $e');
      }
    }

    super.dispose();
  }
}
