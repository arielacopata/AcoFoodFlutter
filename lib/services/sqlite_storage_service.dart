import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'storage_service.dart';
import '../models/food_entry.dart';
import '../models/user_profile.dart';
import '../models/habit.dart';
import '../models/recipe.dart';
import '../models/dashboard_stats.dart';
import '../models/nutrition_report.dart';
import 'food_repository.dart';
import '../data/supplements_data.dart';
import '../models/food.dart';
import 'nutrition_calculator.dart';

class SQLiteStorageService implements StorageService {
  static Database? _database;

  @override
  Future<void> initialize() async {
    if (_database != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'aco_food.db');

    _database = await openDatabase(
      path,
      version: 16,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initialize();
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

    // Tabla de días de ayuno
    await db.execute('''
  CREATE TABLE fasting_days (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL UNIQUE,
    note TEXT
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

    if (oldVersion < 14) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_foods (
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
        createdAt TEXT NOT NULL
      )
    ''');
    }
    if (oldVersion < 15) {
      // Agregar aminoácidos no esenciales a custom_foods
      await db.execute(
        "ALTER TABLE custom_foods ADD COLUMN alanine REAL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE custom_foods ADD COLUMN arginine REAL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE custom_foods ADD COLUMN asparticAcid REAL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE custom_foods ADD COLUMN glutamicAcid REAL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE custom_foods ADD COLUMN glycine REAL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE custom_foods ADD COLUMN proline REAL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE custom_foods ADD COLUMN serine REAL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE custom_foods ADD COLUMN tyrosine REAL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE custom_foods ADD COLUMN cysteine REAL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE custom_foods ADD COLUMN glutamine REAL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE custom_foods ADD COLUMN asparagine REAL DEFAULT 0",
      );
    }

    if (oldVersion < 16) {
      // Agregar tabla de días de ayuno
      await db.execute('''
    CREATE TABLE IF NOT EXISTS fasting_days (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL UNIQUE,
      note TEXT
    )
  ''');
    }
  }

  @override
  Future<void> clearTodayHistory() async {
    final db = await database;
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
    final db = await database;
    return await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      final db = await database;

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
    final db = await database;
    await db.delete('user_profile', where: 'id = ?', whereArgs: [1]);
    print("Perfil de usuario borrado.");
  }

