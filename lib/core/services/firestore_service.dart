import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

import '../../shared/models/heart_rate_measurement.dart';
import '../../features/mood_detection/data/models/emotion_result.dart';
import '../../features/mood_detection/data/models/audio_emotion_result.dart';

/// Service for handling Firestore operations for Mental Wellness app
/// Manages biofeedback and mood session data across devices
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID, returns null if not authenticated
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isUserAuthenticated => _currentUserId != null;

  /// Get user's biofeedback collection reference
  CollectionReference? get _biofeedbackCollection {
    final userId = _currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('biofeedback');
  }

  /// Get user's mood sessions collection reference
  CollectionReference? get _moodSessionsCollection {
    final userId = _currentUserId;
    if (userId == null) return null;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_sessions');
  }

  // ==================== BIOFEEDBACK METHODS ====================

  /// Save heart rate measurement to Firestore
  ///
  /// [measurement] - The heart rate measurement to save
  ///
  /// Throws [Exception] if user is not authenticated or save fails
  Future<void> saveBiofeedback(HeartRateMeasurement measurement) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User must be authenticated to save biofeedback data');
      }

      final collection = _biofeedbackCollection;
      if (collection == null) {
        throw Exception('Unable to access biofeedback collection');
      }

      // Use timestamp-based ID for consistent ordering
      final docId = measurement.timestamp.millisecondsSinceEpoch.toString();

      await collection.doc(docId).set(measurement.toJson());

      dev.log('✅ Biofeedback saved successfully: ${measurement.bpm} BPM',
          name: 'FirestoreService');
    } catch (e) {
      dev.log('❌ Error saving biofeedback: $e', name: 'FirestoreService');
      rethrow;
    }
  }

  /// Get stream of user's biofeedback history
  ///
  /// Returns [Stream<List<HeartRateMeasurement>>] ordered by timestamp (newest first)
  /// Returns empty stream if user is not authenticated
  Stream<List<HeartRateMeasurement>> getBiofeedbackHistory() {
    if (!isUserAuthenticated) {
      dev.log('⚠️ User not authenticated, returning empty biofeedback stream',
          name: 'FirestoreService');
      return Stream.value([]);
    }

    final collection = _biofeedbackCollection;
    if (collection == null) {
      return Stream.value([]);
    }

    return collection
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit to last 100 measurements for performance
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          return HeartRateMeasurement.fromJson(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      } catch (e) {
        dev.log('❌ Error parsing biofeedback data: $e',
            name: 'FirestoreService');
        return <HeartRateMeasurement>[];
      }
    }).handleError((error) {
      dev.log('❌ Error in biofeedback stream: $error',
          name: 'FirestoreService');
    });
  }

  /// Get biofeedback data for a specific date range
  Future<List<HeartRateMeasurement>> getBiofeedbackByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User must be authenticated to fetch biofeedback data');
      }

      final collection = _biofeedbackCollection;
      if (collection == null) {
        throw Exception('Unable to access biofeedback collection');
      }

      final snapshot = await collection
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return HeartRateMeasurement.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      dev.log('❌ Error fetching biofeedback by date range: $e',
          name: 'FirestoreService');
      rethrow;
    }
  }

  // ==================== MOOD SESSION METHODS ====================

  /// Save mood session result to Firestore
  ///
  /// [result] - The emotion result to save (EmotionResult or AudioEmotionResult)
  /// [type] - Optional type identifier ('audio', 'image', etc.)
  ///
  /// Throws [Exception] if user is not authenticated or save fails
  Future<void> saveMoodSession(EmotionResult result, {String? type}) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User must be authenticated to save mood session data');
      }

      final collection = _moodSessionsCollection;
      if (collection == null) {
        throw Exception('Unable to access mood sessions collection');
      }

      // Use timestamp-based ID for consistent ordering
      final docId = result.timestamp.millisecondsSinceEpoch.toString();

      // Prepare data for Firestore
      final data = _prepareMoodSessionData(result, type);

      await collection.doc(docId).set(data);

      dev.log(
          '✅ Mood session saved successfully: ${result.emotion} (${type ?? 'unknown'})',
          name: 'FirestoreService');
    } catch (e) {
      dev.log('❌ Error saving mood session: $e', name: 'FirestoreService');
      rethrow;
    }
  }

  /// Prepare mood session data for Firestore storage
  Map<String, dynamic> _prepareMoodSessionData(
      EmotionResult result, String? type) {
    final baseData = {
      'emotion': result.emotion,
      'confidence': result.confidence,
      'allEmotions': result.allEmotions,
      'timestamp': Timestamp.fromDate(result.timestamp),
      'processingTimeMs': result.processingTimeMs,
      'error': result.error,
      'sessionType': type ?? 'unknown',
    };

    // Add audio-specific fields if it's an AudioEmotionResult
    if (result is AudioEmotionResult) {
      baseData.addAll({
        'transcribedText': result.transcribedText,
        'originalLanguage': result.originalLanguage,
        'translatedText': result.translatedText,
        'audioFilePath': result.audioFilePath, // Note: This is local path only
        'audioDuration': result.audioDuration?.inMilliseconds,
        'hasTranscription': result.hasTranscription,
        'wasTranslated': result.wasTranslated,
      });
    }

    return baseData;
  }

  /// Get stream of user's mood session history
  ///
  /// Returns [Stream<List<EmotionResult>>] ordered by timestamp (newest first)
  /// Returns empty stream if user is not authenticated
  Stream<List<EmotionResult>> getMoodHistory() {
    if (!isUserAuthenticated) {
      dev.log('⚠️ User not authenticated, returning empty mood history stream',
          name: 'FirestoreService');
      return Stream.value([]);
    }

    final collection = _moodSessionsCollection;
    if (collection == null) {
      return Stream.value([]);
    }

    return collection
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit to last 100 sessions for performance
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _parseEmotionResult(data, doc.id);
        }).toList();
      } catch (e) {
        dev.log('❌ Error parsing mood session data: $e',
            name: 'FirestoreService');
        return <EmotionResult>[];
      }
    }).handleError((error) {
      dev.log('❌ Error in mood history stream: $error',
          name: 'FirestoreService');
    });
  }

  /// Parse emotion result from Firestore data
  EmotionResult _parseEmotionResult(Map<String, dynamic> data, String id) {
    final sessionType = data['sessionType'] as String?;

    // Convert Firestore Timestamp to DateTime
    final timestamp = data['timestamp'] is Timestamp
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.parse(data['timestamp'] as String);

    // Check if it's audio - either by sessionType OR by presence of transcribedText
    final isAudioSession =
        (sessionType == 'audio' || data.containsKey('transcribedText'));

    if (isAudioSession && data.containsKey('transcribedText')) {
      // Return AudioEmotionResult
      return AudioEmotionResult(
        emotion: data['emotion'] ?? '',
        confidence: (data['confidence'] ?? 0.0).toDouble(),
        allEmotions: Map<String, double>.from(data['allEmotions'] ?? {}),
        timestamp: timestamp,
        processingTimeMs: data['processingTimeMs'] ?? 0,
        transcribedText: data['transcribedText'] ?? '',
        originalLanguage: data['originalLanguage'] ?? 'English',
        translatedText: data['translatedText'],
        audioFilePath: data['audioFilePath'],
        audioDuration: data['audioDuration'] != null
            ? Duration(milliseconds: data['audioDuration'])
            : null,
        error: data['error'],
      );
    } else {
      // Return base EmotionResult
      return EmotionResult(
        emotion: data['emotion'] ?? '',
        confidence: (data['confidence'] ?? 0.0).toDouble(),
        allEmotions: Map<String, double>.from(data['allEmotions'] ?? {}),
        timestamp: timestamp,
        processingTimeMs: data['processingTimeMs'] ?? 0,
        error: data['error'],
      );
    }
  }

  /// Get mood session data for a specific date range
  Future<List<EmotionResult>> getMoodSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception(
            'User must be authenticated to fetch mood session data');
      }

      final collection = _moodSessionsCollection;
      if (collection == null) {
        throw Exception('Unable to access mood sessions collection');
      }

      final snapshot = await collection
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _parseEmotionResult(data, doc.id);
      }).toList();
    } catch (e) {
      dev.log('❌ Error fetching mood sessions by date range: $e',
          name: 'FirestoreService');
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Delete a specific biofeedback measurement
  Future<void> deleteBiofeedbackMeasurement(String measurementId) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception(
            'User must be authenticated to delete biofeedback data');
      }

      final collection = _biofeedbackCollection;
      if (collection == null) {
        throw Exception('Unable to access biofeedback collection');
      }

      await collection.doc(measurementId).delete();
      dev.log('✅ Biofeedback measurement deleted: $measurementId',
          name: 'FirestoreService');
    } catch (e) {
      dev.log('❌ Error deleting biofeedback measurement: $e',
          name: 'FirestoreService');
      rethrow;
    }
  }

  /// Delete a specific mood session
  Future<void> deleteMoodSession(String sessionId) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception(
            'User must be authenticated to delete mood session data');
      }

      final collection = _moodSessionsCollection;
      if (collection == null) {
        throw Exception('Unable to access mood sessions collection');
      }

      await collection.doc(sessionId).delete();
      dev.log('✅ Mood session deleted: $sessionId', name: 'FirestoreService');
    } catch (e) {
      dev.log('❌ Error deleting mood session: $e', name: 'FirestoreService');
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User must be authenticated to fetch statistics');
      }

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Get biofeedback stats
      final biofeedbackWeek = await getBiofeedbackByDateRange(weekAgo, now);
      final biofeedbackMonth = await getBiofeedbackByDateRange(monthAgo, now);

      // Get mood session stats
      final moodWeek = await getMoodSessionsByDateRange(weekAgo, now);
      final moodMonth = await getMoodSessionsByDateRange(monthAgo, now);

      return {
        'biofeedback': {
          'weekCount': biofeedbackWeek.length,
          'monthCount': biofeedbackMonth.length,
          'averageBPMWeek': biofeedbackWeek.isNotEmpty
              ? biofeedbackWeek.map((m) => m.bpm).reduce((a, b) => a + b) /
                  biofeedbackWeek.length
              : 0,
          'averageBPMMonth': biofeedbackMonth.isNotEmpty
              ? biofeedbackMonth.map((m) => m.bpm).reduce((a, b) => a + b) /
                  biofeedbackMonth.length
              : 0,
        },
        'moodSessions': {
          'weekCount': moodWeek.length,
          'monthCount': moodMonth.length,
          'topEmotionWeek': _getTopEmotion(moodWeek),
          'topEmotionMonth': _getTopEmotion(moodMonth),
        },
        'lastUpdated': Timestamp.now(),
      };
    } catch (e) {
      dev.log('❌ Error fetching user statistics: $e', name: 'FirestoreService');
      rethrow;
    }
  }

  /// Get the most frequent emotion from a list of results
  String _getTopEmotion(List<EmotionResult> results) {
    if (results.isEmpty) return 'No data';

    final emotionCounts = <String, int>{};
    for (final result in results) {
      emotionCounts[result.emotion] = (emotionCounts[result.emotion] ?? 0) + 1;
    }

    return emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Clear all user data (use with caution)
  Future<void> clearAllUserData() async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('User must be authenticated to clear data');
      }

      // Delete all biofeedback data
      final biofeedbackCollection = _biofeedbackCollection;
      if (biofeedbackCollection != null) {
        final biofeedbackSnapshot = await biofeedbackCollection.get();
        for (final doc in biofeedbackSnapshot.docs) {
          await doc.reference.delete();
        }
      }

      // Delete all mood session data
      final moodSessionsCollection = _moodSessionsCollection;
      if (moodSessionsCollection != null) {
        final moodSessionsSnapshot = await moodSessionsCollection.get();
        for (final doc in moodSessionsSnapshot.docs) {
          await doc.reference.delete();
        }
      }

      dev.log('✅ All user data cleared successfully', name: 'FirestoreService');
    } catch (e) {
      dev.log('❌ Error clearing user data: $e', name: 'FirestoreService');
      rethrow;
    }
  }
}
