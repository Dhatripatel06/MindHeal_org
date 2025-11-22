import 'package:flutter/foundation.dart';
import '/features/mood_detection/data/models/emotion_result.dart';
import '/features/mood_detection/data/models/mood_session.dart';

class MoodDetectionProvider extends ChangeNotifier {
  List<MoodSession> _recentSessions = [];
  int _todaySessions = 0;
  String _averageMood = 'Neutral';
  int _streak = 0;

  // Getters
  List<MoodSession> get recentSessions => _recentSessions;
  int get todaySessions => _todaySessions;
  String get averageMood => _averageMood;
  int get streak => _streak;

  // Initialize provider
  Future<void> initialize() async {
    await _loadRecentSessions();
    await _calculateStats();
    notifyListeners();
  }

  // Add new session
  Future<void> addSession(EmotionResult result) async {
    final session = MoodSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dominantEmotion: result.emotion,
      confidence: result.confidence,
      timestamp: result.timestamp,
      analysisType: 'tflite', // Updated for new TFLite service
      metadata: {
        'allEmotions': result.allEmotions,
        'processingTimeMs': result.processingTimeMs,
      },
    );

    _recentSessions.insert(0, session);
    await _saveSession(session);
    await _calculateStats();
    notifyListeners();
  }

  Future<void> _loadRecentSessions() async {
    // Load from local database
    // This is a placeholder - implement with your database service
    _recentSessions = [];
  }

  Future<void> _saveSession(MoodSession session) async {
    // Save to local database
    // This is a placeholder - implement with your database service
  }

  Future<void> _calculateStats() async {
    final today = DateTime.now();
    _todaySessions = _recentSessions
        .where((session) =>
            session.timestamp.day == today.day &&
            session.timestamp.month == today.month &&
            session.timestamp.year == today.year)
        .length;

    if (_recentSessions.isNotEmpty) {
      // Calculate average mood (simplified)
      final moodCounts = <String, int>{};
      for (final session in _recentSessions.take(10)) {
        moodCounts[session.dominantEmotion] =
            (moodCounts[session.dominantEmotion] ?? 0) + 1;
      }
      
      _averageMood = moodCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // Calculate streak (simplified)
    _streak = _calculateConsecutiveDays();
  }

  int _calculateConsecutiveDays() {
    // Implement streak calculation logic
    return 5; // Placeholder
  }
}