  Future<FoodEntry> createEntry(FoodEntry entry) async {
    final db = await database;
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
    final db = await database;
    return await db.update(
      'history',
      entry.toMapForUpdate(), // ✅ Sin incluir id
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Método para eliminar un entry
  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
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
  @override
  Future<DashboardStats> getDashboardStats(
    DateTime startDate,
    DateTime endDate, {
    bool includeFastingInAverages = false,
  }) async {
    final db = await database;

    // Obtener todas las entradas del período
    final entries = await db.query(
      'history',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    // Obtener días de ayuno del período
    final fastingDays = await getFastingDays(startDate, endDate);

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

    // Calcular datos diarios - INCLUIR TODOS LOS DÍAS DEL PERÍODO
    List<DailyData> dailyData = [];
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int nonFastingDaysCount = 0; // Contador de días no ayuno

    final foodRepo = FoodRepository();

    // Iterar sobre TODOS los días del período
    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateNormalized = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(endDateNormalized.add(const Duration(days: 1)))) {
      final dateKey = currentDate.toIso8601String().split('T')[0];
      final isFasting = fastingDays.contains(dateKey);

      // Si el día tiene entradas, calcular sus valores
      if (entriesByDay.containsKey(dateKey)) {
        // Construir FoodEntry objects para ese día
        List<FoodEntry> dayEntries = [];

        for (var entry in entriesByDay[dateKey]!) {
          Food? food;

          // Si es suplemento, buscar en supplementsList primero
          if ((entry['isSupplement'] ?? 0) == 1) {
            food = supplementsList.firstWhere(
              (s) => s.id == entry['foodId'],
              orElse: () => foodRepo.getFoodById(entry['foodId'] as int)!,
            );
          } else {
            // Si es alimento normal, buscar en FoodRepository
            food = foodRepo.getFoodById(entry['foodId'] as int);
          }

          if (food == null) continue;

          dayEntries.add(
            FoodEntry(
              food: food,
              grams: entry['grams'] as double,
              timestamp: DateTime.parse(entry['timestamp'] as String),
              isSupplement: (entry['isSupplement'] ?? 0) == 1,
              supplementDose: entry['supplementDose'] as String?,
            ),
          );
        }

        // Usar NutritionCalculator para calcular todos los nutrientes (incluyendo suplementos)
        final calculator = NutritionCalculator();
        final dayReport = await calculator.calculateDailyTotals(dayEntries);

        final dayCalories = dayReport.calories;
        final dayProtein = dayReport.proteins;
        final dayCarbs = dayReport.carbohydrates;
        final dayFat = dayReport.totalFats;

        // Extraer todos los nutrientes del reporte
        final Map<String, double> dayNutrients = {
          'fiber': dayReport.fiber,
          'saturatedFats': dayReport.saturatedFats,
          'omega3': dayReport.omega3,
          'omega6': dayReport.omega6,
          'omega9': dayReport.omega9,
          'calcium': dayReport.calcium,
          'iron': dayReport.iron,
          'magnesium': dayReport.magnesium,
          'phosphorus': dayReport.phosphorus,
          'potassium': dayReport.potassium,
          'sodium': dayReport.sodium,
          'zinc': dayReport.zinc,
          'copper': dayReport.copper,
          'manganese': dayReport.manganese,
          'selenium': dayReport.selenium,
          'vitaminA': dayReport.vitaminA,
          'vitaminC': dayReport.vitaminC,
          'vitaminE': dayReport.vitaminE,
          'vitaminK': dayReport.vitaminK,
          'vitaminB1': dayReport.vitaminB1,
          'vitaminB2': dayReport.vitaminB2,
          'vitaminB3': dayReport.vitaminB3,
          'vitaminB4': dayReport.vitaminB4,
          'vitaminB5': dayReport.vitaminB5,
          'vitaminB6': dayReport.vitaminB6,
          'vitaminB7': dayReport.vitaminB7,
          'vitaminB9': dayReport.vitaminB9,
          'vitaminB12': dayReport.vitaminB12,
          'vitaminD': dayReport.vitaminD,
          'iodine': dayReport.iodine,
          'molybdenum': dayReport.molybdenum,
          'chromium': dayReport.chromium,
          'fluorine': dayReport.fluorine,
          'histidine': dayReport.histidine,
          'isoleucine': dayReport.isoleucine,
          'leucine': dayReport.leucine,
          'lysine': dayReport.lysine,
          'methionine': dayReport.methionine,
          'phenylalanine': dayReport.phenylalanine,
          'threonine': dayReport.threonine,
          'tryptophan': dayReport.tryptophan,
          'valine': dayReport.valine,
          'alanine': dayReport.alanine,
          'arginine': dayReport.arginine,
          'asparticAcid': dayReport.asparticAcid,
          'glutamicAcid': dayReport.glutamicAcid,
          'glycine': dayReport.glycine,
          'proline': dayReport.proline,
          'serine': dayReport.serine,
          'tyrosine': dayReport.tyrosine,
          'cysteine': dayReport.cysteine,
          'glutamine': dayReport.glutamine,
          'asparagine': dayReport.asparagine,
        };

        // Incluir en promedios según configuración
        if (includeFastingInAverages || !isFasting) {
          totalCalories += dayCalories;
          totalProtein += dayProtein;
          totalCarbs += dayCarbs;
          totalFat += dayFat;
          nonFastingDaysCount++;
        }

        dailyData.add(
          DailyData(
            date: currentDate,
            calories: dayCalories,
            protein: dayProtein,
            carbs: dayCarbs,
            fat: dayFat,
            nutrients: dayNutrients,
            isFasting: isFasting,
          ),
        );
      } else {
        // Día sin entradas - crear entrada vacía
        dailyData.add(
          DailyData(
            date: currentDate,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            nutrients: const {},
            isFasting: isFasting,
          ),
        );

        // Contar días según configuración
        if (includeFastingInAverages || !isFasting) {
          nonFastingDaysCount++;
        }
      }

      // Avanzar al siguiente día
      currentDate = currentDate.add(const Duration(days: 1));
    }

    final daysCount = nonFastingDaysCount > 0 ? nonFastingDaysCount : 1;

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
      ..sort((a, b) => b.timesConsumed.compareTo(a.timesConsumed));
    final topFoodsList = topFoods.toList();

    final topFoodsByWeight = foodStats.values.toList()
      ..sort((a, b) => b.totalGrams.compareTo(a.totalGrams));
    final topFoodsByWeightList = topFoodsByWeight.toList();

    // Completitud de hábitos

    final habits = await db.query('habits');
    Map<String, int> habitCompletion = {};

    for (var habit in habits) {
      final habitId = habit['id'] as int;
      final habitName = habit['name'] as String;
      // Formatear fechas como YYYY-MM-DD
      final startDateStr = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).toIso8601String().split('T')[0];

      final endDateStr = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).toIso8601String().split('T')[0];

      final logs = await db.query(
        'habit_logs',
        where: 'habitId = ? AND date >= ? AND date <= ?',
        whereArgs: [habitId, startDateStr, endDateStr],
      );

      for (var log in logs) {}

      // Contar días únicos (ahora usando directamente el campo 'date')
      final uniqueDays = logs
          .map((log) => log['date'] as String)
          .toSet()
          .length;

      habitCompletion[habitName] = uniqueDays;
    }

    // Ordenar dailyData cronológicamente
    dailyData.sort((a, b) => a.date.compareTo(b.date));

    return DashboardStats(
      startDate: startDate,
      endDate: endDate,
      avgCalories: totalCalories / daysCount,
      avgProtein: totalProtein / daysCount,
      avgCarbs: totalCarbs / daysCount,
      avgFat: totalFat / daysCount,
      dailyData: dailyData,
      topFoods: topFoodsList,
      topFoodsByWeight: topFoodsByWeightList,
      habitCompletion: habitCompletion,
    );
  }

