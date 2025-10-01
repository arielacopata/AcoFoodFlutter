// En: lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_entry.dart';
import '../models/user_profile.dart';
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

    return await openDatabase(
      path,
      version: 6, // 👈 subí la versión para que dispare onUpgrade
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
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
    // <-- 2. AÑADE LA CREACIÓN DE LA TABLA user_profile AQUÍ
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        name TEXT,
        email TEXT,
        dob TEXT,
        gender TEXT,
        weight REAL,
        height REAL,
        lifestyle TEXT,
        exerciseLevel TEXT,
        expenditure INTEGER,
        carbs INTEGER,
        protein INTEGER,
        fat INTEGER
      )
    ''');
  }

  // onUpgrade se ejecuta si la versión de la BD cambia
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Añadir las columnas nuevas sin borrar datos existentes
      await db.execute("ALTER TABLE user_profile ADD COLUMN carbs INTEGER");
      await db.execute("ALTER TABLE user_profile ADD COLUMN protein INTEGER");
      await db.execute("ALTER TABLE user_profile ADD COLUMN fat INTEGER");
    }
  }

  // --- MÉTODOS PARA USER_PROFILE ---

  // <-- 3. AÑADE LOS NUEVOS MÉTODOS
  Future<int> saveUserProfile(UserProfile profile) async {
    final db = await instance.database;
    return await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      final db = await instance.database;

      final maps = await db.query(
        'user_profile',
        where: 'id = ?',
        whereArgs: [1],
      );

      if (maps.isNotEmpty) {
        return UserProfile.fromMap(maps.first);
      } else {
        return null; // 👈 simplemente null si no hay nada
      }
    } catch (e, st) {
      print("ERROR en getUserProfile: $e");
      print(st);
      return null;
    }
  }

  Future<void> deleteUserProfile() async {
    final db = await instance.database;
    await db.delete('user_profile', where: 'id = ?', whereArgs: [1]);
    print("Perfil de usuario borrado.");
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

  // Método para actualizar un entry existente
  Future<int> updateEntry(FoodEntry entry) async {
    final db = await instance.database;
    return await db.update(
      'history',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Método para eliminar un entry
  Future<int> deleteEntry(int id) async {
    final db = await instance.database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
