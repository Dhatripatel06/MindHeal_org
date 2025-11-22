import 'package:flutter/material.dart';
import '/core/constants/app_constants.dart';

class EmotionUtils {
  
  /// Get color for emotion
  static Color getEmotionColor(String emotion) {
    final colorValue = AppConstants.emotionColors[emotion.toLowerCase()];
    if (colorValue != null) {
      return Color(colorValue);
    }
    return Colors.grey;
  }

  /// Get icon for emotion
  static IconData getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
        return Icons.sentiment_dissatisfied;
      case 'fear':
        return Icons.sentiment_neutral;
      case 'surprise':
        return Icons.sentiment_satisfied;
      case 'disgust':
        return Icons.sentiment_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.sentiment_neutral;
    }
  }

  /// Format confidence percentage
  static String formatConfidence(double confidence) {
    return '${(confidence * 100).toInt()}%';
  }

  /// Get confidence level description
  static String getConfidenceLevel(double confidence) {
    if (confidence >= AppConstants.highConfidenceThreshold) {
      return 'High';
    } else if (confidence >= AppConstants.minConfidenceThreshold) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  /// Get recommendations for emotion
  static List<String> getRecommendations(String emotion) {
    return AppConstants.emotionRecommendations[emotion.toLowerCase()] ?? 
           AppConstants.emotionRecommendations['neutral']!;
  }

  /// Format analysis type
  static String formatAnalysisType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return 'Visual Analysis';
      case 'audio':
        return 'Voice Analysis';
      case 'combined':
        return 'Multi-Modal Analysis';
      default:
        return type;
    }
  }

  /// Format duration
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Format time ago
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Validate emotion label
  static bool isValidEmotion(String emotion) {
    return AppConstants.emotionLabels.contains(emotion.toLowerCase());
  }

  /// Get dominant emotion from map
  static MapEntry<String, double> getDominantEmotion(Map<String, double> emotions) {
    if (emotions.isEmpty) {
      return const MapEntry('neutral', 0.0);
    }
    return emotions.entries.reduce((a, b) => a.value > b.value ? a : b);
  }

  /// Normalize emotion scores
  static Map<String, double> normalizeEmotions(Map<String, double> emotions) {
    final total = emotions.values.fold<double>(0.0, (sum, value) => sum + value);
    if (total == 0) return emotions;
    
    final normalized = <String, double>{};
    emotions.forEach((key, value) {
      normalized[key] = value / total;
    });
    return normalized;
  }

  /// Smooth emotion scores using moving average
  static Map<String, double> smoothEmotions(
    List<Map<String, double>> emotionHistory,
    int windowSize,
  ) {
    if (emotionHistory.isEmpty) return {};

    final smoothed = <String, double>{};
    final allEmotions = emotionHistory.first.keys.toSet();

    for (final emotion in allEmotions) {
      final values = emotionHistory
          .take(windowSize)
          .map((emotions) => emotions[emotion] ?? 0.0)
          .toList();
      
      final average = values.fold<double>(0.0, (sum, value) => sum + value) / values.length;
      smoothed[emotion] = average;
    }

    return smoothed;
  }

  /// Calculate emotion trend (increasing/decreasing)
  static double calculateEmotionTrend(
    String emotion,
    List<Map<String, double>> emotionHistory,
  ) {
    if (emotionHistory.length < 2) return 0.0;

    final recent = emotionHistory.first[emotion] ?? 0.0;
    final previous = emotionHistory[1][emotion] ?? 0.0;
    
    return recent - previous;
  }

  /// Get emotion intensity level
  static String getEmotionIntensity(double confidence) {
    if (confidence >= 0.8) return 'Very Strong';
    if (confidence >= 0.6) return 'Strong';
    if (confidence >= 0.4) return 'Moderate';
    if (confidence >= 0.2) return 'Mild';
    return 'Very Mild';
  }

  /// Convert emotion to mood category
  static String emotionToMoodCategory(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'surprise':
        return 'Positive';
      case 'sad':
      case 'fear':
      case 'disgust':
        return 'Negative';
      case 'angry':
        return 'Intense';
      case 'neutral':
      default:
        return 'Neutral';
    }
  }

  /// Get mood category color
  static Color getMoodCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.blue;
      case 'intense':
        return Colors.red;
      case 'neutral':
      default:
        return Colors.grey;
    }
  }
}
