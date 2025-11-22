class MoodEvent {
  final int? id;
  final DateTime timestamp;
  final String? facialEmotion;
  final double? facialConfidence;
  final String? voiceEmotion;
  final double? voiceConfidence;
  final String? poseEmotion;
  final double? poseConfidence;
  final String fusedMood;
  final double fusedConfidence;
  final int sessionDuration;
  final String? notes;

  const MoodEvent({
    this.id,
    required this.timestamp,
    this.facialEmotion,
    this.facialConfidence,
    this.voiceEmotion,
    this.voiceConfidence,
    this.poseEmotion,
    this.poseConfidence,
    required this.fusedMood,
    required this.fusedConfidence,
    required this.sessionDuration,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'facial_emotion': facialEmotion,
      'facial_confidence': facialConfidence,
      'voice_emotion': voiceEmotion,
      'voice_confidence': voiceConfidence,
      'pose_emotion': poseEmotion,
      'pose_confidence': poseConfidence,
      'fused_mood': fusedMood,
      'fused_confidence': fusedConfidence,
      'session_duration': sessionDuration,
      'notes': notes,
    };
  }

  factory MoodEvent.fromMap(Map<String, dynamic> map) {
    return MoodEvent(
      id: map['id']?.toInt(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      facialEmotion: map['facial_emotion'],
      facialConfidence: map['facial_confidence']?.toDouble(),
      voiceEmotion: map['voice_emotion'],
      voiceConfidence: map['voice_confidence']?.toDouble(),
      poseEmotion: map['pose_emotion'],
      poseConfidence: map['pose_confidence']?.toDouble(),
      fusedMood: map['fused_mood'] ?? '',
      fusedConfidence: map['fused_confidence']?.toDouble() ?? 0.0,
      sessionDuration: map['session_duration']?.toInt() ?? 0,
      notes: map['notes'],
    );
  }

  MoodEvent copyWith({
    int? id,
    DateTime? timestamp,
    String? facialEmotion,
    double? facialConfidence,
    String? voiceEmotion,
    double? voiceConfidence,
    String? poseEmotion,
    double? poseConfidence,
    String? fusedMood,
    double? fusedConfidence,
    int? sessionDuration,
    String? notes,
  }) {
    return MoodEvent(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      facialEmotion: facialEmotion ?? this.facialEmotion,
      facialConfidence: facialConfidence ?? this.facialConfidence,
      voiceEmotion: voiceEmotion ?? this.voiceEmotion,
      voiceConfidence: voiceConfidence ?? this.voiceConfidence,
      poseEmotion: poseEmotion ?? this.poseEmotion,
      poseConfidence: poseConfidence ?? this.poseConfidence,
      fusedMood: fusedMood ?? this.fusedMood,
      fusedConfidence: fusedConfidence ?? this.fusedConfidence,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      notes: notes ?? this.notes,
    );
  }
}

class EmotionResult {
  final String emotion;
  final double confidence;
  final DateTime timestamp;

  const EmotionResult({
    required this.emotion,
    required this.confidence,
    required this.timestamp,
  });
}
