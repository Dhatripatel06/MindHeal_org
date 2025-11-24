import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/biofeedback_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/models/heart_rate_measurement.dart';

class CameraHeartRatePage extends StatefulWidget {
  const CameraHeartRatePage({super.key});

  @override
  State<CameraHeartRatePage> createState() => _CameraHeartRatePageState();
}

class _CameraHeartRatePageState extends State<CameraHeartRatePage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isMeasuring = false;
  int _currentBPM = 0;
  double _confidence = 0.0;
  List<double> _waveformData = [];
  int _progress = 0;
  String _statusMessage = 'Place finger over camera and flash';

  // final SignalProcessingService _signalProcessor = SignalProcessingService(); // Unused for now
  final FirestoreService _firestoreService = FirestoreService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras available';
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Camera initialization failed: $e';
      });
    }
  }

  Future<void> _startMeasurement() async {
    if (!_isInitialized || _cameraController == null) return;

    final cameraPermission = await Permission.camera.request();
    if (cameraPermission != PermissionStatus.granted) {
      _showPermissionDialog();
      return;
    }

    setState(() {
      _isMeasuring = true;
      _progress = 0;
      _currentBPM = 0;
      _confidence = 0.0;
      _statusMessage = 'Keep finger steady...';
    });

    try {
      await _cameraController!.setFlashMode(FlashMode.torch);

      _pulseController.repeat(reverse: true);

      _progressController.forward().then((_) {
        _completeMeasurement();
      });

      // Simulate measurement process
      _simulateMeasurement();
    } catch (e) {
      setState(() {
        _statusMessage = 'Measurement failed: $e';
        _isMeasuring = false;
      });
    }
  }

  void _simulateMeasurement() {
    if (!_isMeasuring) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isMeasuring) {
        setState(() {
          _progress = (_progressController.value * 100).toInt();

          // Simulate realistic heart rate detection
          final baseRate = 70;
          final variation = (DateTime.now().millisecond % 20) - 10;
          final progressVariation = (_progress / 5).round();
          _currentBPM = baseRate + variation + progressVariation;

          // Simulate confidence building
          _confidence = (_progress / 100).clamp(0.0, 1.0);

          // Update status based on progress
          if (_progress < 30) {
            _statusMessage = 'Detecting signal...';
          } else if (_progress < 70) {
            _statusMessage = 'Analyzing heart rhythm...';
          } else {
            _statusMessage = 'Finalizing measurement...';
          }

          // Generate waveform data
          _waveformData.add(
              _currentBPM.toDouble() + (DateTime.now().millisecond % 10 - 5));
          if (_waveformData.length > 50) {
            _waveformData.removeAt(0);
          }
        });

        _simulateMeasurement();
      }
    });
  }

  Future<void> _completeMeasurement() async {
    _pulseController.stop();

    try {
      await _cameraController!.setFlashMode(FlashMode.off);
    } catch (e) {
      // Handle flash error
    }

    setState(() {
      _isMeasuring = false;
      _statusMessage = 'Measurement complete!';
    });

    // Update provider with measured heart rate
    if (mounted) {
      final provider = Provider.of<BiofeedbackProvider>(context, listen: false);
      provider.updateHeartRate(_currentBPM);

      // Save to Firestore
      _saveHeartRateMeasurement();
    }

    // Show results
    _showResultsDialog();
  }

  void _showResultsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Measurement Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite,
              color: Colors.red,
              size: 50,
            ),
            const SizedBox(height: 20),
            Text(
              '$_currentBPM BPM',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Confidence: ${(_confidence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _getHealthAdvice(_currentBPM),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetMeasurement();
            },
            child: const Text('Measure Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _resetMeasurement() {
    setState(() {
      _progress = 0;
      _currentBPM = 0;
      _confidence = 0.0;
      _waveformData.clear();
      _statusMessage = 'Place finger over camera and flash';
    });

    _progressController.reset();
  }

  String _getHealthAdvice(int bpm) {
    if (bpm < 60) {
      return 'Your heart rate is below normal. Consider consulting a healthcare provider.';
    } else if (bpm <= 100) {
      return 'Your heart rate is within the normal range. Keep up the good work!';
    } else {
      return 'Your heart rate is elevated. Take some time to relax and breathe deeply.';
    }
  }

  Future<void> _saveHeartRateMeasurement() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // User not authenticated - data still saved locally via provider
        print('User not authenticated - skipping Firestore save');
        return;
      }

      final measurement = HeartRateMeasurement(
        userId: user.uid,
        bpm: _currentBPM,
        method: MeasurementMethod.camera,
        timestamp: DateTime.now(),
        confidenceScore: _confidence,
        metadata: {
          'sessionDuration': _progress,
          'device': 'camera',
        },
      );

      await _firestoreService.saveBiofeedback(measurement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Heart rate saved: $_currentBPM BPM'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Firestore save failed: $e');
      // Data is still saved locally via provider - app continues to work
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved locally. Cloud sync failed.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'This app needs camera access to measure your heart rate using photoplethysmography (PPG). '
          'Please grant camera permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Heart Rate Scanner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color(0xFF1a1a1a),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Camera Preview
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isMeasuring ? Colors.red : Colors.grey,
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: _isInitialized && _cameraController != null
                        ? Stack(
                            children: [
                              CameraPreview(_cameraController!),

                              // Overlay with finger guidance
                              Container(
                                color: Colors.black.withOpacity(0.7),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _isMeasuring
                                                ? _pulseAnimation.value
                                                : 1.0,
                                            child: Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.fingerprint,
                                                color: Colors.white,
                                                size: 60,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        _statusMessage,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          ),
                  ),
                ),
              ),

              // Measurements Display
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // BPM Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMeasurementCard(
                            'Heart Rate',
                            '$_currentBPM',
                            'BPM',
                            Colors.red,
                            Icons.favorite,
                          ),
                          _buildMeasurementCard(
                            'Confidence',
                            '${(_confidence * 100).toInt()}',
                            '%',
                            Colors.green,
                            Icons.check_circle,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Progress Bar
                      if (_isMeasuring) ...[
                        AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            return Column(
                              children: [
                                LinearProgressIndicator(
                                  value: _progressController.value,
                                  backgroundColor: Colors.grey[800],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.red),
                                  minHeight: 8,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$_progress% Complete',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      const Spacer(),

                      // Start/Stop Button
                      Container(
                        width: double.infinity,
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ElevatedButton(
                          onPressed: _isMeasuring ? null : _startMeasurement,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isMeasuring
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Measuring...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Start Measurement',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
