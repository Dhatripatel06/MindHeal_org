class MoodEntry {
  final int? id;
  final int moodScore;
  final DateTime timestamp;
  final String? notes;
  
  const MoodEntry({
    this.id,
    required this.moodScore,
    required this.timestamp,
    this.notes,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood_score': moodScore,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }
  
  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'],
      moodScore: json['mood_score'],
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
    );
  }
}
