/// Represents the result of emotion detection analysis
class EmotionResult {
  final String emotion;
  final double confidence;
  final Map<String, double> allEmotions;
  final DateTime timestamp;
  final int processingTimeMs;
  final String? error;

  const EmotionResult({
    required this.emotion,
    required this.confidence,
    required this.allEmotions,
    required this.timestamp,
    required this.processingTimeMs,
    this.error,
  });

  /// Whether this result represents an error
  bool get hasError => error != null;

  /// Whether this is a successful detection
  bool get isSuccess => error == null && emotion.isNotEmpty;

  /// Get confidence as a percentage (0-100)
  double get confidencePercentage => confidence * 100;

  /// Get formatted confidence string
  String get confidenceString => '${confidencePercentage.toStringAsFixed(1)}%';

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'confidence': confidence,
      'allEmotions': allEmotions,
      'timestamp': timestamp.toIso8601String(),
      'processingTimeMs': processingTimeMs,
      'error': error,
    };
  }

  /// Create from JSON
  factory EmotionResult.fromJson(Map<String, dynamic> json) {
    return EmotionResult(
      emotion: json['emotion'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      allEmotions: Map<String, double>.from(json['allEmotions'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      processingTimeMs: json['processingTimeMs'] ?? 0,
      error: json['error'],
    );
  }

  /// Create an error result
  factory EmotionResult.error(String errorMessage) {
    return EmotionResult(
      emotion: 'error',
      confidence: 0.0,
      allEmotions: {},
      timestamp: DateTime.now(),
      processingTimeMs: 0,
      error: errorMessage,
    );
  }

  /// Create a copy with updated values
  EmotionResult copyWith({
    String? emotion,
    double? confidence,
    Map<String, double>? allEmotions,
    DateTime? timestamp,
    int? processingTimeMs,
    String? error,
  }) {
    return EmotionResult(
      emotion: emotion ?? this.emotion,
      confidence: confidence ?? this.confidence,
      allEmotions: allEmotions ?? this.allEmotions,
      timestamp: timestamp ?? this.timestamp,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    if (hasError) {
      return 'EmotionResult(error: $error)';
    }
    return 'EmotionResult(emotion: $emotion, confidence: $confidenceString, time: ${processingTimeMs}ms)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionResult &&
          runtimeType == other.runtimeType &&
          emotion == other.emotion &&
          confidence == other.confidence &&
          timestamp == other.timestamp &&
          error == other.error;

  @override
  int get hashCode =>
      emotion.hashCode ^
      confidence.hashCode ^
      timestamp.hashCode ^
      error.hashCode;
}

/// Legacy compatibility - maps to new EmotionResult structure
class EmotionResultLegacy {
  final String dominantEmotion;
  final double confidence;
  final Map<String, double> allEmotions;
  final DateTime timestamp;
  final String analysisType;

  EmotionResultLegacy({
    required this.dominantEmotion,
    required this.confidence,
    required this.allEmotions,
    required this.timestamp,
    required this.analysisType,
  });

  /// Convert to new EmotionResult format
  EmotionResult toEmotionResult() {
    return EmotionResult(
      emotion: dominantEmotion,
      confidence: confidence,
      allEmotions: allEmotions,
      timestamp: timestamp,
      processingTimeMs: 0, // Unknown for legacy results
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dominantEmotion': dominantEmotion,
      'confidence': confidence,
      'allEmotions': allEmotions,
      'timestamp': timestamp.toIso8601String(),
      'analysisType': analysisType,
    };
  }

  factory EmotionResultLegacy.fromJson(Map<String, dynamic> json) {
    return EmotionResultLegacy(
      dominantEmotion: json['dominantEmotion'],
      confidence: json['confidence'],
      allEmotions: Map<String, double>.from(json['allEmotions']),
      timestamp: DateTime.parse(json['timestamp']),
      analysisType: json['analysisType'],
    );
  }
}
