import 'package:cloud_firestore/cloud_firestore.dart';
import 'emotion_result.dart';

/// Extensions for EmotionResult to handle Firestore conversions
extension EmotionResultFirestore on EmotionResult {
  /// Convert to Firestore-compatible JSON with proper timestamp handling
  Map<String, dynamic> toFirestoreJson() {
    return {
      'emotion': emotion,
      'confidence': confidence,
      'allEmotions': allEmotions,
      'timestamp': Timestamp.fromDate(timestamp),
      'processingTimeMs': processingTimeMs,
      'error': error,
    };
  }

  /// Create from Firestore document data
  static EmotionResult fromFirestoreJson(Map<String, dynamic> json) {
    // Handle both Firestore Timestamp and String timestamp formats
    final dynamic timestampData = json['timestamp'];
    final DateTime parsedTimestamp = timestampData is Timestamp
        ? timestampData.toDate()
        : DateTime.parse(timestampData.toString());

    return EmotionResult(
      emotion: json['emotion'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      allEmotions: Map<String, double>.from(json['allEmotions'] ?? {}),
      timestamp: parsedTimestamp,
      processingTimeMs: json['processingTimeMs'] ?? 0,
      error: json['error'],
    );
  }
}

/// Extensions for handling Firestore operations specific to mood detection
extension EmotionResultCloudSync on EmotionResult {
  /// Generate a document ID based on timestamp for consistent ordering
  String get firestoreDocumentId => timestamp.millisecondsSinceEpoch.toString();

  /// Create a copy with current timestamp (useful for re-saves)
  EmotionResult withCurrentTimestamp() {
    return copyWith(timestamp: DateTime.now());
  }

  /// Check if this result is suitable for cloud storage
  bool get isValidForCloudStorage {
    return !hasError &&
        emotion.isNotEmpty &&
        confidence >= 0.0 &&
        confidence <= 1.0;
  }
}
