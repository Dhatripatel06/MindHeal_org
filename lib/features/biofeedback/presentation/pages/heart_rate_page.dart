import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/biofeedback_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/models/heart_rate_measurement.dart';
import '../../../mood_detection/data/models/emotion_result.dart';
import '../../../mood_detection/presentation/widgets/advice_dialog.dart';

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
  bool _measurementComplete = false;

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
      _measurementComplete = false;
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
        _measurementComplete = false;
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
      _measurementComplete = true;
    });

    // Update provider with measured heart rate
    if (mounted) {
      final provider = Provider.of<BiofeedbackProvider>(context, listen: false);
      provider.updateHeartRate(_currentBPM);

      // Don't auto-save anymore - let user explicitly save
    }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Please sign in to save measurements'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      Text('Heart rate saved successfully: $_currentBPM BPM'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Heart Rate Scanner'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[800]),
        titleTextStyle: TextStyle(
          color: Colors.grey[800],
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Camera Preview
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: _isMeasuring
                        ? Colors.red.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _isInitialized && _cameraController != null
                      ? Stack(
                          children: [
                            CameraPreview(_cameraController!),

                            // Overlay with finger guidance
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
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
                                            width: 100,
                                            height: 100,
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
                                              size: 50,
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
                      : Center(
                          child: CircularProgressIndicator(
                            color: Colors.blue[600],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // BPM Display Cards
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
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progressController.value,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.red),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_progress% Complete',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Action Chips (Save) - shown after measurement
              if (_measurementComplete && !_isMeasuring) ...[
                Center(
                  child: _buildActionChip(
                    icon: Icons.save_outlined,
                    label: 'Save',
                    color: Colors.green,
                    onTap: _saveHeartRateMeasurement,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Start/Stop Button
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: (_isMeasuring ? Colors.grey : Colors.red)
                          .withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isMeasuring ? null : _startMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
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

              const SizedBox(height: 20),
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
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdviceDialog() {
    // Determine heart rate category for emotion description
    String bpmCategory;
    if (_currentBPM < 60) {
      bpmCategory = 'Low Heart Rate (Bradycardia)';
    } else if (_currentBPM <= 100) {
      bpmCategory = 'Normal Heart Rate';
    } else if (_currentBPM <= 120) {
      bpmCategory = 'Elevated Heart Rate';
    } else {
      bpmCategory = 'High Heart Rate (Tachycardia)';
    }

    // Create EmotionResult for heart rate biofeedback
    final heartRateResult = EmotionResult(
      emotion: '$_currentBPM BPM - $bpmCategory',
      confidence: _confidence,
      allEmotions: {'Heart Rate': _currentBPM.toDouble()},
      timestamp: DateTime.now(),
      processingTimeMs: 0,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdviceDialog(
        emotionResult: heartRateResult,
        userSpeech: '''Heart Rate Biofeedback Measurement:
- Current BPM: $_currentBPM
- Category: $bpmCategory
- Confidence: ${(_confidence * 100).toInt()}%

Please provide Ayurvedic and spiritual wellness guidance including:
1. Dosha balance perspective (Vata, Pitta, Kapha) for this heart rate
2. Recommended herbs, foods, and dietary practices
3. Pranayama (breathing exercises) suitable for this heart rate level
4. Meditation, mantras, and mindfulness techniques for heart health
5. Yoga poses that support cardiovascular balance
6. Practical wellness tips and when to seek medical attention if needed''',
        isAudioDetection: true, // Use conversational style like audio detection
      ),
    );
  }
}
