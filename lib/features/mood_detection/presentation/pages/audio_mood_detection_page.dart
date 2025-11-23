// lib/features/mood_detection/presentation/pages/audio_mood_detection_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/audio_detection_provider.dart';
import '../widgets/waveform_visualizer.dart';
import '../widgets/advice_dialog.dart';

class AudioMoodDetectionPage extends StatefulWidget {
  const AudioMoodDetectionPage({super.key});

  @override
  State<AudioMoodDetectionPage> createState() => _AudioMoodDetectionPageState();
}

class _AudioMoodDetectionPageState extends State<AudioMoodDetectionPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    // Initialize the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AudioDetectionProvider>();
      if (!provider.isInitialized) {
        provider.initialize();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Audio Mood Detection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Language Selector
          Consumer<AudioDetectionProvider>(
            builder: (context, provider, child) {
              return DropdownButton<String>(
                value: provider.selectedLanguage,
                dropdownColor: Colors.teal,
                iconEnabledColor: Colors.white,
                underline: Container(),
                onChanged: provider.isRecording || provider.isProcessing
                    ? null // Disable during recording/processing
                    : (String? newValue) {
                        if (newValue != null) {
                          provider.setLanguage(newValue);
                        }
                      },
                items: <String>['English', 'हिंदी', 'ગુજરાતી']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: context.watch<AudioDetectionProvider>().isRecording
                ? null // Disable during recording
                : _pickAudioFile,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Consumer<AudioDetectionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    // Waveform Visualization Area
                    Container(
                      height: 250,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            WaveformVisualizer(
                              audioData: provider.audioData,
                              isRecording: provider.isRecording,
                              color: Colors.teal,
                            ),

                            // Recording Timer
                            if (provider.isRecording)
                              Positioned(
                                top: 20,
                                left: 20,
                                child: _buildRecordingTimer(provider),
                              ),

                            // Center Message
                            if (!provider.isRecording &&
                                provider.audioData.isEmpty &&
                                !provider.hasRecording)
                              const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.mic,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Tap the microphone to start recording',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Error Message
                    if (provider.lastError != null)
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Error: ${provider.lastError}",
                          style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500),
                        ),
                      ),

                    // Results Section
                    if (provider.lastResult != null)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildResultsSection(provider),
                      ),
                  ],
                ),
              ),

              // Control Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ]),
                child: _buildControlSection(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecordingTimer(AudioDetectionProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              if (mounted) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              }
              return child!;
            },
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(provider.recordingDuration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(AudioDetectionProvider provider) {
    final result = provider.lastResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recording Complete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            IconButton(
              onPressed: () => provider.clearResults(),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Detected Emotion with Emoji
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _getEmotionColor(result.emotion).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getEmotionColor(result.emotion).withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                _getEmotionEmoji(result.emotion),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 8),
              Text(
                result.emotion.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getEmotionColor(result.emotion),
                ),
              ),
              Text(
                'Detected with ${(result.confidence * 100).toInt()}% confidence',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Action Buttons
        Column(
          children: [
            // Adviser Button (Primary)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showAdviser(provider),
                icon: const Icon(Icons.psychology, size: 24),
                label: const Text(
                  'Get Advice',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _saveResults(provider),
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEmotionalBreakdown(provider),
                    icon: const Icon(Icons.analytics, size: 20),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlSection(AudioDetectionProvider provider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Recording Button
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale:
                  provider.isRecording && mounted ? _pulseAnimation.value : 1.0,
              child: GestureDetector(
                onTap: provider.isProcessing
                    ? null // Disable tap while processing
                    : (provider.isRecording ? _stopRecording : _startRecording),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: provider.isRecording ? Colors.red : Colors.teal,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (provider.isRecording ? Colors.red : Colors.teal)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: provider.isProcessing
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        )
                      : Icon(
                          provider.isRecording ? Icons.stop : Icons.mic,
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
          provider.isProcessing
              ? 'Analyzing...'
              : (provider.isRecording ? 'Recording...' : 'Tap to Record'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),

        const SizedBox(height: 24),

        // Secondary Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSecondaryButton(
              icon: Icons.folder_open,
              label: 'Upload',
              onPressed: provider.isRecording || provider.isProcessing
                  ? null
                  : _pickAudioFile,
            ),
            _buildSecondaryButton(
              icon: Icons.play_arrow,
              label: 'Play',
              onPressed: provider.hasRecording &&
                      !provider.isRecording &&
                      !provider.isProcessing
                  ? _playRecording
                  : null,
            ),
            _buildSecondaryButton(
              icon: Icons.delete,
              label: 'Clear',
              onPressed:
                  (provider.hasRecording || provider.lastResult != null) &&
                          !provider.isRecording &&
                          !provider.isProcessing
                      ? _clearRecording
                      : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: onPressed != null
                ? Colors.teal.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: onPressed != null
                  ? Colors.teal.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: onPressed != null ? Colors.teal : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: onPressed != null ? Colors.teal : Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _startRecording() async {
    try {
      final provider = context.read<AudioDetectionProvider>();
      await provider.startRecording();
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final provider = context.read<AudioDetectionProvider>();
      await provider.stopRecording();
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        print('📁 Selected file: ${file.path}');

        // Basic validation - only block obviously non-audio files
        final String extension = file.path.split('.').last.toLowerCase();
        const blockedExt = [
          'pdf',
          'doc',
          'docx',
          'txt',
          'jpg',
          'jpeg',
          'png',
          'gif',
          'bmp',
          'mp4',
          'avi',
          'mov',
          'zip',
          'rar',
          'exe'
        ];

        if (blockedExt.contains(extension)) {
          _showError(
              'Please select an audio file. Selected file type: .$extension');
          return;
        }

        final provider = context.read<AudioDetectionProvider>();
        await provider.analyzeAudioFile(file);
      }
    } catch (e) {
      _showError('Failed to pick audio file: $e');
    }
  }

  Future<void> _playRecording() async {
    try {
      final provider = context.read<AudioDetectionProvider>();
      await provider.playLastRecording();
    } catch (e) {
      _showError('Failed to play recording: $e');
    }
  }

  Future<void> _clearRecording() async {
    final provider = context.read<AudioDetectionProvider>();
    provider.clearRecording();
  }

  void _saveResults(AudioDetectionProvider provider) {
    final result = provider.lastResult;
    if (result == null || !mounted) return;

    // Save the audio recording with detected emotion
    // This could be enhanced to save to database, file system, etc.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.save, color: Colors.teal),
            const SizedBox(width: 8),
            const Text('Save Audio'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Save audio recording with detected emotion?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getEmotionColor(result.emotion).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    _getEmotionEmoji(result.emotion),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${result.emotion.toUpperCase()} (${(result.confidence * 100).toInt()}% confident)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _getEmotionColor(result.emotion),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Actual save logic would go here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '💾 Audio saved with ${result.emotion} emotion detected',
                  ),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () {
                      // Navigate to saved recordings if implemented
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAdviser(AudioDetectionProvider provider) {
    final result = provider.lastResult;
    if (result == null) return;

    showDialog(
      context: context,
      builder: (context) => AdviceDialog(
        emotionResult: result,
        userSpeech: provider.userSpeechForAdvice.isNotEmpty
            ? provider.userSpeechForAdvice
            : null,
      ),
    );
  }

  void _showEmotionalBreakdown(AudioDetectionProvider provider) {
    final result = provider.lastResult;
    if (result == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Emotional Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primary Emotion
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getEmotionColor(result.emotion).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getEmotionColor(result.emotion).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _getEmotionEmoji(result.emotion),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.emotion.toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getEmotionColor(result.emotion),
                            ),
                          ),
                          Text(
                            '${(result.confidence * 100).toInt()}% Confidence',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'All Detected Emotions:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // All emotions list
              ...result.allEmotions.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        _getEmotionEmoji(entry.key),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: entry.value,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getEmotionColor(entry.key),
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 35,
                        child: Text(
                          '${(entry.value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'sad':
      case 'sadness':
        return Colors.blue;
      case 'angry':
      case 'anger':
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

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
      case 'sadness':
        return '😢';
      case 'angry':
      case 'anger':
        return '😠';
      case 'fear':
        return '😨';
      case 'surprise':
        return '😲';
      case 'disgust':
        return '🤢';
      case 'neutral':
        return '😐';
      default:
        return '😐';
    }
  }
}
