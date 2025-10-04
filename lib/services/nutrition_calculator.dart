// lib/services/nutrition_calculator.dart

import '../models/food_entry.dart';
import '../models/nutrition_report.dart';

class NutritionCalculator {
  Future<NutritionReport> calculateDailyTotals(List<FoodEntry> entries) async {
    final Map<String, double> totals = {};

    for (final entry in entries) {
      final food = entry.food;

      // Si es suplemento, procesar la dosis
      if (entry.isSupplement) {
        _processSupplementDose(totals, food.id, entry.supplementDose);
        continue; // No procesar como alimento normal
      }

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
      _addToTotal(totals, 'iodine', food.iodine * scale);
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

      // Aminoácidos esenciales
      _addToTotal(totals, 'histidine', food.histidine * scale);
      _addToTotal(totals, 'isoleucine', food.isoleucine * scale);
      _addToTotal(totals, 'leucine', food.leucine * scale);
      _addToTotal(totals, 'lysine', food.lysine * scale);
      _addToTotal(totals, 'methionine', food.methionine * scale);
      _addToTotal(totals, 'phenylalanine', food.phenylalanine * scale);
      _addToTotal(totals, 'threonine', food.threonine * scale);
      _addToTotal(totals, 'tryptophan', food.tryptophan * scale);
      _addToTotal(totals, 'valine', food.valine * scale);
    }

    return NutritionReport.fromMap(totals);
  }

  void _addToTotal(Map<String, double> map, String key, double value) {
    map[key] = (map[key] ?? 0) + value;
  }

void _processSupplementDose(Map<String, double> totals, int? supplementId, String? dose) {
  if (dose == null || supplementId == null) return;
  
  // Extraer el número de la dosis (ej: "1000 mcg" -> 1000)
  final numberMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(dose);
  if (numberMatch == null) return;
  
  final value = double.parse(numberMatch.group(1)!);
  
  switch (supplementId) {
    case 9001: // B12 con factor de absorción
      // Factor intrínseco: máximo 1.5 mcg por dosis
      // Difusión pasiva: ~1% del resto
      final absorbed = value <= 1.5 
          ? value 
          : 1.5 + ((value - 1.5) * 0.01);
      _addToTotal(totals, 'vitaminB12', absorbed);
      break;
    case 9002: // Vitamina D
      _addToTotal(totals, 'vitaminD', value); // UI
      break;
    case 9003: // Omega-3
      // Asumir que viene en mg, convertir a g
      _addToTotal(totals, 'omega3', value / 1000);
      break;
  }
}
}
