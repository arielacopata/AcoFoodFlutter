// En: lib/services/storage_factory.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_entry.dart';
import '../models/user_profile.dart';
import 'food_repository.dart';
import '../models/habit.dart';
import '../models/dashboard_stats.dart';
import '../data/supplements_data.dart';
import '../models/recipe.dart';

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
      version: 15, // 👈 subí la versión para que dispare onUpgrade
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

    // Tabla de recetas
    await db.execute('''
  CREATE TABLE recipes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    emoji TEXT,
    created_at TEXT NOT NULL
  )
''');

    // Tabla de ingredientes de recetas
    await db.execute('''
  CREATE TABLE recipe_ingredients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    food_id INTEGER NOT NULL,
    grams REAL NOT NULL,
    FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
  )
''');

    // Tabla de custom_foods
    await db.execute('''
CREATE TABLE custom_foods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      emoji TEXT NOT NULL,
      name TEXT NOT NULL,
      fullName TEXT,
      calories REAL DEFAULT 0,
      proteins REAL DEFAULT 0,
      carbohydrates REAL DEFAULT 0,
      fiber REAL DEFAULT 0,
      totalSugars REAL DEFAULT 0,
      totalFats REAL DEFAULT 0,
      saturatedFats REAL DEFAULT 0,
      omega3 REAL DEFAULT 0,
      omega6 REAL DEFAULT 0,
      omega9 REAL DEFAULT 0,
      calcium REAL DEFAULT 0,
      iron REAL DEFAULT 0,
      magnesium REAL DEFAULT 0,
      phosphorus REAL DEFAULT 0,
      potassium REAL DEFAULT 0,
      sodium REAL DEFAULT 0,
      zinc REAL DEFAULT 0,
      copper REAL DEFAULT 0,
      manganese REAL DEFAULT 0,
      selenium REAL DEFAULT 0,
      iodine REAL DEFAULT 0,
      molybdenum REAL DEFAULT 0,
      chromium REAL DEFAULT 0,
      fluorine REAL DEFAULT 0,
      vitaminA REAL DEFAULT 0,
      vitaminC REAL DEFAULT 0,
      vitaminD REAL DEFAULT 0,
      vitaminE REAL DEFAULT 0,
      vitaminK REAL DEFAULT 0,
      vitaminB1 REAL DEFAULT 0,
      vitaminB2 REAL DEFAULT 0,
      vitaminB3 REAL DEFAULT 0,
      vitaminB4 REAL DEFAULT 0,
      vitaminB5 REAL DEFAULT 0,
      vitaminB6 REAL DEFAULT 0,
      vitaminB7 REAL DEFAULT 0,
      vitaminB9 REAL DEFAULT 0,
      vitaminB12 REAL DEFAULT 0,
      histidine REAL DEFAULT 0,
      isoleucine REAL DEFAULT 0,
      leucine REAL DEFAULT 0,
      lysine REAL DEFAULT 0,
      methionine REAL DEFAULT 0,
      phenylalanine REAL DEFAULT 0,
      threonine REAL DEFAULT 0,
      tryptophan REAL DEFAULT 0,
      valine REAL DEFAULT 0,
      alanine REAL DEFAULT 0,
      arginine REAL DEFAULT 0,
      asparticAcid REAL DEFAULT 0,
      glutamicAcid REAL DEFAULT 0,
      glycine REAL DEFAULT 0,
      proline REAL DEFAULT 0,
      serine REAL DEFAULT 0,
      tyrosine REAL DEFAULT 0,
      cysteine REAL DEFAULT 0,
      glutamine REAL DEFAULT 0,
      asparagine REAL DEFAULT 0,
      createdAt TEXT NOT NULL
    )
''');

