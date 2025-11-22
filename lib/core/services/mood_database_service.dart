import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../shared/models/mood_event.dart';

class MoodDatabaseService {
  static final MoodDatabaseService _instance = MoodDatabaseService._init();
  static Database? _database;

  MoodDatabaseService._init();

  factory MoodDatabaseService() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mood_detection.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mood_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        facial_emotion TEXT,
        facial_confidence REAL,
        voice_emotion TEXT,
        voice_confidence REAL,
        pose_emotion TEXT,
        pose_confidence REAL,
        fused_mood TEXT NOT NULL,
        fused_confidence REAL NOT NULL,
        session_duration INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_mood_events_timestamp ON mood_events(timestamp)
    ''');
  }

  Future<int> insertMoodEvent(MoodEvent event) async {
    final db = await database;
    return await db.insert('mood_events', event.toMap());
  }

  Future<List<MoodEvent>> getAllMoodEvents({int? limit, int? offset}) async {
    final db = await database;
    final result = await db.query(
      'mood_events',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((map) => MoodEvent.fromMap(map)).toList();
  }

  Future<List<MoodEvent>> getMoodEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final result = await db.query(
      'mood_events',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => MoodEvent.fromMap(map)).toList();
  }

  Future<Map<String, int>> getMoodStatistics({int days = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final result = await db.rawQuery('''
      SELECT fused_mood, COUNT(*) as count
      FROM mood_events 
      WHERE timestamp >= ?
      GROUP BY fused_mood
      ORDER BY count DESC
    ''', [cutoffDate.millisecondsSinceEpoch]);

    return Map.fromEntries(
      result.map((row) => MapEntry(
        row['fused_mood'] as String,
        row['count'] as int,
      )),
    );
  }

  Future<double> getAverageConfidence({int days = 7}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final result = await db.rawQuery('''
      SELECT AVG(fused_confidence) as avg_confidence
      FROM mood_events 
      WHERE timestamp >= ?
    ''', [cutoffDate.millisecondsSinceEpoch]);

    return (result.first['avg_confidence'] as double?) ?? 0.0;
  }

  Future<void> updateMoodEvent(MoodEvent event) async {
    final db = await database;
    await db.update(
      'mood_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> deleteMoodEvent(int id) async {
    final db = await database;
    await db.delete('mood_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteOldEvents({int keepDays = 90}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
    
    await db.delete(
      'mood_events',
      where: 'timestamp < ?',
      whereArgs: [cutoffDate.millisecondsSinceEpoch],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
