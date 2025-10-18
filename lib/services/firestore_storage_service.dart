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
  Future<FoodEntry> createEntry(FoodEntry entry) {
    throw UnimplementedError('Firestore implementation coming soon');
  }

  @override
  Future<List<FoodEntry>> getEntriesByDate(DateTime date) {
    throw UnimplementedError();
  }

  @override
  Future<int> updateEntry(FoodEntry entry) {
    throw UnimplementedError();
  }

  @override
  Future<int> deleteEntry(int id) {
    throw UnimplementedError();
  }

  @override
  Future<void> clearTodayHistory() {
    throw UnimplementedError();
  }

  @override
  Future<int> saveUserProfile(UserProfile profile) {
    throw UnimplementedError();
  }

  @override
  Future<UserProfile?> getUserProfile() {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUserProfile() {
    throw UnimplementedError();
  }

  @override
  Future<void> updateExpenditureForToday(int calories) {
    throw UnimplementedError();
  }

  @override
  Future<void> incrementFoodUsage(int foodId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<int, int>> getFoodUsageCounts() {
    throw UnimplementedError();
  }

  @override
  Future<void> logHabit(int habitId, String detail) {
    throw UnimplementedError();
  }

  @override
  Future<List<HabitLog>> getHabitLogsByDate(int habitId, DateTime date) {
    throw UnimplementedError();
  }

  @override
  Future<int> calculateStreak(int habitId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Habit>> getAllHabits() {
    throw UnimplementedError();
  }

  @override
  Future<List<Habit>> getEnabledHabits() {
    throw UnimplementedError();
  }

  @override
  Future<void> updateHabitEnabled(int habitId, bool enabled) {
    throw UnimplementedError();
  }

  @override
  Future<int> saveRecipe(Recipe recipe, List<RecipeIngredient> ingredients) {
    throw UnimplementedError();
  }

  @override
  Future<List<Recipe>> getAllRecipes() {
    throw UnimplementedError();
  }

  @override
  Future<List<RecipeIngredient>> getRecipeIngredients(int recipeId) {
    throw UnimplementedError();
  }

  @override
  Future<void> registerRecipeIngredients(int recipeId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteRecipe(int recipeId) {
    throw UnimplementedError();
  }

  @override
  Future<DashboardStats> getDashboardStats(
    DateTime startDate,
    DateTime endDate,
  ) {
    throw UnimplementedError();
  }
}
