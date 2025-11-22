import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../../data/models/emotion_result.dart';
import '../providers/combined_detection_provider.dart';
import '../widgets/waveform_visualizer.dart';
import '../widgets/camera_overlay_widget.dart';
import 'mood_results_page.dart';

class CombinedMoodDetectionPage extends StatefulWidget {
  const CombinedMoodDetectionPage({super.key});

  @override
  State<CombinedMoodDetectionPage> createState() =>
      _CombinedMoodDetectionPageState();
}

class _CombinedMoodDetectionPageState extends State<CombinedMoodDetectionPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isRearCamera = false;
  int _frameCount = 0;
  bool _isProcessingFrame = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeCamera();
    _initializeOnnxService();
  }

  Future<void> _initializeOnnxService() async {
    // Ensure ONNX service is initialized for combined detection
    // The providers will handle the actual initialization
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final selectedCamera = _isRearCamera
            ? cameras.firstWhere(
                (camera) => camera.lensDirection == CameraLensDirection.back,
                orElse: () => cameras.first,
              )
            : cameras.firstWhere(
                (camera) => camera.lensDirection == CameraLensDirection.front,
                orElse: () => cameras.first,
              );

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset
              .medium, // Changed from high to medium for better performance
          enableAudio: false,
        );

        await _cameraController!.initialize();

        // Don't start image stream here - only start when analyzing
        // await _cameraController!.startImageStream(_processCameraImage);

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Combined Detection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: _switchCamera,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Consumer<CombinedDetectionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Dual Preview Section
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      children: [
                        // Camera Section
                        Expanded(
                          flex: 2,
                          child: Stack(
                            children: [
                              Container(
                                color: Colors.black,
                                child: _cameraController?.value.isInitialized ==
                                        true
                                    ? AspectRatio(
                                        aspectRatio: _cameraController!
                                            .value.aspectRatio,
                                        child: Stack(
                                          children: [
                                            CameraPreview(_cameraController!),
                                            CameraOverlayWidget(
                                              detectedFaces:
                                                  provider.detectedFaces,
                                              emotions: provider.imageEmotions,
                                              showOverlay: provider.isAnalyzing,
                                            ),
                                          ],
                                        ),
                                      )
                                    : const Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.purple),
                                      ),
                              ),
                              // Camera Label
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'VISUAL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Audio Section
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: Colors.white,
                            child: Stack(
                              children: [
                                WaveformVisualizer(
                                  audioData: provider.audioData,
                                  isRecording: provider.isRecording,
                                  color: Colors.purple,
                                ),
                                // Audio Label
                                Positioned(
                                  top: 8,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.teal,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Text(
                                      'AUDIO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // Recording Indicator
                                if (provider.isRecording)
                                  Positioned(
                                    top: 8,
                                    right: 16,
                                    child: AnimatedBuilder(
                                      animation: _pulseController,
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
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Fusion Results Section
              if (provider.fusedResult != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildFusionResults(provider),
                ),

              // Control Section
              Container(
                padding: const EdgeInsets.all(24),
                child: _buildControlSection(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFusionResults(CombinedDetectionProvider provider) {
    final result = provider.fusedResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Combined Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Row(
              children: [
                _buildModalityIndicator(
                    'Visual', provider.imageConfidence, Colors.purple),
                const SizedBox(width: 8),
                _buildModalityIndicator(
                    'Audio', provider.audioConfidence, Colors.teal),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Fused Emotion Result
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.1),
                Colors.teal.withOpacity(0.1)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getEmotionColor(result.emotion),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getEmotionIcon(result.emotion),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.emotion.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getEmotionColor(result.emotion),
                      ),
                    ),
                    Text(
                      '${(result.confidence * 100).toInt()}% Combined Confidence',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: result.confidence,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getEmotionColor(result.emotion),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Individual Results Comparison
        Row(
          children: [
            Expanded(
              child: _buildModalityResult(
                'Visual Result',
                provider.lastImageResult,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModalityResult(
                'Audio Result',
                provider.lastAudioResult,
                Colors.teal,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _saveResults(result),
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _viewDetailedResults(result),
                icon: const Icon(Icons.analytics),
                label: const Text('Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModalityIndicator(String label, double confidence, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$label ${(confidence * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalityResult(
      String title, EmotionResult? result, Color color) {
    if (result == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No data',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.emotion,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            '${(result.confidence * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSection(CombinedDetectionProvider provider) {
    return Column(
      children: [
        // Status Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: provider.isAnalyzing
                ? Colors.orange.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: provider.isAnalyzing
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: provider.isAnalyzing ? Colors.orange : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                provider.isAnalyzing ? 'Analyzing...' : 'Ready',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: provider.isAnalyzing ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Main Action Button
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: provider.isAnalyzing ? _pulseAnimation.value : 1.0,
              child: GestureDetector(
                onTap: provider.isAnalyzing ? _stopAnalysis : _startAnalysis,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: provider.isAnalyzing
                          ? [Colors.red, Colors.redAccent]
                          : [Colors.purple, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (provider.isAnalyzing ? Colors.red : Colors.purple)
                                .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    provider.isAnalyzing ? Icons.stop : Icons.psychology,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        Text(
          provider.isAnalyzing
              ? 'Analyzing Both Modalities'
              : 'Start Combined Analysis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Analysis Options
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildOptionToggle(
              'Visual',
              Icons.camera_alt,
              Colors.purple,
              provider.isVisualEnabled,
              (value) => provider.toggleVisual(value),
            ),
            _buildOptionToggle(
              'Audio',
              Icons.mic,
              Colors.teal,
              provider.isAudioEnabled,
              (value) => provider.toggleAudio(value),
            ),
            _buildOptionToggle(
              'Fusion',
              Icons.merge_type,
              Colors.orange,
              provider.isFusionEnabled,
              (value) => provider.toggleFusion(value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionToggle(
    String label,
    IconData icon,
    Color color,
    bool isEnabled,
    Function(bool) onChanged,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onChanged(!isEnabled),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isEnabled ? color : Colors.grey[300],
              shape: BoxShape.circle,
              border: Border.all(
                color: isEnabled ? color : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isEnabled ? Colors.white : Colors.grey[600],
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isEnabled ? color : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _startAnalysis() async {
    try {
      final provider = context.read<CombinedDetectionProvider>();
      await provider.startCombinedAnalysis();

      // Start camera image stream only when analyzing
      if (provider.isVisualEnabled && _cameraController != null) {
        await _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      _showError('Failed to start analysis: $e');
    }
  }

  Future<void> _stopAnalysis() async {
    try {
      final provider = context.read<CombinedDetectionProvider>();
      await provider.stopAnalysis();

      // Stop camera image stream when analysis stops
      if (_cameraController != null) {
        await _cameraController!.stopImageStream();
      }
    } catch (e) {
      _showError('Failed to stop analysis: $e');
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (!mounted || _isProcessingFrame) return;

    _frameCount++;

    // Process every 5th frame to reduce load (from 30fps to ~6fps)
    if (_frameCount % 5 != 0) return;

    _isProcessingFrame = true;

    try {
      final provider =
          Provider.of<CombinedDetectionProvider>(context, listen: false);

      if (provider.isVisualEnabled && provider.isAnalyzing) {
        // Convert CameraImage to File for processing
        final tempDir = await Directory.systemTemp.createTemp();
        final tempFile = File('${tempDir.path}/frame.jpg');

        // Convert YUV420 to RGB and save as JPEG
        await _convertCameraImageToFile(image, tempFile);

        // Analyze the frame
        await provider.analyzeCameraFrame(tempFile);

        // Clean up
        await tempFile.delete();
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error processing camera frame: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _convertCameraImageToFile(CameraImage image, File file) async {
    // Convert CameraImage to image.Image format
    final img.Image rgbImage = _convertYUV420ToImage(image);

    // Save as JPEG
    final jpegBytes = img.encodeJpg(rgbImage);
    await file.writeAsBytes(jpegBytes);
  }

  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final img.Image image = img.Image(width: width, height: height);

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = cameraImage.planes[0].bytes[index];
        final up = cameraImage.planes[1].bytes[uvIndex];
        final vp = cameraImage.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  Future<void> _switchCamera() async {
    final provider = context.read<CombinedDetectionProvider>();
    final wasAnalyzing = provider.isAnalyzing;

    // Stop image stream if running
    if (_cameraController != null) {
      await _cameraController!.stopImageStream();
    }

    setState(() {
      _isRearCamera = !_isRearCamera;
    });

    await _cameraController?.dispose();
    await _initializeCamera();

    // Restart image stream if we were analyzing
    if (wasAnalyzing && provider.isVisualEnabled && _cameraController != null) {
      await _cameraController!.startImageStream(_processCameraImage);
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Analysis Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ListTile(
                    title: const Text('Fusion Algorithm'),
                    subtitle: const Text('Weighted Average'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  ),
                  SwitchListTile(
                    title: const Text('Real-time Processing'),
                    subtitle: const Text('Process while recording'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Auto-save Results'),
                    subtitle: const Text('Automatically save analysis'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  ListTile(
                    title: const Text('Analysis Interval'),
                    subtitle: const Text('Every 2 seconds'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveResults(EmotionResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Combined analysis saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewDetailedResults(EmotionResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoodResultsPage(emotionResult: result),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      case 'fear':
        return Colors.orange;
      case 'surprise':
        return Colors.purple;
      case 'disgust':
        return Colors.brown;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
        return Icons.sentiment_dissatisfied;
      case 'fear':
        return Icons.sentiment_neutral;
      case 'surprise':
        return Icons.sentiment_satisfied;
      case 'disgust':
        return Icons.sentiment_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.sentiment_neutral;
    }
  }
}
