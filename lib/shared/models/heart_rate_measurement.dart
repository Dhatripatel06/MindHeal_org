import 'package:cloud_firestore/cloud_firestore.dart';

enum MeasurementMethod { camera, smartwatch, manual }

class HeartRateMeasurement {
  final String? id;
  final String userId;
  final int bpm;
  final MeasurementMethod method;
  final DateTime timestamp;
  final double? confidenceScore;
  final Map<String, dynamic>? metadata;

  const HeartRateMeasurement({
    this.id,
    required this.userId,
    required this.bpm,
    required this.method,
    required this.timestamp,
    this.confidenceScore,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'bpm': bpm,
      'method': method.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'confidenceScore': confidenceScore,
      'metadata': metadata ?? {},
    };
  }

  factory HeartRateMeasurement.fromJson(Map<String, dynamic> json, String id) {
    return HeartRateMeasurement(
      id: id,
      userId: json['userId'],
      bpm: json['bpm'],
      method: MeasurementMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => MeasurementMethod.manual,
      ),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      confidenceScore: json['confidenceScore']?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  HeartRateMeasurement copyWith({
    String? id,
    String? userId,
    int? bpm,
    MeasurementMethod? method,
    DateTime? timestamp,
    double? confidenceScore,
    Map<String, dynamic>? metadata,
  }) {
    return HeartRateMeasurement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bpm: bpm ?? this.bpm,
      method: method ?? this.method,
      timestamp: timestamp ?? this.timestamp,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      metadata: metadata ?? this.metadata,
    );
  }
}