  @override
  Future<void> initializeDefaultHabits() async {
    // SQLite ya tiene los hábitos en la BD inicial, no hacer nada
  }

  @override
  Future<int> insertCustomFood(Food food) async {
    final db = await database;

    final map = {
      'emoji': food.emoji,
      'name': food.name,
      'fullName': food.fullName,
      'calories': food.calories,
      'proteins': food.proteins,
      'carbohydrates': food.carbohydrates,
      'fiber': food.fiber,
      'totalSugars': food.totalSugars,
      'totalFats': food.totalFats,
      'saturatedFats': food.saturatedFats,
      'omega3': food.omega3,
      'omega6': food.omega6,
      'omega9': food.omega9,
      'calcium': food.calcium,
      'iron': food.iron,
      'magnesium': food.magnesium,
      'phosphorus': food.phosphorus,
      'potassium': food.potassium,
      'sodium': food.sodium,
      'zinc': food.zinc,
      'copper': food.copper,
      'manganese': food.manganese,
      'selenium': food.selenium,
      'iodine': food.iodine,
      'molybdenum': food.molybdenum,
      'chromium': food.chromium,
      'fluorine': food.fluorine,
      'vitaminA': food.vitaminA,
      'vitaminC': food.vitaminC,
      'vitaminD': food.vitaminD,
      'vitaminE': food.vitaminE,
      'vitaminK': food.vitaminK,
      'vitaminB1': food.vitaminB1,
      'vitaminB2': food.vitaminB2,
      'vitaminB3': food.vitaminB3,
      'vitaminB4': food.vitaminB4,
      'vitaminB5': food.vitaminB5,
      'vitaminB6': food.vitaminB6,
      'vitaminB7': food.vitaminB7,
      'vitaminB9': food.vitaminB9,
      'vitaminB12': food.vitaminB12,
      // Aminoácidos esenciales
      'histidine': food.histidine,
      'isoleucine': food.isoleucine,
      'leucine': food.leucine,
      'lysine': food.lysine,
      'methionine': food.methionine,
      'phenylalanine': food.phenylalanine,
      'threonine': food.threonine,
      'tryptophan': food.tryptophan,
      'valine': food.valine,
      // Aminoácidos no esenciales (AGREGAR ESTOS)
      'alanine': food.alanine,
      'arginine': food.arginine,
      'asparticAcid': food.asparticAcid,
      'glutamicAcid': food.glutamicAcid,
      'glycine': food.glycine,
      'proline': food.proline,
      'serine': food.serine,
      'tyrosine': food.tyrosine,
      'cysteine': food.cysteine,
      'glutamine': food.glutamine,
      'asparagine': food.asparagine,
      'createdAt': DateTime.now().toIso8601String(),
    };

    return await db.insert('custom_foods', map);
  }

