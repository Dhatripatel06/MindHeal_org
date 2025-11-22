import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../../data/models/emotion_result.dart';
import '../../onnx_emotion_detection/data/services/onnx_emotion_service.dart';

/// State management for real-time emotion detection
class EmotionProvider with ChangeNotifier {
  final OnnxEmotionService _emotionService = OnnxEmotionService.instance;

  // Detection state
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isLoading = false;
  String? _error;

  // Current results
  EmotionResult? _currentResult;
  List<EmotionResult> _emotionHistory = [];

  // Detection settings
  bool _realTimeDetection = false;
  Duration _detectionInterval = const Duration(milliseconds: 1000); // 1 second
  int _maxHistorySize = 50;
  double _confidenceThreshold = 0.3;

  // Camera integration
  CameraController? _cameraController;
  Timer? _detectionTimer;
  bool _cameraInitialized = false;

  // Performance metrics
  int _totalDetections = 0;
  int _averageProcessingTime = 0;
  List<int> _recentProcessingTimes = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isDetecting => _isDetecting;
  bool get isLoading => _isLoading;
  String? get error => _error;
  EmotionResult? get currentResult => _currentResult;
  List<EmotionResult> get emotionHistory => List.unmodifiable(_emotionHistory);
  bool get realTimeDetection => _realTimeDetection;
  Duration get detectionInterval => _detectionInterval;
  double get confidenceThreshold => _confidenceThreshold;
  bool get cameraInitialized => _cameraInitialized;
  CameraController? get cameraController => _cameraController;
  int get totalDetections => _totalDetections;
  int get averageProcessingTime => _averageProcessingTime;

  /// Get available emotion labels from the service
  List<String> get emotionLabels => _emotionService.emotionClasses;

  /// Get current dominant emotion
  String get currentEmotion => _currentResult?.emotion ?? 'none';

  /// Get current confidence
  double get currentConfidence => _currentResult?.confidence ?? 0.0;

  /// Get current emotion confidence map
  Map<String, double> get currentEmotions => _currentResult?.allEmotions ?? {};

