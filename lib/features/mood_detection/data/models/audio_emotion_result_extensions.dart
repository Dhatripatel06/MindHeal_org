import 'package:cloud_firestore/cloud_firestore.dart';
import 'audio_emotion_result.dart';

/// Extensions for AudioEmotionResult to handle Firestore conversions
extension AudioEmotionResultFirestore on AudioEmotionResult {
  /// Convert to Firestore-compatible JSON with audio-specific fields
  Map<String, dynamic> toFirestoreJson() {
    return {
      'emotion': emotion,
      'confidence': confidence,
      'allEmotions': allEmotions,
      'timestamp': Timestamp.fromDate(timestamp),
      'processingTimeMs': processingTimeMs,
      'error': error,
      'transcribedText': transcribedText,
      'originalLanguage': originalLanguage,
      'translatedText': translatedText,
      'audioFilePath': audioFilePath, // Note: This is local path only
      'audioDuration': audioDuration?.inMilliseconds,
      'hasTranscription': hasTranscription,
      'wasTranslated': wasTranslated,
      'sessionType': 'audio', // Identifier for cloud storage
    };
  }

  /// Create from Firestore document data
  static AudioEmotionResult fromFirestoreJson(Map<String, dynamic> json) {
    // Handle both Firestore Timestamp and String timestamp formats
    final dynamic timestampData = json['timestamp'];
    final DateTime parsedTimestamp = timestampData is Timestamp
        ? timestampData.toDate()
        : DateTime.parse(timestampData.toString());

    return AudioEmotionResult(
      emotion: json['emotion'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      allEmotions: Map<String, double>.from(json['allEmotions'] ?? {}),
      timestamp: parsedTimestamp,
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
}

/// Extensions for cloud sync operations specific to audio emotion results
extension AudioEmotionResultCloudSync on AudioEmotionResult {
  /// Create a cloud-safe copy without local file paths
  AudioEmotionResult toCloudSafeCopy() {
    return copyWith(
      audioFilePath: null, // Remove local path for cloud storage
    );
  }

  /// Check if this audio result has meaningful data for cloud storage
  bool get hasValidAudioData {
    return hasTranscription && transcribedText.trim().isNotEmpty;
  }

  /// Get a summary for cloud storage (without large metadata)
  Map<String, dynamic> toCloudSummary() {
    return {
      'emotion': emotion,
      'confidence': confidence,
      'timestamp': Timestamp.fromDate(timestamp),
      'language': originalLanguage,
      'hasAudio': audioFilePath != null,
      'hasTranscript': hasTranscription,
      'textLength': transcribedText.length,
    };
  }
}