  @override
  Future<List<Food>> getCustomFoods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'custom_foods',
      orderBy: 'name ASC',
    );

    return maps
        .map(
          (map) => Food(
            id: map['id'] as int,
            emoji: map['emoji'] as String,
            name: map['name'] as String,
            fullName: map['fullName'] as String?,
            calories: (map['calories'] as num).toDouble(),
            proteins: (map['proteins'] as num).toDouble(),
            carbohydrates: (map['carbohydrates'] as num).toDouble(),
            fiber: (map['fiber'] as num).toDouble(),
            totalSugars: (map['totalSugars'] as num).toDouble(),
            totalFats: (map['totalFats'] as num).toDouble(),
            saturatedFats: (map['saturatedFats'] as num).toDouble(),
            omega3: (map['omega3'] as num).toDouble(),
            omega6: (map['omega6'] as num).toDouble(),
            omega9: (map['omega9'] as num).toDouble(),
            calcium: (map['calcium'] as num).toDouble(),
            iron: (map['iron'] as num).toDouble(),
            magnesium: (map['magnesium'] as num).toDouble(),
            phosphorus: (map['phosphorus'] as num).toDouble(),
            potassium: (map['potassium'] as num).toDouble(),
            sodium: (map['sodium'] as num).toDouble(),
            zinc: (map['zinc'] as num).toDouble(),
            copper: (map['copper'] as num).toDouble(),
            manganese: (map['manganese'] as num).toDouble(),
            selenium: (map['selenium'] as num).toDouble(),
            iodine: (map['iodine'] as num).toDouble(),
            molybdenum: (map['molybdenum'] as num).toDouble(),
            chromium: (map['chromium'] as num).toDouble(),
            fluorine: (map['fluorine'] as num).toDouble(),
            vitaminA: (map['vitaminA'] as num).toDouble(),
            vitaminC: (map['vitaminC'] as num).toDouble(),
            vitaminD: (map['vitaminD'] as num).toDouble(),
            vitaminE: (map['vitaminE'] as num).toDouble(),
            vitaminK: (map['vitaminK'] as num).toDouble(),
            vitaminB1: (map['vitaminB1'] as num).toDouble(),
            vitaminB2: (map['vitaminB2'] as num).toDouble(),
            vitaminB3: (map['vitaminB3'] as num).toDouble(),
            vitaminB4: (map['vitaminB4'] as num).toDouble(),
            vitaminB5: (map['vitaminB5'] as num).toDouble(),
            vitaminB6: (map['vitaminB6'] as num).toDouble(),
            vitaminB7: (map['vitaminB7'] as num).toDouble(),
            vitaminB9: (map['vitaminB9'] as num).toDouble(),
            vitaminB12: (map['vitaminB12'] as num).toDouble(),
            histidine: (map['histidine'] as num).toDouble(),
            isoleucine: (map['isoleucine'] as num).toDouble(),
            leucine: (map['leucine'] as num).toDouble(),
            lysine: (map['lysine'] as num).toDouble(),
            methionine: (map['methionine'] as num).toDouble(),
            phenylalanine: (map['phenylalanine'] as num).toDouble(),
            threonine: (map['threonine'] as num).toDouble(),
            tryptophan: (map['tryptophan'] as num).toDouble(),
            valine: (map['valine'] as num).toDouble(),
          ),
        )
        .toList();
  }

  @override
  Future<void> deleteAllCustomFoods() async {
    final db = await database;
    // Borrar todos menos el ID 9999 (reservado)
    await db.delete('custom_foods', where: 'id != ?', whereArgs: [9999]);
  }

  Future<bool> hasCustomFoods() async {
    final db = await database;
    final result = await db.query(
      'custom_foods',
      where: 'id >= ?',
      whereArgs: [10000],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ============ MÉTODOS DE AYUNO ============

  @override
  Future<void> markFastingDay(DateTime date, {String? note}) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];

    await db.insert(
      'fasting_days',
      {'date': dateStr, 'note': note},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> unmarkFastingDay(DateTime date) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];

    await db.delete(
      'fasting_days',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
  }

  @override
  Future<bool> isFastingDay(DateTime date) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];

    final result = await db.query(
      'fasting_days',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  @override
  Future<Set<String>> getFastingDays(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final startStr = DateTime(startDate.year, startDate.month, startDate.day)
        .toIso8601String()
        .split('T')[0];
    final endStr = DateTime(endDate.year, endDate.month, endDate.day)
        .toIso8601String()
        .split('T')[0];

    final result = await db.query(
      'fasting_days',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
    );

    return result.map((row) => row['date'] as String).toSet();
  }
}
