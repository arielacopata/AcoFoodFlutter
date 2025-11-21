import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'storage_service.dart';
import '../models/food_entry.dart';
import '../models/user_profile.dart';
import '../models/habit.dart';
import '../models/user_preferences.dart';
import '../models/recipe.dart';
import '../models/dashboard_stats.dart';
import 'food_repository.dart';
import '../data/supplements_data.dart';
import '../models/food.dart';
import 'nutrition_calculator.dart';

class FirestoreStorageService implements StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _userCollection {
    if (_userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(_userId).collection('data');
  }

  @override
  Future<void> initialize() async {
    // Firebase ya está inicializado en main.dart
    // Aquí solo verificamos que el usuario esté autenticado
    if (_userId == null) {
      throw Exception('User must be authenticated to use Firestore storage');
    }
  }

  @override
  Future<void> close() async {
    // Firestore no necesita cerrarse
  }

  // TODO: Implementar todos los métodos de StorageService
  // Por ahora dejamos stubs que tiran error

  @override
  Future<FoodEntry> createEntry(FoodEntry entry) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('entries')
          .collection('history')
          .add({
            'foodId': entry.food.id,
            'grams': entry.grams,
            'timestamp': entry.timestamp.toIso8601String(),
            'isSupplement': entry.isSupplement ? 1 : 0,
            'supplementDose': entry.supplementDose,
          });

