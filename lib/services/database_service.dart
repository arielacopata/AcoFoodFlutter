// En: lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_entry.dart';
import '../models/user_profile.dart';
import 'food_repository.dart';
import '../models/habit.dart';
import '../models/dashboard_stats.dart';
import '../data/supplements_data.dart';

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
      version: 12, // 👈 subí la versión para que dispare onUpgrade
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
      timestamp TEXT NOT NULL,
      isSupplement INTEGER DEFAULT 0,
      supplementDose TEXT
    )
  ''');

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
      fat INTEGER,
      goalType TEXT,
      goalCalories INTEGER
    )
  ''');

    await db.execute('''
    CREATE TABLE food_usage (
      foodId INTEGER PRIMARY KEY,
      count INTEGER DEFAULT 0
    )
  ''');

    // Pre-poblar con datos de 2 semanas
    await db.execute('''
    INSERT INTO food_usage (foodId, count) VALUES
    (1, 94), (3, 76), (4, 66), (5, 28), (6, 45),
    (7, 16), (10, 14), (12, 25), (15, 32), (22, 16),
    (23, 14), (25, 32), (31, 15), (41, 25), (49, 17)
  ''');
    await db.execute('''
  CREATE TABLE habits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    emoji TEXT,
    type TEXT NOT NULL,
    options TEXT,
    enabled INTEGER DEFAULT 1
  )
''');

    await db.execute('''
  CREATE TABLE habit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    habitId INTEGER NOT NULL,
    date TEXT NOT NULL,
    detail TEXT,
    timestamp TEXT NOT NULL,
    FOREIGN KEY (habitId) REFERENCES habits (id)
  )
''');

    // Insertar hábitos predefinidos
    await db.execute('''
  INSERT INTO habits (name, emoji, type, options) VALUES
  ('Meditar', '🧘', 'predefined', '["5 min","10 min","15 min","20 min"]'),
  ('Respirar', '🫁', 'predefined', '["4-7-8","Cuadrada","Profunda","Wim Hof"]'),
  ('Ducha fría', '🚿', 'predefined', '["30 seg","1 min","2 min","5 min"]'),
  ('Agradecer', '🙏', 'predefined', '["Lista de 3","Journaling","Meditación","A alguien"]'),
  ('Ejercicio', '🏃', 'predefined', '["HIIT","Correr","Gimnasio","Caminar","Bicicleta","General"]')
''');
  }

  Future<Map<int, int>> getFoodUsageCounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('food_usage');
    return {for (var item in maps) item['foodId'] as int: item['count'] as int};
  }

  // onUpgrade se ejecuta si la versión de la BD cambia
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Añadir las columnas nuevas sin borrar datos existentes
      await db.execute("ALTER TABLE user_profile ADD COLUMN carbs INTEGER");
      await db.execute("ALTER TABLE user_profile ADD COLUMN protein INTEGER");
      await db.execute("ALTER TABLE user_profile ADD COLUMN fat INTEGER");
    }

    if (oldVersion < 7) {
      await db.execute('''
      CREATE TABLE food_usage (
        foodId INTEGER PRIMARY KEY,
        count INTEGER DEFAULT 0
      )
    ''');
    }

    if (oldVersion < 8) {
      // Pre-poblar con datos de 2 semanas
      await db.execute('''
      INSERT OR IGNORE INTO food_usage (foodId, count) VALUES
      (1, 94),   -- Avena
      (3, 76),   -- Banana
      (4, 66),   -- Maní
      (6, 45),   -- Nueces
      (25, 32),  -- Zanahoria
      (5, 28),   -- Mandarina
      (41, 25),  -- Soja texturizada
      (12, 25),  -- Calabaza
      (7, 16),   -- Cebolla
      (15, 32),  -- Batata/Boniato
      (49, 17),  -- Lentejas
      (22, 16),  -- Palta
      (31, 15),  -- Tomate
      (10, 14),  -- Garbanzos
      (23, 14)   -- Papa
    ''');
    }
    if (oldVersion < 10) {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS habits (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      emoji TEXT,
      type TEXT NOT NULL,
      options TEXT,
      enabled INTEGER DEFAULT 1
    )
  ''');

      await db.execute('''
    CREATE TABLE IF NOT EXISTS habit_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      habitId INTEGER NOT NULL,
      date TEXT NOT NULL,
      detail TEXT,
      timestamp TEXT NOT NULL,
      FOREIGN KEY (habitId) REFERENCES habits (id)
    )
  ''');

      // Insertar predefinidos si la tabla está vacía
      final existing = await db.query('habits', limit: 1);
      if (existing.isEmpty) {
        await db.execute('''
      INSERT INTO habits (name, emoji, type, options) VALUES
      ('Meditar', '🧘', 'predefined', '["5 min","10 min","15 min","20 min"]'),
      ('Respirar', '🫁', 'predefined', '["4-7-8","Cuadrada","Profunda","Wim Hof"]'),
      ('Ducha fría', '🚿', 'predefined', '["30 seg","1 min","2 min","5 min"]'),
      ('Agradecer', '🙏', 'predefined', '["Lista de 3","Journaling","Meditación","A alguien"]'),
      ('Ejercicio', '🏃', 'predefined', '["HIIT","Correr","Gimnasio","Caminar","Bicicleta","General"]')
    ''');
      }
    }

    if (oldVersion < 11) {
      await db.execute('''
          ALTER TABLE user_profile ADD COLUMN goalType TEXT
        ''');
      await db.execute('''
          ALTER TABLE user_profile ADD COLUMN goalCalories INTEGER
        ''');
    }

    if (oldVersion < 12) {
      // Agregar columnas para suplementos
      await db.execute(
        'ALTER TABLE history ADD COLUMN isSupplement INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE history ADD COLUMN supplementDose TEXT');
    }
  }

  // Obtener todos los hábitos habilitados
  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habits');
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  // Registrar un hábito completado
  Future<void> logHabit(int habitId, String? detail) async {
    final db = await database;
    final now = DateTime.now();
    await db.insert('habit_logs', {
      'habitId': habitId,
      'date': DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String().split('T')[0],
      'detail': detail,
      'timestamp': now.toIso8601String(),
    });
  }

  // Obtener logs de un hábito por fecha
  Future<List<HabitLog>> getHabitLogsByDate(int habitId, DateTime date) async {
    final db = await database;
    final dateStr = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      'habit_logs',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, dateStr],
    );
    return maps.map((map) => HabitLog.fromMap(map)).toList();
  }

  Future<void> updateHabitEnabled(int habitId, bool enabled) async {
    final db = await database;
    await db.update(
      'habits',
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  // Calcular streak (días consecutivos)
  Future<int> calculateStreak(int habitId) async {
    final db = await database;
    final today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateStr = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
      ).toIso8601String().split('T')[0];

      final logs = await db.query(
        'habit_logs',
        where: 'habitId = ? AND date = ?',
        whereArgs: [habitId, dateStr],
      );

      if (logs.isEmpty) {
        break; // Rompió la racha
      }
      streak++;
    }

    return streak;
  }

  // --- MÉTODOS PARA USER_PROFILE ---
  Future<void> incrementFoodUsage(int foodId) async {
    final db = await database;
    await db.execute(
      '''
    INSERT INTO food_usage (foodId, count) VALUES (?, 1)
    ON CONFLICT(foodId) DO UPDATE SET count = count + 1
  ''',
      [foodId],
    );
  }

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

  Future<List<FoodEntry>> getEntriesByDate(DateTime date) async {
    final db = await database;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    List<FoodEntry> entries = [];
    for (var map in maps) {
      var food = FoodRepository().getFoodById(map['foodId']);

      // Si es suplemento, buscar en supplementsList
      if ((map['isSupplement'] ?? 0) == 1) {
        food = supplementsList.firstWhere(
          (s) => s.id == map['foodId'],
          orElse: () => FoodRepository().getFoodById(map['foodId'])!,
        );
      } else {
        // Si es alimento normal, buscar en FoodRepository
        food = FoodRepository().getFoodById(map['foodId']);
      }

      if (food != null) {
        entries.add(
          FoodEntry(
            id: map['id'],
            food: food,
            grams: map['grams'],
            timestamp: DateTime.parse(map['timestamp']),
            isSupplement:
                (map['isSupplement'] ?? 0) == 1, // Leer el campo nuevo
            supplementDose: map['supplementDose'], // Leer el campo nuevo
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
      entry.toMapForUpdate(), // ✅ Sin incluir id
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

  Future<List<Habit>> getEnabledHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habits',
      where: 'enabled = ?',
      whereArgs: [1],
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<void> updateExpenditureForToday(int calories) async {
    final db = await database;

    // Actualizar el expenditure en user_profile
    await db.update(
      'user_profile',
      {'expenditure': calories},
      where: 'id = ?',
      whereArgs: [1], // Asumiendo que el perfil siempre tiene id=1
    );
  }

  Future<DashboardStats> getDashboardStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;

    // Obtener todas las entradas del período
    final entries = await db.query(
      'history',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.add(const Duration(days: 1)).toIso8601String(),
      ],
    );

    // Agrupar por día
    Map<String, List<Map<String, dynamic>>> entriesByDay = {};
    for (var entry in entries) {
      final date = DateTime.parse(entry['timestamp'] as String);
      final dateKey = DateTime(
        date.year,
        date.month,
        date.day,
      ).toIso8601String().split('T')[0];
      entriesByDay.putIfAbsent(dateKey, () => []).add(entry);
    }

    // Calcular datos diarios
    List<DailyData> dailyData = [];
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    final foodRepo = FoodRepository();

for (var dateKey in entriesByDay.keys) {
  double dayCalories = 0;
  double dayProtein = 0;   // Agregar
  double dayCarbs = 0;     // Agregar
  double dayFat = 0;       // Agregar

  for (var entry in entriesByDay[dateKey]!) {
    final food = foodRepo.getFoodById(entry['foodId'] as int);
    if (food != null) {
      final grams = entry['grams'] as double;
      final scale = grams / 100;
      dayCalories += food.calories * scale;
      dayProtein += food.proteins * scale;    // Cambiar totalProtein por dayProtein
      dayCarbs += food.carbohydrates * scale; // Cambiar totalCarbs por dayCarbs
      dayFat += food.totalFats * scale;       // Cambiar totalFat por dayFat
    }
  }

  totalCalories += dayCalories;
  totalProtein += dayProtein;   // Agregar
  totalCarbs += dayCarbs;       // Agregar
  totalFat += dayFat;           // Agregar
  
  dailyData.add(
    DailyData(
      date: DateTime.parse(dateKey),
      calories: dayCalories,
      protein: dayProtein,
      carbs: dayCarbs,
      fat: dayFat,
    ),
  );
}

    final daysCount = entriesByDay.length > 0 ? entriesByDay.length : 1;

    // Top alimentos
    Map<int, TopFood> foodStats = {};
    for (var entry in entries) {
      final foodId = entry['foodId'] as int;
      final grams = entry['grams'] as double;
      final food = foodRepo.getFoodById(foodId);

      if (food != null) {
        if (foodStats.containsKey(foodId)) {
          foodStats[foodId] = TopFood(
            name: food.name,
            fullName: food.fullName ?? food.name,
            emoji: food.emoji,
            timesConsumed: foodStats[foodId]!.timesConsumed + 1,
            totalGrams: foodStats[foodId]!.totalGrams + grams,
          );
        } else {
          foodStats[foodId] = TopFood(
            name: food.name,
            fullName: food.fullName ?? food.name,
            emoji: food.emoji,
            timesConsumed: 1,
            totalGrams: grams,
          );
        }
      }
    }

    final topFoods = foodStats.values.toList()
      ..sort((a, b) => b.timesConsumed.compareTo(a.timesConsumed))
      ..take(5).toList();

    // Completitud de hábitos
    final habits = await db.query('habits');
    Map<String, int> habitCompletion = {};

    for (var habit in habits) {
      final habitId = habit['id'] as int;
      final habitName = habit['name'] as String;

      final logs = await db.query(
        'habit_logs',
        where: 'habitId = ? AND timestamp >= ? AND timestamp < ?',
        whereArgs: [
          habitId,
          startDate.toIso8601String(),
          endDate.add(const Duration(days: 1)).toIso8601String(),
        ],
      );

      // Contar días únicos
      final uniqueDays = logs
          .map((log) {
            final date = DateTime.parse(log['timestamp'] as String);
            return DateTime(
              date.year,
              date.month,
              date.day,
            ).toIso8601String().split('T')[0];
          })
          .toSet()
          .length;

      habitCompletion[habitName] = uniqueDays;
    }

    return DashboardStats(
      startDate: startDate,
      endDate: endDate,
      avgCalories: totalCalories / daysCount,
      avgProtein: totalProtein / daysCount,
      avgCarbs: totalCarbs / daysCount,
      avgFat: totalFat / daysCount,
      dailyData: dailyData,
      topFoods: topFoods,
      habitCompletion: habitCompletion,
    );
  }
}
