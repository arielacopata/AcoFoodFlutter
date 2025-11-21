// lib/services/food_repository.dart

import '../models/food.dart';
import '../services/storage_factory.dart';
import '../data/foods.dart' as food_data;

class FoodRepository {
  // Enriched foods cache
  List<Food> _allFoods = [];

  // Singleton
  static final FoodRepository _instance = FoodRepository._internal();
  factory FoodRepository() => _instance;
  FoodRepository._internal();

  // Load base + custom foods and merge nutrients
  Future<void> loadFoods({bool forceReload = false}) async {
    if (_allFoods.isNotEmpty && !forceReload) return;
    if (forceReload) {
      _allFoods.clear();
    }

    final List<Food> enrichedFoods = [];

    // Base foods with nutrient data
    for (final baseFood in food_data.foods) {
      final nutrients = food_data.nutrientsData[baseFood.id];
      if (nutrients != null) {
        enrichedFoods.add(Food.fromData(baseFood, nutrients));
      }
    }

    // Custom foods from storage
    try {
      final customFoods = await StorageFactory.instance.getCustomFoods();
      enrichedFoods.addAll(customFoods);
    } catch (_) {
      // ignore
    }

    // Hide reserved sentinel if present
    enrichedFoods.removeWhere((food) => food.id == 9999);

    _allFoods = enrichedFoods;
  }

  List<Food> getAllFoods() => _allFoods;

  Food? getFoodById(int id) {
    for (final f in _allFoods) {
      if (f.id == id) return f;
    }
    return null;
  }
}

