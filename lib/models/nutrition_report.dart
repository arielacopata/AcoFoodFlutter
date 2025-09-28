// En: lib/models/nutrition_report.dart

class NutritionReport {
  // --- MACROS ---
  final double calories;
  final double proteins;
  final double carbohydrates;
  final double fiber;
  final double totalSugars;
  final double totalFats;
  final double saturatedFats;

  // --- ÁCIDOS GRASOS ---
  final double omega3;
  final double omega6;
  final double omega9;

  // --- MINERALES ---
  final double calcium;
  final double iron;
  final double magnesium;
  final double phosphorus;
  final double potassium;
  final double sodium;
  final double zinc;
  final double copper;
  final double manganese;
  final double selenium;

  // --- VITAMINAS ---
  final double vitaminA;
  final double vitaminC;
  final double vitaminE;
  final double vitaminK;
  final double vitaminB1;
  final double vitaminB2;
  final double vitaminB3;
  final double vitaminB4;
  final double vitaminB5;
  final double vitaminB6;
  final double vitaminB7;
  final double vitaminB9;

  NutritionReport({
    // Macros
    this.calories = 0,
    this.proteins = 0,
    this.carbohydrates = 0,
    this.fiber = 0,
    this.totalSugars = 0,
    this.totalFats = 0,
    this.saturatedFats = 0,
    // Ácidos Grasos
    this.omega3 = 0,
    this.omega6 = 0,
    this.omega9 = 0,
    // Minerales
    this.calcium = 0,
    this.iron = 0,
    this.magnesium = 0,
    this.phosphorus = 0,
    this.potassium = 0,
    this.sodium = 0,
    this.zinc = 0,
    this.copper = 0,
    this.manganese = 0,
    this.selenium = 0,
    // Vitaminas
    this.vitaminA = 0,
    this.vitaminC = 0,
    this.vitaminE = 0,
    this.vitaminK = 0,
    this.vitaminB1 = 0,
    this.vitaminB2 = 0,
    this.vitaminB3 = 0,
    this.vitaminB4 = 0,
    this.vitaminB5 = 0,
    this.vitaminB6 = 0,
    this.vitaminB7 = 0,
    this.vitaminB9 = 0,
  });

  // Un factory constructor para crear el reporte desde el mapa de totales
  // En: lib/models/nutrition_report.dart

  // ... (las propiedades y el constructor se mantienen igual)

  // Reemplaza SOLAMENTE el factory constructor con este
  factory NutritionReport.fromMap(Map<String, double> totals) {
    return NutritionReport(
      calories: totals['calories'] ?? 0,
      proteins: totals['proteins'] ?? 0,
      carbohydrates: totals['carbohydrates'] ?? 0,
      fiber: totals['fiber'] ?? 0,
      totalSugars: totals['totalSugars'] ?? 0,
      totalFats: totals['totalFats'] ?? 0,
      saturatedFats: totals['saturatedFats'] ?? 0,
      omega3: totals['omega3'] ?? 0,
      omega6: totals['omega6'] ?? 0,
      omega9: totals['omega9'] ?? 0,
      calcium: totals['calcium'] ?? 0,
      iron: totals['iron'] ?? 0,
      magnesium: totals['magnesium'] ?? 0,
      phosphorus: totals['phosphorus'] ?? 0,
      potassium: totals['potassium'] ?? 0,
      sodium: totals['sodium'] ?? 0,
      zinc: totals['zinc'] ?? 0,
      copper: totals['copper'] ?? 0,
      manganese: totals['manganese'] ?? 0,
      selenium: totals['selenium'] ?? 0,
      vitaminA: totals['vitaminA'] ?? 0,
      vitaminC: totals['vitaminC'] ?? 0,
      vitaminE: totals['vitaminE'] ?? 0,
      vitaminK: totals['vitaminK'] ?? 0,
      vitaminB1: totals['vitaminB1'] ?? 0,
      vitaminB2: totals['vitaminB2'] ?? 0,
      vitaminB3: totals['vitaminB3'] ?? 0,
      vitaminB4: totals['vitaminB4'] ?? 0,
      vitaminB5: totals['vitaminB5'] ?? 0,
      vitaminB6: totals['vitaminB6'] ?? 0,
      vitaminB7: totals['vitaminB7'] ?? 0,
      vitaminB9: totals['vitaminB9'] ?? 0,
    );
  }
}
