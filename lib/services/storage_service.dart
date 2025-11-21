// lib/services/storage_service.dart
import '../models/food_entry.dart';
import '../models/user_profile.dart';
import '../models/habit.dart';
import '../models/recipe.dart';
import '../models/dashboard_stats.dart';
import '../models/food.dart';

abstract class StorageService {
  Future<void> initialize();

  // Food entries
  Future<FoodEntry> createEntry(FoodEntry entry);
  Future<List<FoodEntry>> getEntriesByDate(DateTime date);
  Future<int> updateEntry(FoodEntry entry);
  Future<int> deleteEntry(int id);
  Future<void> clearTodayHistory();

  // User profile
  Future<int> saveUserProfile(UserProfile profile);
  Future<UserProfile?> getUserProfile();
  Future<void> deleteUserProfile();
  Future<void> updateExpenditureForToday(int calories);

  // Food usage
  Future<void> incrementFoodUsage(int foodId);
  Future<Map<int, int>> getFoodUsageCounts();

  // Habits
  Future<void> logHabit(int habitId, String detail);
  Future<List<HabitLog>> getHabitLogsByDate(int habitId, DateTime date);
  Future<int> calculateStreak(int habitId);
  Future<List<Habit>> getAllHabits();
  Future<List<Habit>> getEnabledHabits();
  Future<void> updateHabitEnabled(int habitId, bool enabled);

  // Recipes
  Future<int> saveRecipe(Recipe recipe, List<RecipeIngredient> ingredients);
  Future<List<Recipe>> getAllRecipes();
  Future<List<RecipeIngredient>> getRecipeIngredients(int recipeId);
  Future<void> registerRecipeIngredients(int recipeId);
  Future<void> deleteRecipe(int recipeId);

  // Dashboard
  Future<DashboardStats> getDashboardStats(
    DateTime startDate,
    DateTime endDate, {
    bool includeFastingInAverages = false,
  });

  // Fasting days
  Future<void> markFastingDay(DateTime date, {String? note});
  Future<void> unmarkFastingDay(DateTime date);
  Future<bool> isFastingDay(DateTime date);
  Future<Set<String>> getFastingDays(DateTime startDate, DateTime endDate);

  Future<void> initializeDefaultHabits() async {}
  Future<void> close();

  // Custom foods
  Future<int> insertCustomFood(Food food);
  Future<List<Food>> getCustomFoods();
  Future<void> deleteAllCustomFoods();
  Future<bool> hasCustomFoods();
}
