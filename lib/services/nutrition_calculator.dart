// lib/services/nutrition_calculator.dart

import '../models/food_entry.dart';
import '../models/nutrition_report.dart';

class NutritionCalculator {
  Future<NutritionReport> calculateDailyTotals(List<FoodEntry> entries) async {
  final Map<String, double> totals = {};

  for (final entry in entries) {
    final food = entry.food;
    
    // Caso especial: B12 con factor de absorción
    if (entry.isSupplement && food.id == 9001) {
      final dose = _parseB12Dose(entry.supplementDose);
      if (dose > 0) {
        // Factor intrínseco: máximo 1.5 mcg por dosis
        // Difusión pasiva: ~1% del resto
        final absorbed = dose <= 1.5 
            ? dose 
            : 1.5 + ((dose - 1.5) * 0.01);
        _addToTotal(totals, 'vitaminB12', absorbed);
      }
      continue; // No procesar como alimento normal
    }

    // Todos los demás (alimentos y suplementos)
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
    _addToTotal(totals, 'vitaminD', food.vitaminD * scale);
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
    _addToTotal(totals, 'vitaminB12', food.vitaminB12 * scale);

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

// Helper para parsear dosis de B12
double _parseB12Dose(String? dose) {
  if (dose == null) return 0;
  final numberMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(dose);
  if (numberMatch == null) return 0;
  return double.parse(numberMatch.group(1)!);
}

}