      return FoodEntry(
        firestoreDocId: docRef.id, // 👈 Usar firestoreDocId
        food: entry.food,
        grams: entry.grams,
        timestamp: entry.timestamp,
        isSupplement: entry.isSupplement,
        supplementDose: entry.supplementDose,
      );
    } catch (e) {
      print('Error creating entry: $e');
      rethrow;
    }
  }

  @override
  Future<Map<int, int>> getFoodUsageCounts() async {
    // Por ahora retornar vacío, lo implementamos después si lo necesitás
    return {};
  }

  @override
  Future<int> updateEntry(FoodEntry entry) async {
    try {
      if (entry.firestoreDocId == null) {
        print('Error: No firestoreDocId to update');
        return 0;
      }

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('entries')
          .collection('history')
          .doc(entry.firestoreDocId)
          .update({
            'grams': entry.grams,
            'timestamp': entry.timestamp.toIso8601String(),
          });

      return 1;
    } catch (e) {
      print('Error updating entry: $e');
      return 0;
    }
  }

  @override
  Future<int> deleteEntry(int id) async {
    // Este método recibe el objeto completo en realidad
    // Necesitamos cambiar la firma o buscar de otra forma
    throw UnimplementedError('Use deleteEntryByDocId instead');
  }

  // Agregar método nuevo
  Future<int> deleteEntryByDocId(String docId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('entries')
          .collection('history')
          .doc(docId)
          .delete();
      return 1;
    } catch (e) {
      print('Error deleting entry: $e');
      return 0;
    }
  }

  @override
  Future<void> clearTodayHistory() async {
    try {
      final today = DateTime.now();
      final entries = await getEntriesByDate(today);

      for (var entry in entries) {
        if (entry.firestoreDocId != null) {
          await deleteEntryByDocId(entry.firestoreDocId!);
        }
      }
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  @override
  Future<int> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('profile')
          .set(profile.toMap());

      return 1;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      print('🔍 Buscando perfil para userId: $_userId');

      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('profile')
          .get();

      print('📄 Documento existe: ${doc.exists}');

      if (doc.exists) {
        print('📊 Datos del documento: ${doc.data()}');
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  @override
  Future<void> deleteUserProfile() async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('profile')
          .delete();
    } catch (e) {
      print('Error deleting profile: $e');
    }
  }

  @override
  Future<void> updateExpenditureForToday(int calories) async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('profile')
          .update({'expenditure_$dateStr': calories});
    } catch (e) {
      print('Error updating expenditure: $e');
    }
  }

  @override
  Future<void> incrementFoodUsage(int foodId) async {
    // Por ahora no implementamos contadores de uso en web
    // Se puede implementar después si es necesario
    return;
  }

  @override
  Future<void> initializeDefaultHabits() async {
    try {
      final existing = await getAllHabits();
      if (existing.isNotEmpty) return;

      final defaultHabits = [
        {
          'name': 'Meditar',
          'type': 'predefined',
          'emoji': '🧘',
          'enabled': true,
          'options': ['5 min', '10 min', '15 min', '20 min'],
        },
        {
          'name': 'Respirar',
          'type': 'predefined',
          'emoji': '🫁',
          'enabled': true,
          'options': ['4-7-8', 'Cuadrada', 'Profunda', 'Wim Hof'],
        },
        {
          'name': 'Ducha fría',
          'type': 'predefined',
          'emoji': '🚿',
          'enabled': true,
          'options': ['30 seg', '1 min', '2 min', '5 min'],
        },
        {
          'name': 'Agradecer',
          'type': 'predefined',
          'emoji': '🙏',
          'enabled': true,
          'options': ['Lista de 3', 'Journaling', 'Meditación', 'A alguien'],
        },
        {
          'name': 'Ejercicio',
          'type': 'predefined',
          'emoji': '🏃',
          'enabled': true,
          'options': [
            'HIIT',
            'Correr',
            'Gimnasio',
            'Caminar',
            'Bicicleta',
            'General',
          ],
        },
      ];

      for (var habit in defaultHabits) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('data')
            .doc('habits')
            .collection('items')
            .add(habit);
      }
    } catch (e) {
      print('Error initializing default habits: $e');
    }
  }

  @override
  Future<void> logHabit(int habitId, String? detail, {DateTime? date}) async {
    try {
      final logDate = date ?? DateTime.now();

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('habits')
          .collection('logs')
          .add({
            'habitId': habitId,
            'detail': detail ?? '',
            'timestamp': FieldValue.serverTimestamp(),
            'date': DateTime(
              logDate.year,
              logDate.month,
              logDate.day,
            ).toIso8601String().split('T')[0],
          });
    } catch (e) {
      print('❌ Error logging habit: $e');
      rethrow;
    }
  }

  /// Obtener todos los logs de hábitos
  Future<List<HabitLog>> getAllHabitLogs() async {
    try {
      print('🔍 Buscando logs en: users/$_userId/data/habits/logs');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('habits') // 👈 CAMBIAR ACÁ
          .collection('logs')
          .get();

      print('📊 Documentos encontrados: ${snapshot.docs.length}');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HabitLog(
          id: doc.id.hashCode,
          habitId: data['habitId'] as int,
          date: DateTime.parse(data['date']),
          detail: data['detail'],
          timestamp: data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.parse(data['date']),
        );
      }).toList();
    } catch (e) {
      print('❌ Error getting habit logs: $e');
      return [];
    }
  }

  @override
  Future<List<HabitLog>> getHabitLogsByDate(int habitId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('habits')
          .collection('logs')
          .where('habitId', isEqualTo: habitId)
          .where('date', isEqualTo: dateStr)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return HabitLog(
          id: doc.id.hashCode,
          habitId: habitId,
          date: DateTime.parse(data['date']),
          timestamp: data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.parse(data['date']),
          detail: data['detail'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error getting habit logs: $e');
      return [];
    }
  }

  @override
  Future<int> calculateStreak(int habitId) async {
    try {
      int streak = 0;
      DateTime currentDate = DateTime.now();

      // Verificar días consecutivos hacia atrás
      while (true) {
        final logs = await getHabitLogsByDate(habitId, currentDate);

        if (logs.isEmpty) {
          break;
        }

        streak++;
        currentDate = currentDate.subtract(Duration(days: 1));

        // Límite de seguridad
        if (streak > 365) break;
      }

      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  @override
  Future<List<Habit>> getAllHabits() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('habits')
          .collection('items')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Habit(
          id: doc.id.hashCode,
          name: data['name'],
          type: data['type'] ?? 'text',
          emoji: data['emoji'] ?? '✓',
          options: data['options'] != null
              ? List<String>.from(data['options'])
              : null,
          enabled: data['enabled'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('Error getting habits: $e');
      return [];
    }
  }

  @override
  Future<List<Habit>> getEnabledHabits() async {
    try {
      final allHabits = await getAllHabits();
      return allHabits.where((h) => h.enabled).toList();
    } catch (e) {
      print('Error getting enabled habits: $e');
      return [];
    }
  }

  @override
  Future<void> updateHabitEnabled(int habitId, bool enabled) async {
    try {
      final habits = await getAllHabits();
      final habit = habits.firstWhere((h) => h.id == habitId);

      // Buscar el documento por nombre (ya que no guardamos el docId)
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('habits')
          .collection('items')
          .where('name', isEqualTo: habit.name)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({'enabled': enabled});
      }
    } catch (e) {
      print('Error updating habit: $e');
    }
  }

  Future<void> savePreferences(UserPreferences prefs) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('data')
        .doc('preferences')
        .set(prefs.toMap());
  }

  Future<UserPreferences?> getPreferences() async {
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('data')
        .doc('preferences')
        .get();

    if (!doc.exists) return null;
    return UserPreferences.fromMap(doc.data()!);
  }

  @override
  Future<int> saveRecipe(
    Recipe recipe,
    List<RecipeIngredient> ingredients,
  ) async {
    try {
      // Crear la receta
      final recipeDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('recipes')
          .collection('items')
          .add({
            'name': recipe.name,
            'emoji': recipe.emoji,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Guardar ingredientes en batch
      final batch = _firestore.batch();
      for (var ingredient in ingredients) {
        final ingredientRef = recipeDoc.collection('ingredients').doc();
        batch.set(ingredientRef, {
          'foodId': ingredient.food.id,
          'grams': ingredient.grams,
        });
      }
      await batch.commit();

      return recipeDoc.id.hashCode;
    } catch (e) {
      print('Error saving recipe: $e');
      return 0;
    }
  }

  @override
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('recipes')
          .collection('items')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Recipe(
          id: doc.id.hashCode,
          firestoreDocId: doc.id,
          name: doc.data()['name'],
          emoji: doc.data()['emoji'],
          createdAt: DateTime.now(), // 👈 Asignar fecha actual al bajar
        );
      }).toList();
    } catch (e) {
      print('Error getting recipes: $e');
      return [];
    }
  }

  @override
  Future<List<RecipeIngredient>> getRecipeIngredients(int recipeId) async {
    try {
      // Buscar la receta por ID para obtener el firestoreDocId
      final recipes = await getAllRecipes();
      final recipe = recipes.firstWhere(
        (r) => r.id == recipeId,
        orElse: () => throw Exception('Recipe not found'),
      );

      if (recipe.firestoreDocId == null) {
        return [];
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('recipes')
          .collection('items')
          .doc(recipe.firestoreDocId)
          .collection('ingredients')
          .get();

      List<RecipeIngredient> ingredients = [];
      for (var doc in snapshot.docs) {
        final foodId = doc.data()['foodId'] as int;
        final food = FoodRepository().getFoodById(foodId);

        if (food != null) {
          ingredients.add(
            RecipeIngredient(
              recipeId: recipeId,
              food: food,
              grams: (doc.data()['grams'] as num).toDouble(),
            ),
          );
        }
      }

      return ingredients;
    } catch (e) {
      print('Error getting recipe ingredients: $e');
      return [];
    }
  }

  /// Subir múltiples recetas en batch (con ingredientes)
  Future<void> createRecipesBatch(
    Map<Recipe, List<RecipeIngredient>> recipesWithIngredients,
  ) async {
    if (recipesWithIngredients.isEmpty) return;

    for (final entry in recipesWithIngredients.entries) {
      final recipe = entry.key;
      final ingredients = entry.value;

      // Crear documento de receta
      final recipeRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('recipes')
          .collection('items')
          .doc();

      await recipeRef.set({
        'name': recipe.name,
        'emoji': recipe.emoji,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Subir ingredientes
      if (ingredients.isNotEmpty) {
        final batch = _firestore.batch();

        for (final ingredient in ingredients) {
          final ingredientRef = recipeRef.collection('ingredients').doc();
          batch.set(ingredientRef, {
            'foodId': ingredient.food.id,
            'grams': ingredient.grams,
          });
        }

        await batch.commit();
      }
    }

    print(
      '   ✅ ${recipesWithIngredients.length} recetas con ingredientes subidas',
    );
  }

  /// Subir múltiples entradas en batch (máximo 500 por lote)
  Future<void> createEntriesBatch(List<FoodEntry> entries) async {
    const batchSize = 500; // Límite de Firestore

    for (int i = 0; i < entries.length; i += batchSize) {
      final end = (i + batchSize < entries.length)
          ? i + batchSize
          : entries.length;
      final batchEntries = entries.sublist(i, end);

      final batch = _firestore.batch();

      for (final entry in batchEntries) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('data')
            .doc('entries')
            .collection('history')
            .doc(); // Auto-genera ID

        batch.set(docRef, {
          'foodId': entry.food.id,
          'grams': entry.grams,
          'timestamp': entry.timestamp.toIso8601String(),
          'isSupplement': entry.isSupplement ? 1 : 0,  // ← Convertir a int como en createEntry
          'supplementDose': entry.supplementDose,
        });
      }

      await batch.commit();
      print(
        '   ✅ Lote ${(i ~/ batchSize) + 1} completado (${batchEntries.length} entradas)',
      );
    }
  }

  /// Limpiar todos los datos del usuario en Firestore
  /// Limpiar todos los datos del usuario en Firestore (con batch)
  Future<void> clearAllData() async {
    try {
      final userDataRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('data');

      // Borrar entradas en batch
      final entriesSnapshot = await userDataRef
          .doc('entries')
          .collection('history')
          .get();

      if (entriesSnapshot.docs.isNotEmpty) {
        await _deleteBatch(entriesSnapshot.docs);
        print('   🗑️ Entradas borradas: ${entriesSnapshot.docs.length}');
      }

      // Borrar logs de hábitos en batch
      final logsSnapshot = await userDataRef
          .doc('habits')
          .collection('logs')
          .get();

      if (logsSnapshot.docs.isNotEmpty) {
        await _deleteBatch(logsSnapshot.docs);
        print('   🗑️ Logs borrados: ${logsSnapshot.docs.length}');
      }

      // Borrar recetas (incluyendo ingredientes)
      final recipesSnapshot = await userDataRef
          .doc('recipes')
          .collection('items')
          .get();

      if (recipesSnapshot.docs.isNotEmpty) {
        // Primero borrar ingredientes de cada receta
        for (final recipeDoc in recipesSnapshot.docs) {
          final ingredientsSnapshot = await recipeDoc.reference
              .collection('ingredients')
              .get();

          if (ingredientsSnapshot.docs.isNotEmpty) {
            await _deleteBatch(ingredientsSnapshot.docs);
          }
        }

        // Luego borrar las recetas
        await _deleteBatch(recipesSnapshot.docs);
        print('   🗑️ Recetas borradas: ${recipesSnapshot.docs.length}');
      }
    } catch (e) {
      print('❌ Error limpiando Firestore: $e');
      rethrow;
    }
  }

  /// Borrar documentos en lotes de 500 (límite de Firestore)
  Future<void> _deleteBatch(List<QueryDocumentSnapshot> docs) async {
    const batchSize = 500;

    for (int i = 0; i < docs.length; i += batchSize) {
      final end = (i + batchSize < docs.length) ? i + batchSize : docs.length;
      final batchDocs = docs.sublist(i, end);

      final batch = _firestore.batch();
      for (final doc in batchDocs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }

  /// Subir múltiples logs de hábitos en batch
  Future<void> createHabitLogsBatch(List<HabitLog> logs) async {
    const batchSize = 500;

    for (int i = 0; i < logs.length; i += batchSize) {
      final end = (i + batchSize < logs.length) ? i + batchSize : logs.length;
      final batchLogs = logs.sublist(i, end);

      final batch = _firestore.batch();

      for (final log in batchLogs) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('data')
            .doc('habits')
            .collection('logs')
            .doc(); // Auto-genera ID

        final logDate = log.date;
        batch.set(docRef, {
          'habitId': log.habitId,
          'detail': log.detail ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'date': DateTime(
            logDate.year,
            logDate.month,
            logDate.day,
          ).toIso8601String().split('T')[0],
        });
      }

      await batch.commit();
      print(
        '   ✅ Lote ${(i ~/ batchSize) + 1} completado (${batchLogs.length} logs)',
      );
    }
  }

  @override
  Future<void> registerRecipeIngredients(int recipeId) async {
    try {
      final ingredients = await getRecipeIngredients(recipeId);
      for (var ingredient in ingredients) {
        await incrementFoodUsage(ingredient.food.id!);
      }
    } catch (e) {
      print('Error registering recipe ingredients: $e');
    }
  }

  @override
  Future<void> deleteRecipe(int recipeId) async {
    try {
      final recipes = await getAllRecipes();
      final recipe = recipes.firstWhere(
        (r) => r.id == recipeId,
        orElse: () => throw Exception('Recipe not found'),
      );

      if (recipe.firestoreDocId == null) {
        return;
      }

      final recipeRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('recipes')
          .collection('items')
          .doc(recipe.firestoreDocId);

      // Eliminar ingredientes
      final ingredientsSnapshot = await recipeRef
          .collection('ingredients')
          .get();
      final batch = _firestore.batch();

      for (var doc in ingredientsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Eliminar la receta
      batch.delete(recipeRef);

      await batch.commit();
    } catch (e) {
      print('Error deleting recipe: $e');
    }
  }

  @override
  Future<DashboardStats> getDashboardStats(
    DateTime startDate,
    DateTime endDate, {
    bool includeFastingInAverages = false,
  }) async {
    try {
      // Obtener todas las entradas en el rango de fechas
      List<FoodEntry> allEntries = [];
      DateTime currentDate = startDate;

      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        final entries = await getEntriesByDate(currentDate);
        allEntries.addAll(entries);
        currentDate = currentDate.add(Duration(days: 1));
      }

      // Agrupar entradas por día
      Map<String, List<FoodEntry>> entriesByDay = {};
      for (var entry in allEntries) {
        final dateKey = DateTime(
          entry.timestamp.year,
          entry.timestamp.month,
          entry.timestamp.day,
        ).toIso8601String().split('T')[0];
        entriesByDay.putIfAbsent(dateKey, () => []).add(entry);
      }

      // Calcular datos diarios usando NutritionCalculator
      List<DailyData> dailyData = [];
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      final calculator = NutritionCalculator();

      for (var dateKey in entriesByDay.keys) {
        // Usar NutritionCalculator para calcular todos los nutrientes (incluyendo suplementos)
        final dayReport = await calculator.calculateDailyTotals(
          entriesByDay[dateKey]!,
        );

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

        dailyData.add(DailyData(
          date: DateTime.parse(dateKey),
          calories: dayCalories,
          protein: dayProtein,
          carbs: dayCarbs,
          fat: dayFat,
          nutrients: dayNutrients,
        ));

        totalCalories += dayCalories;
        totalProtein += dayProtein;
        totalCarbs += dayCarbs;
        totalFat += dayFat;
      }

      // Calcular promedios
      final numDays = dailyData.isNotEmpty ? dailyData.length : 1;
      final avgCalories = totalCalories / numDays;
      final avgProtein = totalProtein / numDays;
      final avgCarbs = totalCarbs / numDays;
      final avgFat = totalFat / numDays;

      // Top foods (más usados)
      Map<int, int> foodCounts = {};
      Map<int, double> foodGrams = {};

      // Llenar los mapas con datos de las entradas
      for (var entry in allEntries) {
        final foodId = entry.food.id;
        if (foodId != null) {
          foodCounts[foodId] = (foodCounts[foodId] ?? 0) + 1;
          foodGrams[foodId] = (foodGrams[foodId] ?? 0) + entry.grams;
        }
      }

      List<TopFood> topFoods =
          foodCounts.entries
              .map((e) {
                final food = FoodRepository().getFoodById(e.key);
                if (food == null) return null;

                return TopFood(
                  name: food.name,
                  fullName: food.fullName ?? food.name,
                  emoji: food.emoji,
                  timesConsumed: e.value,
                  totalGrams: foodGrams[e.key] ?? 0,
                );
              })
              .whereType<TopFood>()
              .toList()
            ..sort((a, b) => b.timesConsumed.compareTo(a.timesConsumed));

      // Top foods por peso (usar la misma lista antes del take)
      final allTopFoods = List<TopFood>.from(topFoods);
      final topFoodsByWeight = allTopFoods
        ..sort((a, b) => b.totalGrams.compareTo(a.totalGrams));
      final topFoodsByWeightList = topFoodsByWeight.toList();

      topFoods = topFoods.toList();

      // Hábitos (por ahora vacío)
      Map<String, int> habitCompletion = {};

      // Ordenar dailyData cronológicamente
      dailyData.sort((a, b) => a.date.compareTo(b.date));

      return DashboardStats(
        startDate: startDate,
        endDate: endDate,
        avgCalories: avgCalories,
        avgProtein: avgProtein,
        avgCarbs: avgCarbs,
        avgFat: avgFat,
        dailyData: dailyData,
        topFoods: topFoods,
        topFoodsByWeight: topFoodsByWeightList,
        habitCompletion: habitCompletion,
      );
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return DashboardStats(
        startDate: startDate,
        endDate: endDate,
        avgCalories: 0,
        avgProtein: 0,
        avgCarbs: 0,
        avgFat: 0,
        dailyData: [],
        topFoods: [],
        topFoodsByWeight: [],
        habitCompletion: {},
      );
    }
  }

  @override
  Future<int> insertCustomFood(Food food) async {
    // TODO: Implementar cuando sea necesario para web
    throw UnimplementedError('Custom foods not yet implemented for Firestore');
  }

  @override
  Future<List<Food>> getCustomFoods() async {
    // TODO: Implementar cuando sea necesario para web
    return [];
  }

  @override
  Future<bool> hasCustomFoods() async {
    // TODO: Implementar cuando sea necesario para web
    return false;
  }

  @override
  Future<void> deleteAllCustomFoods() async {
    throw UnimplementedError('Custom foods not yet implemented for Firestore');
  }

  @override
  Future<List<FoodEntry>> getEntriesByDate(DateTime date) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('entries')
          .collection('history')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
          )
          .where('timestamp', isLessThan: endOfDay.toIso8601String())
          .orderBy('timestamp', descending: true)
          .get();

      List<FoodEntry> entries = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final foodId = data['foodId'] as int;
        // Aceptar tanto int (1/0) como boolean (true/false)
        final isSuppField = data['isSupplement'];
        final isSupp = isSuppField is bool ? isSuppField : (isSuppField == 1);

        Food? food;
        if (isSupp) {
          food = supplementsList.firstWhere(
            (s) => s.id == foodId,
            orElse: () => FoodRepository().getFoodById(foodId)!,
          );
        } else {
          food = FoodRepository().getFoodById(foodId);
        }

        if (food != null) {
          entries.add(
            FoodEntry(
              firestoreDocId: doc.id,
              food: food,
              grams: (data['grams'] as num).toDouble(),
              timestamp: DateTime.parse(data['timestamp']),
              isSupplement: isSupp,
              supplementDose: data['supplementDose'],
            ),
          );
        }
      }

      return entries;
    } catch (e) {
      print('Error getting entries: $e');
      return [];
    }
  }

  /// Obtener TODAS las entradas (para sincronización)
  Future<List<FoodEntry>> getAllEntries() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('data')
          .doc('entries')
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      List<FoodEntry> entries = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final foodId = data['foodId'] as int;
        // Aceptar tanto int (1/0) como boolean (true/false)
        final isSuppField = data['isSupplement'];
        final isSupp = isSuppField is bool ? isSuppField : (isSuppField == 1);

        Food? food;
        if (isSupp) {
          food = supplementsList.firstWhere(
            (s) => s.id == foodId,
            orElse: () => FoodRepository().getFoodById(foodId)!,
          );
        } else {
          food = FoodRepository().getFoodById(foodId);
        }

        if (food != null) {
          entries.add(
            FoodEntry(
              firestoreDocId: doc.id,
              food: food,
              grams: (data['grams'] as num).toDouble(),
              timestamp: DateTime.parse(data['timestamp']),
              isSupplement: isSupp,
              supplementDose: data['supplementDose'],
            ),
          );
        }
      }

      return entries;
    } catch (e) {
      print('Error getting all entries: $e');
      return [];
    }
  }

  // ============ MÉTODOS DE AYUNO ============

  @override
  Future<void> markFastingDay(DateTime date, {String? note}) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('fasting_days')
        .doc(dateStr)
        .set({
      'date': dateStr,
      'note': note,
    });
  }

  @override
  Future<void> unmarkFastingDay(DateTime date) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('fasting_days')
        .doc(dateStr)
        .delete();
  }

  @override
  Future<bool> isFastingDay(DateTime date) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];

    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('fasting_days')
        .doc(dateStr)
        .get();

    return doc.exists;
  }

  @override
  Future<Set<String>> getFastingDays(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final startStr = DateTime(startDate.year, startDate.month, startDate.day)
        .toIso8601String()
        .split('T')[0];
    final endStr = DateTime(endDate.year, endDate.month, endDate.day)
        .toIso8601String()
        .split('T')[0];

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('fasting_days')
        .where('date', isGreaterThanOrEqualTo: startStr)
        .where('date', isLessThanOrEqualTo: endStr)
        .get();

    return snapshot.docs.map((doc) => doc.data()['date'] as String).toSet();
  }
}
