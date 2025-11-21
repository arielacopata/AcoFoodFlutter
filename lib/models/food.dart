// lib/models/food.dart

class Food {
  final int? id;
  final String emoji;
  final String name;
  final String? fullName;

  // --- CAMPOS NUTRICIONALES (por 100g) ---
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
  final double iodine;
  final double molybdenum; // ← Debe existir
  final double chromium; // ← Debe existir
  final double fluorine; // ← Debe existir
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
  final double vitaminB12;
  final double vitaminD;

  // --- AMINOÁCIDOS ESENCIALES ---
  final double histidine;
  final double isoleucine;
  final double leucine;
  final double lysine;
  final double methionine;
  final double phenylalanine;
  final double threonine;
  final double tryptophan;
  final double valine;

  // --- AMINOÁCIDOS NO ESENCIALES ---
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

  Food({
    this.id,
    required this.emoji,
    required this.name,
    this.fullName,
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
    this.iodine = 0,
    this.molybdenum = 0, // ← SÍ, esto
    this.chromium = 0, // ← SÍ, esto
    this.fluorine = 0, // ← SÍ, esto
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
    this.vitaminB12 = 0,
    this.vitaminD = 0,
    this.histidine = 0,
    this.isoleucine = 0,
    this.leucine = 0,
    this.lysine = 0,
    this.methionine = 0,
    this.phenylalanine = 0,
    this.threonine = 0,
    this.tryptophan = 0,
    this.valine = 0,
    this.alanine = 0.0,
    this.arginine = 0.0,
    this.asparticAcid = 0.0,
    this.glutamicAcid = 0.0,
    this.glycine = 0.0,
    this.proline = 0.0,
    this.serine = 0.0,
    this.tyrosine = 0.0,
    this.cysteine = 0,
    this.glutamine = 0,
    this.asparagine = 0,
  });

  // Factory para construir un Food desde los datos de foods.dart
  factory Food.fromData(Food baseFood, Map<String, dynamic> nutrients) {
    // Función auxiliar para convertir a double de forma segura
    double _toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return Food(
      id: baseFood.id,
      emoji: baseFood.emoji,
      name: baseFood.name,
      fullName: baseFood.fullName,
      calories: _toDouble(nutrients["Calorías"]),
      proteins: _toDouble(nutrients["Proteínas"]),
      carbohydrates: _toDouble(nutrients["Carbohidratos"]),
      fiber: _toDouble(nutrients["Fibra"]),
      totalSugars: _toDouble(nutrients["Azúcares totales"]),
      totalFats: _toDouble(nutrients["Grasas totales"]),
      saturatedFats: _toDouble(nutrients["Grasas saturadas"]),
      omega3: _toDouble(nutrients["Omega-3"]),
      omega6: _toDouble(nutrients["Omega-6"]),
      omega9: _toDouble(nutrients["Omega-9"]),
      calcium: _toDouble(nutrients["Calcio"]),
      iron: _toDouble(nutrients["Hierro"]),
      magnesium: _toDouble(nutrients["Magnesio"]),
      phosphorus: _toDouble(nutrients["Fósforo"]),
      potassium: _toDouble(nutrients["Potasio"]),
      sodium: _toDouble(nutrients["Sodio"]),
      zinc: _toDouble(nutrients["Zinc"]),
      copper: _toDouble(nutrients["Cobre"]),
      manganese: _toDouble(nutrients["Manganeso"]),
      selenium: _toDouble(nutrients["Selenio"]),
      iodine: _toDouble(nutrients["Yodo"]),
      molybdenum: _toDouble(nutrients['Molibdeno']), // ← Ya está
      chromium: _toDouble(nutrients['Cromo']), // ← Ya está
      fluorine: _toDouble(nutrients['Flúor']), // ← Ya está
      vitaminA: _toDouble(nutrients["Vitamina A"]),
      vitaminC: _toDouble(nutrients["Vitamina C"]),
      vitaminE: _toDouble(nutrients["Vitamina E"]),
      vitaminK: _toDouble(nutrients["Vitamina K"]),
      vitaminB1: _toDouble(nutrients["Vitamina B1 (Tiamina)"]),
      vitaminB2: _toDouble(nutrients["Vitamina B2 (Riboflavina)"]),
      vitaminB3: _toDouble(nutrients["Vitamina B3 (Niacina)"]),
      vitaminB4: _toDouble(nutrients["Vitamina B4 (Colina)"]),
      vitaminB5: _toDouble(nutrients["Vitamina B5 (Ácido pantoténico)"]),
      vitaminB6: _toDouble(nutrients["Vitamina B6"]),
      vitaminB7: _toDouble(nutrients["Vitamina B7 (Biotina)"]),
      vitaminB9: _toDouble(nutrients["Vitamina B9 (Folato)"]),
      vitaminB12: _toDouble(nutrients["Vitamina B12"]),
      vitaminD: _toDouble(nutrients["Vitamina D"]),
      histidine: _toDouble(nutrients["Histidina"]),
      isoleucine: _toDouble(nutrients["Isoleucina"]),
      leucine: _toDouble(nutrients["Leucina"]),
      lysine: _toDouble(nutrients["Lisina"]),
      methionine: _toDouble(nutrients["Metionina"]),
      phenylalanine: _toDouble(nutrients["Fenilalanina"]),
      threonine: _toDouble(nutrients["Treonina"]),
      tryptophan: _toDouble(nutrients["Triptófano"]),
      valine: _toDouble(nutrients["Valina"]),
      alanine: _toDouble(nutrients["Alanina"]),
      arginine: _toDouble(nutrients["Arginina"]),
      asparticAcid: _toDouble(nutrients["Ácido aspártico"]),
      glutamicAcid: _toDouble(nutrients["Ácido glutámico"]),
      glycine: _toDouble(nutrients["Glicina"]),
      proline: _toDouble(nutrients["Prolina"]),
      serine: _toDouble(nutrients["Serina"]),
      tyrosine: _toDouble(nutrients["Tirosina"]),
      cysteine: _toDouble(nutrients["Cisteína"]),
      glutamine: _toDouble(nutrients["Glutamina"]),
      asparagine: _toDouble(nutrients["Asparagina"]),
    );
  }
}
