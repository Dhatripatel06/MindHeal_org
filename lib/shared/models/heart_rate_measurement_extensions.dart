import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/models/heart_rate_measurement.dart';

/// Extensions for HeartRateMeasurement to handle Firestore conversions
extension HeartRateMeasurementFirestore on HeartRateMeasurement {
  /// Convert to Firestore-compatible JSON with proper timestamp handling
  Map<String, dynamic> toFirestoreJson() {
    return {
      'userId': userId,
      'bpm': bpm,
      'method': method.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'confidenceScore': confidenceScore,
      'metadata': metadata ?? {},
    };
  }

  /// Create from Firestore document data
  static HeartRateMeasurement fromFirestoreJson(
      Map<String, dynamic> json, String docId) {
    // Handle both Firestore Timestamp and String timestamp formats
    final dynamic timestampData = json['timestamp'];
    final DateTime parsedTimestamp = timestampData is Timestamp
        ? timestampData.toDate()
        : DateTime.parse(timestampData.toString());

    return HeartRateMeasurement(
      id: docId,
      userId: json['userId'] ?? '',
      bpm: json['bpm'] ?? 0,
      method: MeasurementMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => MeasurementMethod.manual,
      ),
      timestamp: parsedTimestamp,
      confidenceScore: json['confidenceScore']?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Extensions for cloud sync operations specific to heart rate measurements
extension HeartRateMeasurementCloudSync on HeartRateMeasurement {
  /// Generate a document ID based on timestamp for consistent ordering
  String get firestoreDocumentId => timestamp.millisecondsSinceEpoch.toString();

  /// Check if this measurement is valid for cloud storage
  bool get isValidForCloudStorage {
    return bpm > 30 && bpm < 220 && userId.isNotEmpty;
  }

  /// Create a copy with current timestamp (useful for re-saves)
  HeartRateMeasurement withCurrentTimestamp() {
    return copyWith(timestamp: DateTime.now());
  }

  /// Get a summary for analytics
  Map<String, dynamic> toAnalyticsSummary() {
    return {
      'bpm': bpm,
      'method': method.name,
      'confidence': confidenceScore,
      'timestamp': Timestamp.fromDate(timestamp),
      'isResting': bpm >= 60 && bpm <= 80,
      'isElevated': bpm > 100,
    };
  }

  /// Check if this is a resting heart rate measurement
  bool get isRestingHeartRate => bpm >= 60 && bpm <= 100;

  /// Check if this measurement indicates elevated heart rate
  bool get isElevatedHeartRate => bpm > 100;

  /// Get heart rate category as string
  String get heartRateCategory {
    if (bpm < 60) return 'Low';
    if (bpm >= 60 && bpm <= 100) return 'Normal';
    if (bpm > 100 && bpm <= 140) return 'Elevated';
    if (bpm > 140) return 'High';
    return 'Unknown';
  }
}
