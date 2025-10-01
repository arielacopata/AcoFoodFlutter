// lib/services/nutrition_calculator.dart

import '../models/food_entry.dart';
import '../models/nutrition_report.dart';

class NutritionCalculator {
  Future<NutritionReport> calculateDailyTotals(List<FoodEntry> entries) async {
    final Map<String, double> totals = {};

    for (final entry in entries) {
      final food = entry.food;
      final scale = entry.grams / 100.0;

      _addToTotal(totals, 'calories', food.calories * scale);
      _addToTotal(totals, 'proteins', food.proteins * scale);
      _addToTotal(totals, 'carbohydrates', food.carbohydrates * scale);
      _addToTotal(totals, 'fiber', food.fiber * scale);
      _addToTotal(totals, 'totalSugars', food.totalSugars * scale);
      _addToTotal(totals, 'totalFats', food.totalFats * scale);
      _addToTotal(totals, 'saturatedFats', food.saturatedFats * scale);
      _addToTotal(totals, 'omega3', food.omega3 * scale);
      _addToTotal(totals, 'omega6', food.omega6 * scale);
      _addToTotal(totals, 'omega9', food.omega9 * scale);
      _addToTotal(totals, 'calcium', food.calcium * scale);
      _addToTotal(totals, 'iron', food.iron * scale);
      _addToTotal(totals, 'magnesium', food.magnesium * scale);
      _addToTotal(totals, 'phosphorus', food.phosphorus * scale);
      _addToTotal(totals, 'potassium', food.potassium * scale);
      _addToTotal(totals, 'sodium', food.sodium * scale);
      _addToTotal(totals, 'zinc', food.zinc * scale);
      _addToTotal(totals, 'copper', food.copper * scale);
      _addToTotal(totals, 'manganese', food.manganese * scale);
      _addToTotal(totals, 'selenium', food.selenium * scale);
      _addToTotal(totals, 'vitaminA', food.vitaminA * scale);
      _addToTotal(totals, 'vitaminC', food.vitaminC * scale);
      _addToTotal(totals, 'vitaminE', food.vitaminE * scale);
      _addToTotal(totals, 'vitaminK', food.vitaminK * scale);
      _addToTotal(totals, 'vitaminB1', food.vitaminB1 * scale);
      _addToTotal(totals, 'vitaminB2', food.vitaminB2 * scale);
      _addToTotal(totals, 'vitaminB3', food.vitaminB3 * scale);
      _addToTotal(totals, 'vitaminB4', food.vitaminB4 * scale);
      _addToTotal(totals, 'vitaminB5', food.vitaminB5 * scale);
      _addToTotal(totals, 'vitaminB6', food.vitaminB6 * scale);
      _addToTotal(totals, 'vitaminB7', food.vitaminB7 * scale);
      _addToTotal(totals, 'vitaminB9', food.vitaminB9 * scale);
    }

    return NutritionReport.fromMap(totals);
  }

  void _addToTotal(Map<String, double> map, String key, double value) {
    map[key] = (map[key] ?? 0) + value;
  }
}
