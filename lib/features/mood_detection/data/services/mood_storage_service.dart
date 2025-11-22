import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/emotion_result.dart';
import '../models/mood_session.dart';

class MoodStorageService {
  static final MoodStorageService _instance = MoodStorageService._internal();
  factory MoodStorageService() => _instance;
  MoodStorageService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mood_detection.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mood_sessions (
        id TEXT PRIMARY KEY,
        dominant_emotion TEXT NOT NULL,
        confidence REAL NOT NULL,
        timestamp TEXT NOT NULL,
        analysis_type TEXT NOT NULL,
        all_emotions TEXT NOT NULL,
        metadata TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sessions_timestamp ON mood_sessions(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_sessions_emotion ON mood_sessions(dominant_emotion)
    ''');
  }

  Future<void> saveMoodSession(EmotionResult result) async {
    final db = await database;
    
    final session = MoodSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dominantEmotion: result.emotion,
      confidence: result.confidence,
      timestamp: result.timestamp,
      analysisType: 'tflite',  // Default analysis type since EmotionResult no longer has this field
      metadata: {
        'allEmotions': result.allEmotions,
        'processingTimeMs': result.processingTimeMs,
        'error': result.error,
      },
    );

    await db.insert(
      'mood_sessions',
      {
        'id': session.id,
        'dominant_emotion': session.dominantEmotion,
        'confidence': session.confidence,
        'timestamp': session.timestamp.toIso8601String(),
        'analysis_type': session.analysisType,
        'all_emotions': jsonEncode(result.allEmotions),
        'metadata': session.metadata != null ? jsonEncode(session.metadata) : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MoodSession>> getMoodSessions({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      whereClause = 'WHERE timestamp BETWEEN ? AND ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'mood_sessions',
      where: whereClause.isNotEmpty ? whereClause.replaceFirst('WHERE ', '') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => MoodSession(
      id: map['id'],
      dominantEmotion: map['dominant_emotion'],
      confidence: map['confidence'],
      timestamp: DateTime.parse(map['timestamp']),
      analysisType: map['analysis_type'],
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
    )).toList();
  }

  Future<Map<String, int>> getMoodStatistics({int days = 30}) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days));

    final List<Map<String, dynamic>> maps = await db.query(
      'mood_sessions',
      columns: ['dominant_emotion', 'COUNT(*) as count'],
      where: 'timestamp >= ?',
      whereArgs: [startDate.toIso8601String()],
      groupBy: 'dominant_emotion',
      orderBy: 'count DESC',
    );

    final Map<String, int> statistics = {};
    for (final map in maps) {
      statistics[map['dominant_emotion']] = map['count'];
    }

    return statistics;
  }

  Future<void> deleteMoodSession(String id) async {
    final db = await database;
    await db.delete(
      'mood_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllSessions() async {
    final db = await database;
    await db.delete('mood_sessions');
  }

  Future<void> saveUserPreference(String key, String value) async {
    final db = await database;
    await db.insert(
      'user_preferences',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getUserPreference(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'];
    }
    return null;
  }

  Future<List<EmotionResult>> exportSessionsAsEmotionResults({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sessions = await getMoodSessions(
      startDate: startDate,
      endDate: endDate,
      limit: 1000,
    );

    return sessions.map((session) => EmotionResult(
      emotion: session.dominantEmotion,
      confidence: session.confidence,
      allEmotions: session.metadata?['allEmotions']?.cast<String, double>() ?? {},
      timestamp: session.timestamp,
      processingTimeMs: session.metadata?['processingTimeMs'] ?? 0,
      error: session.metadata?['error'],
    )).toList();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
