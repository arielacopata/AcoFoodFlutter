// En: lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_entry.dart';
import '../models/food.dart';
import 'food_repository.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<void> clearTodayHistory() async {
    final db = await instance.database;
    final today = DateTime.now();
    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();

    await db.delete(
      'history',
      where: 'timestamp >= ?',
      whereArgs: [startOfDay],
    );
    print("Historial de hoy borrado de la base de datos.");
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aco_food.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        foodId INTEGER NOT NULL,
        grams REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<FoodEntry> createEntry(FoodEntry entry) async {
    final db = await instance.database;
    final id = await db.insert('history', entry.toMap());
    return FoodEntry(
      id: id,
      food: entry.food,
      grams: entry.grams,
      timestamp: entry.timestamp,
    );
  }

  Future<List<FoodEntry>> getTodayEntries() async {
    final db = await instance.database;
    final today = DateTime.now();
    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();

    final maps = await db.query(
      'history',
      where: 'timestamp >= ?',
      whereArgs: [startOfDay],
      orderBy: 'timestamp DESC',
    );

    if (maps.isEmpty) {
      return [];
    }

    final foodRepo = FoodRepository();
    List<FoodEntry> entries = [];
    for (var map in maps) {
      final foodId = map['foodId'] as int;
      final food = foodRepo.getFoodById(foodId);
      if (food != null) {
        entries.add(
          FoodEntry(
            id: map['id'] as int,
            food: food,
            grams: map['grams'] as double,
            timestamp: DateTime.parse(map['timestamp'] as String),
          ),
        );
      }
    }
    return entries;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
