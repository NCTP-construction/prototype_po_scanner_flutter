import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('reports.db');
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

  Future _createDB(Database db, int version) async {
    // We store the complex lists (materials, transport) as JSON strings
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        weather TEXT,
        materials TEXT, 
        transport_logs TEXT,
        engines TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertReport(Map<String, dynamic> report) async {
    final db = await instance.database;
    return await db.insert('reports', report);
  }
}