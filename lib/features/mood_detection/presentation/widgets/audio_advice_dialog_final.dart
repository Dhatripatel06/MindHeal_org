import 'package:flutter/material.dart';
import 'package:mental_wellness_app/features/mood_detection/data/models/audio_emotion_result.dart';
import 'package:mental_wellness_app/core/services/tts_service.dart';

/// Audio-specific advice dialog that matches the image mood detection UI pattern
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

class _AudioAdviceDialogState extends State<AudioAdviceDialog> {
  bool _isExpanded = false;
  bool _isSpeaking = false;
  late TtsService _ttsService;

  @override
  void initState() {
    super.initState();
    _ttsService = TtsService();
    _ttsService.onStateChanged = (state) {
      setState(() {
        _isSpeaking = state == TtsState.playing;
      });
    };
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(
              _getEmotionIcon(widget.result.emotion),
              size: 35,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Mood Detection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getEmotionEmoji(widget.result.emotion)} ${widget.result.emotion.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${(widget.result.confidence * 100).toInt()}% confidence',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.result.hasTranscription) _buildTranscriptionSection(),
            const SizedBox(height: 16),
            _buildAdviceSection(),
            const SizedBox(height: 16),
            _buildAudioDetails(),
            const SizedBox(height: 16),
            _buildEmotionBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.transcribe, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Transcription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                widget.result.transcribedText ?? 'No transcription available',
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (widget.result.translatedText != null) ...[
              const SizedBox(height: 8),
              Text(
                'Translation (English):',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  widget.result.translatedText!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'AI Advice',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                _buildTTSButton(),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.blue[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                widget.advice,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTTSButton() {
    return Container(
      decoration: BoxDecoration(
        color: _isSpeaking ? Colors.red : Colors.purple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(
          _isSpeaking ? Icons.stop : Icons.volume_up,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () async {
          if (_isSpeaking) {
            await _ttsService.stop();
          } else {
            final language = widget.result.languageCodeForTTS;
            await _ttsService.speak(widget.advice, language);
          }
        },
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: const EdgeInsets.all(8),
      ),
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
                  'Model',
                  'wav2vec2_emotion',
                  Icons.psychology,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Emotion Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.result.allEmotions.entries
                .map((entry) => _buildEmotionBar(entry.key, entry.value))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionBar(String emotion, double score) {
    final percentage = (score * 100).toInt();
    final isTopEmotion = emotion.toLowerCase() == widget.result.emotion.toLowerCase();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(_getEmotionEmoji(emotion)),
                  const SizedBox(width: 8),
                  Text(
                    emotion.toUpperCase(),
                    style: TextStyle(
                      fontWeight: isTopEmotion ? FontWeight.bold : FontWeight.normal,
                      color: isTopEmotion ? Colors.purple : Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isTopEmotion ? Colors.purple : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.grey[300],
            ),
            child: FractionallySizedBox(
              widthFactor: score,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: isTopEmotion
                        ? [Colors.purple, Colors.deepPurple]
                        : [Colors.blue[300]!, Colors.blue[500]!],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _handleClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleShare,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Share'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleClose() {
    Navigator.of(context).pop();
    widget.onClose?.call();
  }

  void _handleShare() {
    // Create shareable content
    final content = 
        'Emotion: ${widget.result.emotion}\n'
        'Confidence: ${(widget.result.confidence * 100).toInt()}%\n'
        'Text: "${widget.result.transcribedText}"\n'
        'Advice: "${widget.advice}"';
    
    // Show share options (simplified for now)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );
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
        return Icons.sentiment_very_dissatisfied;
      case 'fear':
        return Icons.sentiment_dissatisfied;
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