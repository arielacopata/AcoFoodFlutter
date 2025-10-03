class NutritionReport {
  final double calories;
  final double proteins;
  final double carbohydrates;
  final double fiber;
  final double totalSugars;
  final double totalFats;
  final double saturatedFats;
  final double omega3;
  final double omega6;
  final double omega9;
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
  final double iodine;
  final double vitaminB12;
  final double vitaminD;

  // Aminoácidos esenciales
  final double histidine;
  final double isoleucine;
  final double leucine;
  final double lysine;
  final double methionine;
  final double phenylalanine;
  final double threonine;
  final double tryptophan;
  final double valine;

  NutritionReport({
    this.calories = 0,
    this.proteins = 0,
    this.carbohydrates = 0,
    this.fiber = 0,
    this.totalSugars = 0,
    this.totalFats = 0,
    this.saturatedFats = 0,
    this.omega3 = 0,
    this.omega6 = 0,
    this.omega9 = 0,
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
    this.iodine = 0,
    this.vitaminB12 = 0,
    this.vitaminD = 0,

    // Agregar estos al constructor:
    this.histidine = 0,
    this.isoleucine = 0,
    this.leucine = 0,
    this.lysine = 0,
    this.methionine = 0,
    this.phenylalanine = 0,
    this.threonine = 0,
    this.tryptophan = 0,
    this.valine = 0,
  });

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
      iodine: totals['iodine'] ?? 0,
      vitaminB12: totals['vitaminB12'] ?? 0,
      vitaminD: totals['vitaminD'] ?? 0,

      // Agregar estos al factory:
      histidine: totals['histidine'] ?? 0,
      isoleucine: totals['isoleucine'] ?? 0,
      leucine: totals['leucine'] ?? 0,
      lysine: totals['lysine'] ?? 0,
      methionine: totals['methionine'] ?? 0,
      phenylalanine: totals['phenylalanine'] ?? 0,
      threonine: totals['threonine'] ?? 0,
      tryptophan: totals['tryptophan'] ?? 0,
      valine: totals['valine'] ?? 0,
    );
  }
}
