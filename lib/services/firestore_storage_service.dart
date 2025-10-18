import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'storage_service.dart';
import '../models/food_entry.dart';
import '../models/user_profile.dart';
import '../models/habit.dart';
import '../models/recipe.dart';
import '../models/dashboard_stats.dart';
import 'food_repository.dart';
import '../data/supplements_data.dart';
import '../models/food.dart';

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
  Future<List<FoodEntry>> getEntriesByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
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

        Food? food;
        if ((data['isSupplement'] ?? 0) == 1) {
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
              isSupplement: (data['isSupplement'] ?? 0) == 1,
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
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('data')
        .doc('profile')
        .update({
      'expenditure_$dateStr': calories,
    });
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
  Future<void> logHabit(int habitId, String detail) async {
 // TODO: Implementar hábitos en Firestore
  }

  @override
  Future<List<HabitLog>> getHabitLogsByDate(int habitId, DateTime date) async {
  return [];
  }

  @override
  Future<int> calculateStreak(int habitId) async {
  return 0;
  }

  @override
  Future<List<Habit>> getAllHabits() async {
  return [];
  }

  @override
  Future<List<Habit>> getEnabledHabits() async  {
  return [];
  }

  @override
  Future<void> updateHabitEnabled(int habitId, bool enabled) async {
  // TODO: Implementar
  }

  @override
  Future<int> saveRecipe(Recipe recipe, List<RecipeIngredient> ingredients) async {
  return 0; // TODO: Implementar recetas
  }

  @override
  Future<List<Recipe>> getAllRecipes() async {
  return [];
  }

  @override
  Future<List<RecipeIngredient>> getRecipeIngredients(int recipeId) async {
  return [];
  }

  @override
  Future<void> registerRecipeIngredients(int recipeId) async {
  // TODO: Implementar
  }

  @override
  Future<void> deleteRecipe(int recipeId) async {
  // TODO: Implementar
  }

@override
Future<DashboardStats> getDashboardStats(DateTime startDate, DateTime endDate) async {
  // Retornar stats vacíos por ahora
  return DashboardStats(
    startDate: startDate,
    endDate: endDate,
    avgCalories: 0,
    avgProtein: 0,
    avgCarbs: 0,
    avgFat: 0,
    dailyData: [],
    topFoods: [],
    habitCompletion: {},
  );
}
}
