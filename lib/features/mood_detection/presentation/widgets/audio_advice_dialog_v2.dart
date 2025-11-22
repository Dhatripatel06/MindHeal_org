import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mental_wellness_app/features/mood_detection/data/models/audio_emotion_result.dart';
import 'package:mental_wellness_app/features/mood_detection/presentation/providers/enhanced_audio_detection_provider.dart';

/// Audio-specific advice dialog that matches the image mood detection UI pattern
/// Shows detected emotion, transcribed text, and AI advice with read-aloud functionality
class AudioAdviceDialog extends StatefulWidget {
  final AudioEmotionResult result;
  final String advice;
  final VoidCallback? onClose;

  const AudioAdviceDialog({
    super.key,
    required this.result,
    required this.advice,
    this.onClose,
  });

  @override
  State<AudioAdviceDialog> createState() => _AudioAdviceDialogState();
}

class _AudioAdviceDialogState extends State<AudioAdviceDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          contentPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          content: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                minHeight: 400,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Expanded(child: _buildContent()),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getEmotionColor(widget.result.emotion),
            _getEmotionColor(widget.result.emotion).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _getEmotionIcon(widget.result.emotion),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Analysis',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.result.emotion.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _closeDialog,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Confidence indicator
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: widget.result.confidence,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(widget.result.confidence * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transcribed Text Section
          if (widget.result.hasTranscription) ...[
            _buildSectionHeader('What You Said', Icons.record_voice_over),
            const SizedBox(height: 12),
            _buildTextCard(
              widget.result.transcribedText,
              Colors.blue.withOpacity(0.1),
              Colors.blue,
            ),
            const SizedBox(height: 20),
          ],

          // Translation Section (if applicable)
          if (widget.result.wasTranslated) ...[
            _buildSectionHeader('Translation', Icons.translate),
            const SizedBox(height: 12),
            _buildTextCard(
              widget.result.translatedText!,
              Colors.green.withOpacity(0.1),
              Colors.green,
            ),
            const SizedBox(height: 20),
          ],

          // AI Advice Section
          _buildSectionHeader('Your AI Friend Says', Icons.psychology),
          const SizedBox(height: 12),
          _buildAdviceCard(),
          const SizedBox(height: 20),

          // Audio Details (expandable)
          _buildAudioDetails(),

          // Emotion Breakdown
          if (_isExpanded) ...[
            const SizedBox(height: 20),
            _buildEmotionBreakdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTextCard(String text, Color backgroundColor, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.4,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildAdviceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personalized Guidance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple[700],
                ),
              ),
              _buildTTSButton(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.advice,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTTSButton() {
    return Consumer<AudioDetectionProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: provider.isSpeaking ? Colors.red : Colors.purple,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: Icon(
              provider.isSpeaking ? Icons.stop : Icons.volume_up,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () async {
              if (provider.isSpeaking) {
                await provider.stopSpeaking();
              } else {
                await provider.speakAdvice(widget.advice);
              }
            },
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: const EdgeInsets.all(8),
          ),
        );
      },
    );
  }

  Widget _buildAudioDetails() {
    return Card(
      child: ExpansionTile(
        title: const Text(
          'Audio Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: const Icon(Icons.audio_file),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  'Language',
                  widget.result.originalLanguage,
                  Icons.language,
                ),
                if (widget.result.audioDuration != null)
                  _buildDetailRow(
                    'Duration',
                    _formatDuration(widget.result.audioDuration!),
                    Icons.timer,
                  ),
                _buildDetailRow(
                  'Processing Time',
                  '${widget.result.processingTimeMs}ms',
                  Icons.speed,
                ),
                _buildDetailRow(
                  'Timestamp',
                  _formatTimestamp(widget.result.timestamp),
                  Icons.schedule,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emotion Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...widget.result.allEmotions.entries
            .where((entry) => entry.value > 0.05) // Only show emotions > 5%
            .map((entry) => _buildEmotionBar(entry.key, entry.value))
            .toList(),
      ],
    );
  }

  Widget _buildEmotionBar(String emotion, double confidence) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _getEmotionEmoji(emotion),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    emotion.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Text(
                '${(confidence * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getEmotionColor(emotion),
            ),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveResults,
              icon: const Icon(Icons.save),
              label: const Text('Save Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareResults,
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _closeDialog() {
    _slideController.reverse().then((_) {
      Navigator.of(context).pop();
      widget.onClose?.call();
    });
  }

  void _saveResults() {
    // Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice analysis saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    _closeDialog();
  }

  void _shareResults() {
    // Implement share functionality
    final summary = 'Voice Analysis Results:\n'
        'Emotion: ${widget.result.emotion}\n'
        'Confidence: ${(widget.result.confidence * 100).toInt()}%\n'
        'Text: "${widget.result.transcribedText}"\n'
        'Advice: "${widget.advice}"';

    // You could use share_plus package here
    print('Sharing: $summary');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analysis shared successfully!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Helper methods
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

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
      case 'sadness':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
      case 'anger':
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// Helper function to show the audio advice dialog
Future<void> showAudioAdviceDialog(
  BuildContext context, {
  required AudioEmotionResult result,
  required String advice,
  VoidCallback? onClose,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AudioAdviceDialog(
        result: result,
        advice: advice,
        onClose: onClose,
      );
    },
  );
}
