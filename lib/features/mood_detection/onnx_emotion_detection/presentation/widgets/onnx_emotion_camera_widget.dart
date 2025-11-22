// File: lib/features/mood_detection/onnx_emotion_detection/presentation/widgets/onnx_emotion_camera_widget.dart
// Fetched from: uploaded:dhatripatel06/mindheal/MindHeal-85536139ba7d179416053015e8b635520a2cb94e/lib/features/mood_detection/onnx_emotion_detection/presentation/widgets/onnx_emotion_camera_widget.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../../data/services/onnx_emotion_service.dart'; //
import '../../../data/models/emotion_result.dart'; //

// --- NEW IMPORTS ---
import '../../../presentation/providers/image_detection_provider.dart';
import '../../../../../core/services/tts_service.dart'; // For TtsState enum
// --- END NEW IMPORTS ---


class OnnxEmotionCameraWidget extends StatefulWidget {
  // Removed internal detection logic, will rely on provider
  final bool showPerformanceOverlay; //

  const OnnxEmotionCameraWidget({
    super.key,
    this.showPerformanceOverlay = true, //
  });

  @override
  State<OnnxEmotionCameraWidget> createState() =>
      _OnnxEmotionCameraWidgetState();
}

class _OnnxEmotionCameraWidgetState extends State<OnnxEmotionCameraWidget>
    with WidgetsBindingObserver, TickerProviderStateMixin { //

  // CameraController and related state will be managed by the provider
  late ImageDetectionProvider _provider; // Reference to the provider

  // Animation controllers (keep for UI feedback)
  late AnimationController _pulseController; //
  late AnimationController _fadeController; //
  late Animation<double> _pulseAnimation; //
  late Animation<double> _fadeAnimation; //

  // Keep service instance for performance stats if needed
  final OnnxEmotionService _emotionService = OnnxEmotionService.instance; //

  @override
  void initState() {
    super.initState(); //
    WidgetsBinding.instance.addObserver(this); //

    // Initialize animations
    _pulseController = AnimationController( //
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController = AnimationController( //
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate( //
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate( //
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Get provider reference (listen: false as we use Consumer later)
    _provider = Provider.of<ImageDetectionProvider>(context, listen: false);

    _initializeServices(); // Call initialization via provider
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); //
    // Provider handles camera controller disposal
    _pulseController.dispose(); //
    _fadeController.dispose(); //
    // Stop real-time detection if active when widget is disposed
    if (_provider.isRealTimeMode) {
       _provider.stopRealTimeDetection();
    }
    super.dispose(); //
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { //
     // Let the provider handle lifecycle if needed, or re-initialize camera here
     final controller = _provider.cameraController;
    if (controller == null || !controller.value.isInitialized) { //
      return;
    }

    if (state == AppLifecycleState.inactive) { //
       // Stop real-time when inactive
       if(_provider.isRealTimeMode) {
          _provider.stopRealTimeDetection();
       }
       // Consider disposing camera controller here or let provider handle it
       // controller.dispose();
    } else if (state == AppLifecycleState.resumed) { //
       // Re-initialize camera if needed or restart real-time
        if (controller.value.isInitialized == false) {
           _provider.initializeCamera(); // Re-init if controller was disposed
        }
    }
  }

  Future<void> _initializeServices() async {
     try {
       // Initialize emotion service first
       await _provider.initialize();
       if (!_provider.isInitialized) {
          throw Exception('Failed to initialize ONNX emotion detection');
       }
       // Initialize camera
       await _provider.initializeCamera();
       if (_provider.cameraController == null || !_provider.cameraController!.value.isInitialized) {
         throw Exception('Failed to initialize Camera');
       }
       _fadeController.forward(); // Fade in camera preview
     } catch (e) {
        // Error state is handled by the provider, UI will react via Consumer
        print("Initialization Error: $e");
     }
  }


  // --- detectEmotion removed, provider handles this ---

  // --- Helper methods for color/emoji (can remain here or move to utils) ---
  Color _getEmotionColor(String emotion) { //
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'sad':
        return Colors.blue;
      case 'anger': //
        return Colors.red;
      case 'fear': //
        return Colors.orange;
      case 'surprise': //
        return Colors.purple;
      case 'disgust': //
        return Colors.brown;
      case 'contempt': //
        return Colors.indigo;
      case 'neutral': //
      default:
        return Colors.grey; //
    }
  }

  String _getEmotionEmoji(String emotion) { //
    switch (emotion.toLowerCase()) {
      case 'happy': //
        return '😊';
      case 'sad': //
        return '😢';
      case 'anger': //
        return '😠';
      case 'fear': //
        return '😨';
      case 'surprise': //
        return '😲';
      case 'disgust': //
        return '🤢';
      case 'contempt': //
        return '😤';
      case 'neutral': //
      default:
        return '😐'; //
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to provider changes
    return Consumer<ImageDetectionProvider>(
      builder: (context, provider, child) {
        // Update pulse animation based on provider's processing state
        if (provider.isProcessing && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        } else if (!provider.isProcessing && _pulseController.isAnimating) {
          _pulseController.stop();
          _pulseController.reset();
        }

        // Determine status message based on provider state
        String statusMessage = 'Initializing...';
        if (provider.error != null) {
          statusMessage = 'Error: ${provider.error}';
        } else if (!provider.isInitialized) {
          statusMessage = 'Initializing ONNX service...';
        } else if (provider.cameraController == null || !provider.cameraController!.value.isInitialized) {
          statusMessage = 'Initializing camera...';
        } else if (provider.isRealTimeMode && provider.isProcessing) {
          statusMessage = 'Detecting...';
        } else if (provider.currentResult != null) {
           statusMessage = 'Detected: ${provider.currentResult!.emotion} '
              '(${(provider.currentResult!.confidence * 100).toStringAsFixed(1)}%)';
        } else if (provider.isRealTimeMode) {
          statusMessage = 'Real-time detection active';
        }
         else {
          statusMessage = 'Ready';
        }


        return Scaffold(
          backgroundColor: Colors.black, //
          body: SafeArea( //
            child: Column(
              children: [
                // Status bar
                Container( //
                  width: double.infinity,
                  padding: const EdgeInsets.all(12), // Reduced padding slightly
                  decoration: BoxDecoration( //
                    gradient: LinearGradient( //
                      colors: [Colors.blue.shade900, Colors.blue.shade700],
                    ),
                  ),
                  child: Row( //
                    children: [
                      if (provider.isProcessing || provider.isFetchingAdvice) // Show indicator also when fetching advice
                        Container( //
                          width: 12, //
                          height: 12, //
                          margin: const EdgeInsets.only(right: 8), //
                          child: CircularProgressIndicator( //
                            strokeWidth: 2, //
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white), //
                          ),
                        ),
                      Expanded( //
                        child: Text(
                          statusMessage, // Use dynamic status message
                          style: const TextStyle(color: Colors.white, fontSize: 14), // Slightly smaller font //
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                        ),
                      ),
                      // --- NEW LANGUAGE SELECTOR ---
                      _buildLanguageSelector(provider),
                      // --- END NEW LANGUAGE SELECTOR ---
                    ],
                  ),
                ),

                // Camera preview
                Expanded( //
                  flex: 3, //
                  child: _buildCameraPreview(provider), // Pass provider //
                ),

                // Emotion results and Advice Area
                 Expanded( //
                    flex: 2, // Adjusted flex //
                    child: _buildResultsAndAdviceArea(provider), // Combined area
                  ),


                // Controls
                Container( //
                  padding: const EdgeInsets.all(16), //
                  decoration: BoxDecoration( //
                    color: Colors.grey.shade100, //
                    borderRadius: //
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column( //
                    mainAxisSize: MainAxisSize.min, // Make column height fit content
                    children: [
                      Row( //
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, //
                        children: [
                          // Real-time toggle button
                           _buildRealTimeButton(provider),

                          // Switch camera button
                          if (provider.cameraController != null) // Check if controller exists
                             IconButton( //
                                onPressed: provider.isProcessing ? null : provider.switchCamera, // Use provider method //
                                icon: const Icon(Icons.flip_camera_ios), //
                                iconSize: 32, //
                                color: Colors.blue, //
                              ),

                          // Performance stats (optional)
                          if (_emotionService.isReady && //
                              widget.showPerformanceOverlay) //
                            TextButton( //
                              onPressed: _showPerformanceStats, //
                              child: const Text( //
                                'Stats',
                                style: TextStyle(color: Colors.blue), //
                              ),
                            ),
                        ],
                      ),
                       // --- NEW ADVICE BUTTON AND READ ALOUD ---
                       if (provider.currentResult != null && !provider.currentResult!.hasError)
                         Padding(
                           padding: const EdgeInsets.only(top: 10.0),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               ElevatedButton.icon(
                                  onPressed: provider.isFetchingAdvice ? null : provider.fetchAdvice,
                                  icon: provider.isFetchingAdvice
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.lightbulb_outline),
                                  label: Text(provider.adviceText == null ? 'Get Advice' : 'Refresh Advice'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.deepPurple,
                                     foregroundColor: Colors.white,
                                   ),
                                ),
                                const SizedBox(width: 15),
                                // Read Aloud / Stop Button
                                if (provider.adviceText != null && provider.adviceText!.isNotEmpty)
                                  IconButton(
                                      icon: Icon(
                                          provider.isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                                          color: provider.isSpeaking ? Colors.redAccent : Colors.deepPurple,
                                      ),
                                      iconSize: 30,
                                      tooltip: provider.isSpeaking ? 'Stop' : 'Read Aloud',
                                      onPressed: provider.isSpeaking ? provider.stopSpeaking : provider.speakAdvice,
                                  ),

                             ],
                           ),
                         ),
                      // --- END NEW ADVICE BUTTON ---
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraPreview(ImageDetectionProvider provider) { //
    final controller = provider.cameraController;
    if (controller == null || !controller.value.isInitialized) { //
      // Show loading or error based on provider state
      return Center( //
        child: Column( //
          mainAxisAlignment: MainAxisAlignment.center, //
          children: [ //
            if (provider.error == null) const CircularProgressIndicator(color: Colors.blue), //
            const SizedBox(height: 16), //
            Text( //
              provider.error ?? 'Initializing camera...',
              style: const TextStyle(color: Colors.white, fontSize: 16), //
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Use AspectRatio to prevent distortion
    return FadeTransition( //
      opacity: _fadeAnimation, //
      child: Container( //
        margin: const EdgeInsets.all(8), // Add some margin
        clipBehavior: Clip.antiAlias, // Smoother clipping
        decoration: BoxDecoration( //
           borderRadius: BorderRadius.circular(16) //
        ),
        child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller), //
         ),
      ),
    );
  }

    // --- NEW WIDGET ---
   Widget _buildResultsAndAdviceArea(ImageDetectionProvider provider) {
     final result = provider.currentResult;
     final advice = provider.adviceText;

     return Container(
        padding: const EdgeInsets.all(16), //
        width: double.infinity,
        decoration: BoxDecoration( //
          gradient: LinearGradient( //
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              result != null ? _getEmotionColor(result.emotion).withOpacity(0.1) : Colors.grey.shade100, //
              Colors.grey.shade50, //
            ],
          ),
          // No border radius needed if it's not the top element
        ),
        child: SingleChildScrollView( // Allow scrolling if content overflows
          child: Column( //
            children: [
              // Only show emotion results if available
              if (result != null && !result.hasError) ...[ //
                 _buildEmotionDisplay(result), // Extracted display logic
                 const SizedBox(height: 15), //
                 _buildTopEmotions(result), // Extracted breakdown
                  const SizedBox(height: 8), //
                   // Processing time
                    Text( //
                      'Processed in ${result.processingTimeMs}ms',
                      style: TextStyle( //
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  const Divider(height: 20, thickness: 1),
               ],

              // Advice Section
              if (provider.isFetchingAdvice)
                 const Center(child: CircularProgressIndicator())
              else if (advice != null)
                 Padding(
                   padding: const EdgeInsets.symmetric(vertical: 8.0),
                   child: Text(
                     advice,
                     style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                     textAlign: TextAlign.center,
                   ),
                 )
              else if (result != null && !result.hasError) // Show only if mood detected
                 const Text(
                   'Tap "Get Advice" for tips.',
                   style: TextStyle(color: Colors.grey),
                 ),
            ],
          ),
        ),
     );
   }

   // Extracted widget for main emotion display
   Widget _buildEmotionDisplay(EmotionResult result) {
      return Row( //
        mainAxisAlignment: MainAxisAlignment.center, //
        children: [
          Text( //
            _getEmotionEmoji(result.emotion), //
            style: const TextStyle(fontSize: 40), // Slightly smaller emoji //
          ),
          const SizedBox(width: 16), //
          Column( //
            crossAxisAlignment: CrossAxisAlignment.start, //
            children: [
              Text( //
                result.emotion, //
                style: TextStyle( //
                  fontSize: 24, // Smaller text //
                  fontWeight: FontWeight.bold, //
                  color: _getEmotionColor(result.emotion), //
                ),
              ),
              Text( //
                '${(result.confidence * 100).toStringAsFixed(1)}% confidence', //
                style: TextStyle( //
                  fontSize: 14, // Smaller text //
                  color: Colors.grey.shade600, //
                ),
              ),
            ],
          ),
        ],
      );
   }

   // Extracted widget for top 3 emotions breakdown
  Widget _buildTopEmotions(EmotionResult result) {
     final topEmotions = result.allEmotions.entries.toList() //
      ..sort((a, b) => b.value.compareTo(a.value)); //
    final top3 = topEmotions.take(3).toList(); //

    return Column( //
       children: [
          // Top emotions breakdown
          Text( //
            'Emotion Breakdown',
            style: TextStyle( //
              fontSize: 15, //
              fontWeight: FontWeight.w600, //
              color: Colors.grey.shade700, //
            ),
          ),
          const SizedBox(height: 8), //

          ...top3.map((emotion) { //
            // Remember: result.allEmotions contains ORIGINAL probabilities
            // result.confidence is the SCALED value of the top emotion
            // We display original probabilities here for the breakdown
            double originalProbability = emotion.value;

            return Padding( //
              padding: const EdgeInsets.symmetric(vertical: 3), // Reduced vertical padding //
              child: Row( //
                children: [
                  SizedBox( //
                    width: 70, // Slightly smaller width //
                    child: Text( //
                      emotion.key, //
                      style: const TextStyle( //
                        fontSize: 13, //
                        fontWeight: FontWeight.w500, //
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded( //
                    child: LinearProgressIndicator( //
                      value: originalProbability, // Use original probability //
                      backgroundColor: Colors.grey.shade300, //
                      valueColor: AlwaysStoppedAnimation<Color>( //
                        _getEmotionColor(emotion.key), //
                      ),
                       minHeight: 6, // Make bars slightly thicker
                    ),
                  ),
                  const SizedBox(width: 8), //
                  SizedBox( //
                    width: 45, // Slightly smaller width //
                    child: Text( //
                      '${(originalProbability * 100).toStringAsFixed(1)}%', // Display original percentage
                      style: TextStyle( //
                        fontSize: 12, //
                        color: Colors.grey.shade600, //
                      ),
                      textAlign: TextAlign.right, //
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
       ],
     );
  }


  // --- NEW WIDGET ---
  Widget _buildLanguageSelector(ImageDetectionProvider provider) {
    return DropdownButton<String>(
      value: provider.selectedLanguage,
      icon: const Icon(Icons.language, color: Colors.white, size: 20),
      dropdownColor: Colors.blue.shade800,
      underline: Container(), // Remove underline
      onChanged: provider.isFetchingAdvice || provider.isSpeaking
          ? null // Disable while fetching or speaking
          : (String? newValue) {
              if (newValue != null) {
                provider.setLanguage(newValue);
              }
            },
      items: provider.availableLanguages
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        );
      }).toList(),
    );
  }

   // --- NEW WIDGET ---
   Widget _buildRealTimeButton(ImageDetectionProvider provider) {
       return ElevatedButton.icon(
           onPressed: provider.isProcessing ? null : () {
               if (provider.isRealTimeMode) {
                   provider.stopRealTimeDetection();
               } else {
                   provider.startRealTimeDetection();
               }
           },
           icon: Icon(provider.isRealTimeMode ? Icons.stop : Icons.play_arrow),
           label: Text(provider.isRealTimeMode ? 'Stop Real-time' : 'Start Real-time'),
            style: ElevatedButton.styleFrom(
               backgroundColor: provider.isRealTimeMode ? Colors.redAccent : Colors.teal,
               foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), //
                shape: RoundedRectangleBorder( //
                  borderRadius: BorderRadius.circular(12),
                ),
           ),
       );
   }


  // Keep _showPerformanceStats as it relies on _emotionService instance
  void _showPerformanceStats() { //
    final stats = _emotionService.getPerformanceStats(); //

    showDialog( //
      context: context,
      builder: (context) => AlertDialog( //
        title: const Text('ONNX Performance Statistics'), //
        content: Column( //
          mainAxisSize: MainAxisSize.min, //
          crossAxisAlignment: CrossAxisAlignment.start, //
          children: [
            Text('Total Inferences: ${stats.totalInferences}'), //
            const SizedBox(height: 8), //
            Text( //
                'Average Time: ${stats.averageInferenceTimeMs.toStringAsFixed(1)}ms'),
            Text('Min Time: ${stats.minInferenceTimeMs.toStringAsFixed(1)}ms'), //
            Text('Max Time: ${stats.maxInferenceTimeMs.toStringAsFixed(1)}ms'), //
            const SizedBox(height: 12), //
            Text( //
              'Model: EfficientNet-B0 (AFEW)',
              style: TextStyle( //
                fontSize: 12, //
                color: Colors.grey.shade600, //
              ),
            ),
          ],
        ),
        actions: [ //
          TextButton( //
            onPressed: () => Navigator.of(context).pop(), //
            child: const Text('Close'), //
          ),
        ],
      ),
    );
  }
} // End of _OnnxEmotionCameraWidgetState