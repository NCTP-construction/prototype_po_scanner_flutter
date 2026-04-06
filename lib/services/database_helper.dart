import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // This replaces "initDB" - it is the entry point for the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('site_ops.db'); // Calls the internal init
    return _database!;
  }

  // Logic to define the file path and open the connection
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB, // References the separate creation function
    );
  }

  // This handles the actual SQL table creation
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id TEXT,        -- UUID from projects table
        report_date TEXT,
        payload TEXT,           -- The JSON from DailyReportModel
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Helper method to insert the form data
  Future<int> insertReport(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('local_reports', row);
  }
}