// Después del CREATE TABLE custom_foods
await db.execute('''
  INSERT INTO custom_foods (
    id, emoji, name, fullName, calories, proteins, carbohydrates,
    fiber, totalSugars, totalFats, saturatedFats, omega3, omega6, omega9,
    calcium, iron, magnesium, phosphorus, potassium, sodium, zinc,
    copper, manganese, selenium, iodine, molybdenum, chromium, fluorine,
    vitaminA, vitaminC, vitaminD, vitaminE, vitaminK, vitaminB1, vitaminB2,
    vitaminB3, vitaminB4, vitaminB5, vitaminB6, vitaminB7, vitaminB9, vitaminB12,
    histidine, isoleucine, leucine, lysine, methionine, phenylalanine,
    threonine, tryptophan, valine, alanine, arginine, asparticAcid,
    glutamicAcid, glycine, proline, serine, tyrosine, cysteine,
    glutamine, asparagine, createdAt
  ) VALUES (
    9999, '🔒', '__RESERVED__', 'Separador de IDs', 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, datetime('now')
  )
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

    if (oldVersion < 13) {
      // Agregar tablas de recetas
      await db.execute('''
    CREATE TABLE IF NOT EXISTS recipes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      emoji TEXT,
      created_at TEXT NOT NULL
    )
  ''');

      await db.execute('''
    CREATE TABLE IF NOT EXISTS recipe_ingredients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL,
      food_id INTEGER NOT NULL,
      grams REAL NOT NULL,
      FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
    )
  ''');
    }
    // 👇 AGREGAR ESTO:
    if (oldVersion < 14) {
      await db.execute('ALTER TABLE foods ADD COLUMN alanine REAL DEFAULT 0');
      await db.execute('ALTER TABLE foods ADD COLUMN arginine REAL DEFAULT 0');
      await db.execute(
        'ALTER TABLE foods ADD COLUMN aspartic_acid REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE foods ADD COLUMN glutamic_acid REAL DEFAULT 0',
      );
      await db.execute('ALTER TABLE foods ADD COLUMN glycine REAL DEFAULT 0');
      await db.execute('ALTER TABLE foods ADD COLUMN proline REAL DEFAULT 0');
      await db.execute('ALTER TABLE foods ADD COLUMN serine REAL DEFAULT 0');
      await db.execute('ALTER TABLE foods ADD COLUMN tyrosine REAL DEFAULT 0');
    }
    if (oldVersion < 15) {
      await db.execute('ALTER TABLE foods ADD COLUMN cysteine REAL DEFAULT 0');
      await db.execute('ALTER TABLE foods ADD COLUMN glutamine REAL DEFAULT 0');
      await db.execute(
        'ALTER TABLE foods ADD COLUMN asparagine REAL DEFAULT 0',
      );
    }

    if (oldVersion < 16) {
      // Agregar aminoácidos no esenciales a custom_foods
      await db.execute(
        'ALTER TABLE custom_foods ADD COLUMN alanine REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE custom_foods ADD COLUMN arginine REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE custom_foods ADD COLUMN asparticAcid REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE custom_foods ADD COLUMN glutamicAcid REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE custom_foods ADD COLUMN glycine REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE custom_foods ADD COLUMN proline REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE custom_foods ADD COLUMN serine REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE custom_foods ADD COLUMN tyrosine REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE custom_foods ADD COLUMN cysteine REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE custom_foods ADD COLUMN glutamine REAL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE custom_foods ADD COLUMN asparagine REAL DEFAULT 0',
      );

      // Insertar registro dummy en ID 9999 para forzar AUTOINCREMENT desde 10000
      await db.execute('''
    INSERT OR IGNORE INTO custom_foods (
      id, emoji, name, fullName, calories, proteins, carbohydrates,
      fiber, totalSugars, totalFats, saturatedFats, omega3, omega6, omega9,
      calcium, iron, magnesium, phosphorus, potassium, sodium, zinc,
      copper, manganese, selenium, iodine, molybdenum, chromium, fluorine,
      vitaminA, vitaminC, vitaminD, vitaminE, vitaminK, vitaminB1, vitaminB2,
      vitaminB3, vitaminB4, vitaminB5, vitaminB6, vitaminB7, vitaminB9, vitaminB12,
      histidine, isoleucine, leucine, lysine, methionine, phenylalanine,
      threonine, tryptophan, valine, alanine, arginine, asparticAcid,
      glutamicAcid, glycine, proline, serine, tyrosine, cysteine,
      glutamine, asparagine, createdAt
    ) VALUES (
      9999, '🔒', '__RESERVED__', 'Separador de IDs', 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, datetime('now')
    )
  ''');
    }
  }

  // Obtener todos los hábitos habilitados
  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habits');
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  // Registrar un hábito completado
  Future<void> logHabit(
    int habitId,
    String? detail, {
    DateTime? date,
    DateTime? timestamp,
  }) async {
    final db = await database;
    final now = DateTime.now();
    final logDate = date ?? now;
    final logTimestamp = timestamp ?? now;

    await db.insert('habit_logs', {
      'habitId': habitId,
      'date': DateTime(
        logDate.year,
        logDate.month,
        logDate.day,
      ).toIso8601String().split('T')[0],
      'detail': detail,
      'timestamp': logTimestamp.toIso8601String(),
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

  // ============ MÉTODOS DE RECETAS ============

  /// Guardar una receta completa con sus ingredientes
  Future<int> saveRecipe(
    Recipe recipe,
    List<RecipeIngredient> ingredients,
  ) async {
    final db = await database;

    // Guardar la receta
    final recipeId = await db.insert('recipes', recipe.toMap());

    // Guardar cada ingrediente
    for (final ingredient in ingredients) {
      await db.insert('recipe_ingredients', {
        'recipe_id': recipeId,
        'food_id': ingredient.food.id,
        'grams': ingredient.grams,
      });
    }

    return recipeId;
  }

  /// Obtener todas las recetas
  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Recipe.fromMap(map)).toList();
  }

  /// Obtener los ingredientes de una receta
  Future<List<RecipeIngredient>> getRecipeIngredients(int recipeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipe_ingredients',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
    );

    List<RecipeIngredient> ingredients = [];

    // Por cada ingrediente, obtener el Food correspondiente
    for (final map in maps) {
      final foodId = map['food_id'] as int;
      final food = FoodRepository().getFoodById(foodId);
      if (food != null) {
        ingredients.add(RecipeIngredient.fromMap(map, food));
      }
    }

    return ingredients;
  }

  /// Registrar todos los ingredientes de una receta
  Future<void> registerRecipeIngredients(int recipeId) async {
    final ingredients = await getRecipeIngredients(recipeId);

    for (final ingredient in ingredients) {
      final entry = FoodEntry(food: ingredient.food, grams: ingredient.grams);
      await createEntry(entry);
      await incrementFoodUsage(ingredient.food.id!);
    }
  }

  /// Eliminar una receta (y sus ingredientes por CASCADE)
  Future<void> deleteRecipe(int recipeId) async {
    final db = await database;
    await db.delete('recipes', where: 'id = ?', whereArgs: [recipeId]);
  }

  // en storage service

  /// Obtener TODAS las entradas históricas (para sincronización)
  Future<List<FoodEntry>> getAllEntries() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      orderBy: 'timestamp DESC',
    );

    List<FoodEntry> entries = [];
    for (var map in maps) {
      var food = FoodRepository().getFoodById(map['foodId']);

      if ((map['isSupplement'] ?? 0) == 1) {
        food = supplementsList.firstWhere(
          (s) => s.id == map['foodId'],
          orElse: () => FoodRepository().getFoodById(map['foodId'])!,
        );
      } else {
        food = FoodRepository().getFoodById(map['foodId']);
      }

      if (food != null) {
        entries.add(
          FoodEntry(
            id: map['id'],
            food: food,
            grams: map['grams'],
            timestamp: DateTime.parse(map['timestamp']),
            isSupplement: (map['isSupplement'] ?? 0) == 1,
            supplementDose: map['supplementDose'],
          ),
        );
      }
    }

    return entries;
  }

  /// Obtener todos los logs de hábitos
  Future<List<HabitLog>> getAllHabitLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habit_logs');
    return maps.map((map) => HabitLog.fromMap(map)).toList();
  }

  /// Obtener un hábito por ID (helper)
  Future<Habit?> getHabitById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habits',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }
}
