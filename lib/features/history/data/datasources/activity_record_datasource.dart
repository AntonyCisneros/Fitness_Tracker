import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/activity_record.dart';

class ActivityRecordDataSource {
  static final ActivityRecordDataSource _instance =
      ActivityRecordDataSource._internal();
  factory ActivityRecordDataSource() => _instance;
  ActivityRecordDataSource._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fitness_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE activity_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            stepCount INTEGER NOT NULL,
            activityType TEXT NOT NULL,
            estimatedCalories REAL NOT NULL,
            distanceKm REAL NOT NULL DEFAULT 0,
            durationMinutes INTEGER NOT NULL DEFAULT 0,
            notes TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertRecord(ActivityRecord record) async {
    final db = await database;
    return await db.insert(
      'activity_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ActivityRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query(
      'activity_records',
      orderBy: 'date DESC',
    );
    return maps.map((map) => ActivityRecord.fromMap(map)).toList();
  }

  Future<ActivityRecord?> getRecordById(int id) async {
    final db = await database;
    final maps = await db.query(
      'activity_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ActivityRecord.fromMap(maps.first);
  }

  Future<int> updateRecord(ActivityRecord record) async {
    final db = await database;
    return await db.update(
      'activity_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      'activity_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllRecords() async {
    final db = await database;
    return await db.delete('activity_records');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
