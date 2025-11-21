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
  final double molybdenum; // ← Debe existir
  final double chromium; // ← Debe existir
  final double fluorine; // ← Debe existir
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

  // Aminoácidos no esenciales
  final double alanine;
  final double arginine;
  final double asparticAcid;
  final double glutamicAcid;
  final double glycine;
  final double proline;
  final double serine;
  final double tyrosine;
  final double cysteine;
  final double glutamine;
  final double asparagine;

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
    this.molybdenum = 0, // ← SÍ, agregar esto
    this.chromium = 0, // ← SÍ, agregar esto
    this.fluorine = 0, // ← SÍ, agregar esto
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

    this.alanine = 0,
    this.arginine = 0,
    this.asparticAcid = 0,
    this.glutamicAcid = 0,
    this.glycine = 0,
    this.proline = 0,
    this.serine = 0,
    this.tyrosine = 0,
    this.cysteine = 0,
    this.glutamine = 0,
    this.asparagine = 0,
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
      molybdenum: totals['molybdenum'] ?? 0, // ← NUEVO
      chromium: totals['chromium'] ?? 0, // ← NUEVO
      fluorine: totals['fluorine'] ?? 0, // ← NUEVO
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
      alanine: totals['alanine'] ?? 0,
      arginine: totals['arginine'] ?? 0,
      asparticAcid: totals['asparticAcid'] ?? 0,
      glutamicAcid: totals['glutamicAcid'] ?? 0,
      glycine: totals['glycine'] ?? 0,
      proline: totals['proline'] ?? 0,
      serine: totals['serine'] ?? 0,
      tyrosine: totals['tyrosine'] ?? 0,
      cysteine: totals['cysteine'] ?? 0,
      glutamine: totals['glutamine'] ?? 0,
      asparagine: totals['asparagine'] ?? 0,
    );
  }
  factory NutritionReport.fromJson(Map<String, dynamic> json) {
    return NutritionReport(
      calories: (json['calories'] ?? 0).toDouble(),
      proteins: (json['proteins'] ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? 0).toDouble(),
      totalFats: (json['totalFats'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      omega3: (json['omega3'] ?? 0).toDouble(),
      omega6: (json['omega6'] ?? 0).toDouble(),
      omega9: (json['omega9'] ?? 0).toDouble(),
      calcium: (json['calcium'] ?? 0).toDouble(),
      iron: (json['iron'] ?? 0).toDouble(),
      magnesium: (json['magnesium'] ?? 0).toDouble(),
      phosphorus: (json['phosphorus'] ?? 0).toDouble(),
      potassium: (json['potassium'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      zinc: (json['zinc'] ?? 0).toDouble(),
      copper: (json['copper'] ?? 0).toDouble(),
      manganese: (json['manganese'] ?? 0).toDouble(),
      selenium: (json['selenium'] ?? 0).toDouble(),
      vitaminA: (json['vitaminA'] ?? 0).toDouble(),
      vitaminC: (json['vitaminC'] ?? 0).toDouble(),
      vitaminE: (json['vitaminE'] ?? 0).toDouble(),
      vitaminK: (json['vitaminK'] ?? 0).toDouble(),
      vitaminB1: (json['vitaminB1'] ?? 0).toDouble(),
      vitaminB2: (json['vitaminB2'] ?? 0).toDouble(),
      vitaminB3: (json['vitaminB3'] ?? 0).toDouble(),
      vitaminB4: (json['vitaminB4'] ?? 0).toDouble(),
      vitaminB5: (json['vitaminB5'] ?? 0).toDouble(),
      vitaminB6: (json['vitaminB6'] ?? 0).toDouble(),
      vitaminB7: (json['vitaminB7'] ?? 0).toDouble(),
      vitaminB9: (json['vitaminB9'] ?? 0).toDouble(),
      vitaminB12: (json['vitaminB12'] ?? 0).toDouble(),
      vitaminD: (json['vitaminD'] ?? 0).toDouble(),
      iodine: (json['iodine'] ?? 0).toDouble(),
      molybdenum: (json['molybdenum'] ?? 0).toDouble(),
      chromium: (json['chromium'] ?? 0).toDouble(),
      fluorine: (json['fluorine'] ?? 0).toDouble(),
      histidine: (json['histidine'] ?? 0).toDouble(),
      isoleucine: (json['isoleucine'] ?? 0).toDouble(),
      leucine: (json['leucine'] ?? 0).toDouble(),
      lysine: (json['lysine'] ?? 0).toDouble(),
      methionine: (json['methionine'] ?? 0).toDouble(),
      phenylalanine: (json['phenylalanine'] ?? 0).toDouble(),
      threonine: (json['threonine'] ?? 0).toDouble(),
      tryptophan: (json['tryptophan'] ?? 0).toDouble(),
      valine: (json['valine'] ?? 0).toDouble(),
      alanine: (json['alanine'] ?? 0).toDouble(),
      arginine: (json['arginine'] ?? 0).toDouble(),
      asparticAcid: (json['asparticAcid'] ?? 0).toDouble(),
      glutamicAcid: (json['glutamicAcid'] ?? 0).toDouble(),
      glycine: (json['glycine'] ?? 0).toDouble(),
      proline: (json['proline'] ?? 0).toDouble(),
      serine: (json['serine'] ?? 0).toDouble(),
      tyrosine: (json['tyrosine'] ?? 0).toDouble(),
      cysteine: (json['cysteine'] ?? 0).toDouble(),
      glutamine: (json['glutamine'] ?? 0).toDouble(),
      asparagine: (json['asparagine'] ?? 0).toDouble(),
    );
  }
}
