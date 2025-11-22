/// Enhanced emotion result specifically for audio mood detection
/// Extends the base EmotionResult with audio-specific features
import 'emotion_result.dart';

class AudioEmotionResult extends EmotionResult {
  final String transcribedText;
  final String originalLanguage;
  final String? translatedText;
  final String? audioFilePath;
  final Duration? audioDuration;

  const AudioEmotionResult({
    required super.emotion,
    required super.confidence,
    required super.allEmotions,
    required super.timestamp,
    required super.processingTimeMs,
    required this.transcribedText,
    required this.originalLanguage,
    this.translatedText,
    this.audioFilePath,
    this.audioDuration,
    super.error,
  });

  /// Whether transcription was successful
  bool get hasTranscription =>
      transcribedText.isNotEmpty && transcribedText != "(No speech detected)";

  /// Whether translation was performed
  bool get wasTranslated =>
      translatedText != null && translatedText!.isNotEmpty;

  /// Get the text to display (original or translated)
  String get displayText =>
      hasTranscription ? transcribedText : "No speech detected";

  /// Get the language code for TTS
  String get languageCodeForTTS {
    switch (originalLanguage.toLowerCase()) {
      case 'हिंदी':
      case 'hindi':
        return 'hi_IN';
      case 'ગુજરાતી':
      case 'gujarati':
        return 'gu_IN';
      default:
        return 'en_US';
    }
  }

  /// Convert to base EmotionResult
  EmotionResult toEmotionResult() {
    return EmotionResult(
      emotion: emotion,
      confidence: confidence,
      allEmotions: allEmotions,
      timestamp: timestamp,
      processingTimeMs: processingTimeMs,
      error: error,
    );
  }

  /// Convert to JSON with audio-specific fields
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'transcribedText': transcribedText,
      'originalLanguage': originalLanguage,
      'translatedText': translatedText,
      'audioFilePath': audioFilePath,
      'audioDuration': audioDuration?.inMilliseconds,
    });
    return json;
  }

  /// Create from JSON
  factory AudioEmotionResult.fromJson(Map<String, dynamic> json) {
    return AudioEmotionResult(
      emotion: json['emotion'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      allEmotions: Map<String, double>.from(json['allEmotions'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      processingTimeMs: json['processingTimeMs'] ?? 0,
      transcribedText: json['transcribedText'] ?? '',
      originalLanguage: json['originalLanguage'] ?? 'English',
      translatedText: json['translatedText'],
      audioFilePath: json['audioFilePath'],
      audioDuration: json['audioDuration'] != null
          ? Duration(milliseconds: json['audioDuration'])
          : null,
      error: json['error'],
    );
  }

  /// Create an error result for audio
  factory AudioEmotionResult.error(
    String errorMessage, {
    String language = 'English',
    String? audioPath,
  }) {
    return AudioEmotionResult(
      emotion: 'error',
      confidence: 0.0,
      allEmotions: {},
      timestamp: DateTime.now(),
      processingTimeMs: 0,
      transcribedText: '',
      originalLanguage: language,
      audioFilePath: audioPath,
      error: errorMessage,
    );
  }

  /// Create a successful result
  factory AudioEmotionResult.success({
    required String emotion,
    required double confidence,
    required Map<String, double> allEmotions,
    required String transcribedText,
    required String originalLanguage,
    required int processingTimeMs,
    String? translatedText,
    String? audioFilePath,
    Duration? audioDuration,
  }) {
    return AudioEmotionResult(
      emotion: emotion,
      confidence: confidence,
      allEmotions: allEmotions,
      timestamp: DateTime.now(),
      processingTimeMs: processingTimeMs,
      transcribedText: transcribedText,
      originalLanguage: originalLanguage,
      translatedText: translatedText,
      audioFilePath: audioFilePath,
      audioDuration: audioDuration,
    );
  }

  /// Create a copy with updated values
  AudioEmotionResult copyWith({
    String? emotion,
    double? confidence,
    Map<String, double>? allEmotions,
    DateTime? timestamp,
    int? processingTimeMs,
    String? transcribedText,
    String? originalLanguage,
    String? translatedText,
    String? audioFilePath,
    Duration? audioDuration,
    String? error,
  }) {
    return AudioEmotionResult(
      emotion: emotion ?? this.emotion,
      confidence: confidence ?? this.confidence,
      allEmotions: allEmotions ?? this.allEmotions,
      timestamp: timestamp ?? this.timestamp,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      transcribedText: transcribedText ?? this.transcribedText,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      translatedText: translatedText ?? this.translatedText,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      audioDuration: audioDuration ?? this.audioDuration,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    if (hasError) {
      return 'AudioEmotionResult(error: $error)';
    }
    return 'AudioEmotionResult(emotion: $emotion, confidence: $confidenceString, '
        'text: "$displayText", lang: $originalLanguage, time: ${processingTimeMs}ms)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is AudioEmotionResult &&
          runtimeType == other.runtimeType &&
          transcribedText == other.transcribedText &&
          originalLanguage == other.originalLanguage &&
          translatedText == other.translatedText &&
          audioFilePath == other.audioFilePath &&
          audioDuration == other.audioDuration;

  @override
  int get hashCode =>
      super.hashCode ^
      transcribedText.hashCode ^
      originalLanguage.hashCode ^
      translatedText.hashCode ^
      audioFilePath.hashCode ^
      audioDuration.hashCode;
}
