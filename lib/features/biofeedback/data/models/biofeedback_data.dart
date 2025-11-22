class BiofeedbackData {
  final DateTime timestamp;
  final int heartRate;
  final double stressLevel;
  final int hrvScore;
  final int breathingRate;

  BiofeedbackData({
    required this.timestamp,
    required this.heartRate,
    required this.stressLevel,
    required this.hrvScore,
    required this.breathingRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'heartRate': heartRate,
      'stressLevel': stressLevel,
      'hrvScore': hrvScore,
      'breathingRate': breathingRate,
    };
  }

  factory BiofeedbackData.fromJson(Map<String, dynamic> json) {
    return BiofeedbackData(
      timestamp: DateTime.parse(json['timestamp']),
      heartRate: json['heartRate'],
      stressLevel: json['stressLevel'].toDouble(),
      hrvScore: json['hrvScore'],
      breathingRate: json['breathingRate'],
    );
  }
}