  /// Initialize the emotion detection service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      print('🚀 Initializing emotion detection service...');
      _isInitialized = await _emotionService.initialize();
      print('✅ Emotion detection service initialized successfully');
    } catch (e) {
      _setError('Failed to initialize emotion detection: $e');
      print('❌ Failed to initialize emotion detection: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Initialize camera for real-time detection
  Future<void> initializeCamera([CameraDescription? camera]) async {
    if (_cameraInitialized || _cameraController != null) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Default to front camera if available
      final selectedCamera = camera ??
          cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          );

      // Initialize camera controller
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // Ensure JPEG output
      );

      await _cameraController!.initialize();
      _cameraInitialized = true;

      print('📷 Camera initialized successfully');
    } catch (e) {
      _setError('Failed to initialize camera: $e');
      print('❌ Failed to initialize camera: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Start real-time emotion detection
  Future<void> startRealTimeDetection() async {
    if (!_isInitialized) {
      throw Exception('Service not initialized. Call initialize() first.');
    }

    if (!_cameraInitialized || _cameraController == null) {
      throw Exception('Camera not initialized. Call initializeCamera() first.');
    }

    if (_realTimeDetection) return;

    try {
      _realTimeDetection = true;
      _isDetecting = true;
      _clearError();

      // Start periodic detection
      _detectionTimer = Timer.periodic(_detectionInterval, (_) {
        _captureAndDetect();
      });

      print(
          '🎯 Real-time emotion detection started (interval: ${_detectionInterval.inMilliseconds}ms)');
    } catch (e) {
      _setError('Failed to start real-time detection: $e');
      print('❌ Failed to start real-time detection: $e');
    }

    notifyListeners();
  }

  /// Stop real-time emotion detection
  void stopRealTimeDetection() {
    if (!_realTimeDetection) return;

    _detectionTimer?.cancel();
    _detectionTimer = null;
    _realTimeDetection = false;
    _isDetecting = false;

    print('⏹️ Real-time emotion detection stopped');
    notifyListeners();
  }

  /// Capture image and detect emotion
  Future<void> _captureAndDetect() async {
    if (!_realTimeDetection ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();

      // Run detection
      await detectEmotionFromFile(File(imageFile.path));

      // Clean up temporary file
      try {
        await File(imageFile.path).delete();
      } catch (e) {
        print('⚠️ Failed to delete temporary image: $e');
      }
    } catch (e) {
      print('⚠️ Error in real-time detection: $e');
    }
  }

  /// Detect emotion from image file
  Future<EmotionResult?> detectEmotionFromFile(File imageFile) async {
    if (!_isInitialized) {
      throw Exception('Service not initialized. Call initialize() first.');
    }

    try {
      final imageBytes = await imageFile.readAsBytes();

      final result = _emotionHistory.isNotEmpty
          ? await _emotionService.detectEmotionsRealTime(imageBytes,
              previousResult: _emotionHistory.last, stabilizationFactor: 0.3)
          : await _emotionService.detectEmotions(imageBytes);

      // Update state if confidence meets threshold
      if (result.confidence >= _confidenceThreshold) {
        _updateCurrentResult(result);
        _addToHistory(result);
        _updatePerformanceMetrics(result.processingTimeMs);
      }

      print(
          '🎯 Detected: ${result.emotion} (${(result.confidence * 100).toStringAsFixed(1)}%) in ${result.processingTimeMs}ms');

      return result;
    } catch (e) {
      final errorResult = EmotionResult.error('Detection failed: $e');
      _setError(e.toString());
      print('❌ Error detecting emotion: $e');
      return errorResult;
    }
  }

  /// Manually trigger single detection
  Future<EmotionResult?> captureAndDetectEmotion() async {
    if (!_cameraInitialized || _cameraController == null) {
      throw Exception('Camera not initialized');
    }

    try {
      _setLoading(true);
      _clearError();

      final XFile imageFile = await _cameraController!.takePicture();
      final result = await detectEmotionFromFile(File(imageFile.path));

      try {
        await File(imageFile.path).delete();
      } catch (e) {
        print('⚠️ Failed to delete temporary image: $e');
      }

      return result;
    } catch (e) {
      _setError('Failed to capture and detect emotion: $e');
      print('❌ Failed to capture and detect emotion: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update detection settings
  void updateDetectionInterval(Duration interval) {
    _detectionInterval = interval;
    if (_realTimeDetection) {
      stopRealTimeDetection();
      startRealTimeDetection();
    }
    notifyListeners();
  }

  /// Update confidence threshold
  void updateConfidenceThreshold(double threshold) {
    _confidenceThreshold = threshold.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Clear emotion history
  void clearHistory() {
    _emotionHistory.clear();
    _totalDetections = 0;
    _averageProcessingTime = 0;
    _recentProcessingTimes.clear();
    notifyListeners();
  }

  /// Get emotion statistics
  Map<String, dynamic> getEmotionStatistics() {
    if (_emotionHistory.isEmpty) {
      return {
        'totalDetections': 0,
        'emotionCounts': <String, int>{},
        'averageConfidence': 0.0,
        'averageProcessingTime': 0,
        'dominantEmotion': 'none',
      };
    }

    final emotionCounts = <String, int>{};
    double totalConfidence = 0.0;

    for (final result in _emotionHistory) {
      if (!result.hasError) {
        emotionCounts[result.emotion] =
            (emotionCounts[result.emotion] ?? 0) + 1;
        totalConfidence += result.confidence;
      }
    }

    final dominantEmotion = emotionCounts.isNotEmpty
        ? emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'none';

    return {
      'totalDetections': _totalDetections,
      'emotionCounts': emotionCounts,
      'averageConfidence':
          _totalDetections > 0 ? totalConfidence / _totalDetections : 0.0,
      'averageProcessingTime': _averageProcessingTime,
      'dominantEmotion': dominantEmotion,
    };
  }

  /// Private methods
  void _updateCurrentResult(EmotionResult result) {
    _currentResult = result;
    notifyListeners();
  }

  void _addToHistory(EmotionResult result) {
    _emotionHistory.add(result);
    if (_emotionHistory.length > _maxHistorySize) {
      _emotionHistory.removeAt(0);
    }
    _totalDetections++;
  }

  void _updatePerformanceMetrics(int processingTime) {
    _recentProcessingTimes.add(processingTime);
    if (_recentProcessingTimes.length > 20) {
      _recentProcessingTimes.removeAt(0);
    }
    _averageProcessingTime = _recentProcessingTimes.isEmpty
        ? 0
        : _recentProcessingTimes.reduce((a, b) => a + b) ~/
            _recentProcessingTimes.length;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    stopRealTimeDetection();
    _cameraController?.dispose();
    // Do not dispose the singleton service here
    // _emotionService.dispose(); 
    super.dispose();
  }
}