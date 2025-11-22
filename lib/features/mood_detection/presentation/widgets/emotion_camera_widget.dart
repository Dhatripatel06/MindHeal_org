import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/emotion_provider.dart';
import '/shared/widgets/loading_widget.dart';
import '/shared/widgets/error_widget.dart';

/// Camera widget with real-time emotion detection overlay
class EmotionCameraWidget extends StatefulWidget {
  final VoidCallback? onEmotionDetected;
  final bool showConfidenceThreshold;
  final bool showProcessingTime;
  final bool autoStart;

  const EmotionCameraWidget({
    Key? key,
    this.onEmotionDetected,
    this.showConfidenceThreshold = true,
    this.showProcessingTime = false,
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<EmotionCameraWidget> createState() => _EmotionCameraWidgetState();
}

class _EmotionCameraWidgetState extends State<EmotionCameraWidget>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _confidenceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _confidenceAnimation;

  bool _permissionsGranted = false;
  bool _checkingPermissions = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _confidenceController = AnimationController(
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

    _confidenceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confidenceController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController.repeat(reverse: true);

    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _confidenceController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final emotionProvider = context.read<EmotionProvider>();

    if (state == AppLifecycleState.inactive) {
      emotionProvider.stopRealTimeDetection();
    } else if (state == AppLifecycleState.resumed && widget.autoStart) {
      if (emotionProvider.cameraInitialized &&
          !emotionProvider.realTimeDetection) {
        emotionProvider.startRealTimeDetection();
      }
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _checkingPermissions = true);

    try {
      final cameraStatus = await Permission.camera.request();

      setState(() {
        _permissionsGranted = cameraStatus == PermissionStatus.granted;
        _checkingPermissions = false;
      });

      if (_permissionsGranted) {
        await _initializeCamera();
      }
    } catch (e) {
      setState(() {
        _permissionsGranted = false;
        _checkingPermissions = false;
      });
      print('❌ Error checking permissions: $e');
    }
  }

  Future<void> _initializeCamera() async {
    final emotionProvider = context.read<EmotionProvider>();

    try {
      if (!emotionProvider.isInitialized) {
        await emotionProvider.initialize();
      }

      await emotionProvider.initializeCamera();

      if (widget.autoStart && mounted) {
        await emotionProvider.startRealTimeDetection();
      }
    } catch (e) {
      print('❌ Error initializing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermissions) {
      return const Center(
        child: LoadingWidget(message: 'Checking camera permissions...'),
      );
    }

    if (!_permissionsGranted) {
      return _buildPermissionDeniedWidget();
    }

    return Consumer<EmotionProvider>(
      builder: (context, emotionProvider, child) {
        if (emotionProvider.isLoading) {
          return const Center(
            child: LoadingWidget(message: 'Initializing emotion detection...'),
          );
        }

        if (emotionProvider.error != null) {
          return Center(
            child: CustomErrorWidget(
              message: emotionProvider.error!,
              onRetry: _initializeCamera,
            ),
          );
        }

        if (!emotionProvider.cameraInitialized ||
            emotionProvider.cameraController == null) {
          return const Center(
            child: LoadingWidget(message: 'Initializing camera...'),
          );
        }

        return _buildCameraPreview(emotionProvider);
      },
    );
  }

  Widget _buildPermissionDeniedWidget() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera Permission Required',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'To detect emotions in real-time, we need access to your camera.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _checkPermissions,
                icon: const Icon(Icons.settings),
                label: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview(EmotionProvider emotionProvider) {
    final controller = emotionProvider.cameraController!;

    return Stack(
      children: [
        // Camera preview
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),

        // Emotion overlay
        _buildEmotionOverlay(emotionProvider),

        // Controls
        _buildControls(emotionProvider),

        // Detection indicator
        if (emotionProvider.realTimeDetection) _buildDetectionIndicator(),
      ],
    );
  }

  Widget _buildEmotionOverlay(EmotionProvider emotionProvider) {
    final result = emotionProvider.currentResult;

    if (result == null || result.hasError) {
      return const SizedBox.shrink();
    }

    // Trigger confidence animation when result updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confidenceController.reset();
      _confidenceController.forward();

      if (widget.onEmotionDetected != null) {
        widget.onEmotionDetected!();
      }
    });

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _confidenceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (_confidenceAnimation.value * 0.2),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getEmotionColor(result.emotion).withOpacity(0.6),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  // Primary emotion
                  Row(
                    children: [
                      Icon(
                        _getEmotionIcon(result.emotion),
                        color: _getEmotionColor(result.emotion),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.emotion.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${result.confidenceString} confidence',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.showProcessingTime)
                        Text(
                          '${result.processingTimeMs}ms',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white60,
                                  ),
                        ),
                    ],
                  ),

                  // Confidence bars for all emotions
                  if (widget.showConfidenceThreshold) ...[
                    const SizedBox(height: 12),
                    ...result.allEmotions.entries.map(
                      (entry) => _buildConfidenceBar(entry.key, entry.value),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfidenceBar(String emotion, double confidence) {
    final color = _getEmotionColor(emotion);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              emotion,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: confidence,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${(confidence * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(EmotionProvider emotionProvider) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Toggle real-time detection
          FloatingActionButton(
            heroTag: 'toggle_detection',
            onPressed: emotionProvider.realTimeDetection
                ? emotionProvider.stopRealTimeDetection
                : () => emotionProvider.startRealTimeDetection(),
            backgroundColor: emotionProvider.realTimeDetection
                ? Colors.red
                : Theme.of(context).primaryColor,
            child: Icon(
              emotionProvider.realTimeDetection ? Icons.stop : Icons.play_arrow,
            ),
          ),

          // Manual capture
          FloatingActionButton(
            heroTag: 'manual_capture',
            onPressed: emotionProvider.isLoading
                ? null
                : emotionProvider.captureAndDetectEmotion,
            child: const Icon(Icons.camera_alt),
          ),

          // Clear history
          FloatingActionButton(
            heroTag: 'clear_history',
            onPressed: emotionProvider.clearHistory,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.clear_all),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionIndicator() {
    return Positioned(
      top: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Colors.yellow;
      case 'sad':
      case 'sadness':
        return Colors.blue;
      case 'angry':
      case 'anger':
        return Colors.red;
      case 'fear':
      case 'afraid':
        return Colors.purple;
      case 'surprise':
      case 'surprised':
        return Colors.orange;
      case 'disgust':
        return Colors.green;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
      case 'sadness':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
      case 'anger':
        return Icons.sentiment_very_dissatisfied;
      case 'fear':
      case 'afraid':
        return Icons.sentiment_dissatisfied;
      case 'surprise':
      case 'surprised':
        return Icons.sentiment_satisfied;
      case 'disgust':
        return Icons.sentiment_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.help_outline;
    }
  }
}
