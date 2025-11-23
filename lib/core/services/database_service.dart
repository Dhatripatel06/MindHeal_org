import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  
  DatabaseService._init();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mental_wellness.db');
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
      CREATE TABLE mood_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood_score INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        notes TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE biofeedback_data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        heart_rate REAL,
        stress_level REAL,
        timestamp TEXT NOT NULL
      )
    ''');
  }
  
  Future<void> init() async {
    await database;
  }
}
