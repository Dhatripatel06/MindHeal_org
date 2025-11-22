// mood_session.dart
class MoodSession {
  final String id;
  final String dominantEmotion;
  final double confidence;
  final DateTime timestamp;
  final String analysisType;
  final Map<String, dynamic>? metadata;

  MoodSession({
    required this.id,
    required this.dominantEmotion,
    required this.confidence,
    required this.timestamp,
    required this.analysisType,
    this.metadata,
  });

  factory MoodSession.fromJson(Map<String, dynamic> json) {
    return MoodSession(
      id: json['id'],
      dominantEmotion: json['dominantEmotion'],
      confidence: json['confidence'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      analysisType: json['analysisType'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dominantEmotion': dominantEmotion,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'analysisType': analysisType,
      'metadata': metadata,
    };
  }
}
