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

  // Factory para construir un Food desde los datos de foods.dart
  factory Food.fromData(Food baseFood, Map<String, double> nutrients) {
    return Food(
      id: baseFood.id,
      emoji: baseFood.emoji,
      name: baseFood.name,
      fullName: baseFood.fullName,
      calories: nutrients["Calorías"] ?? 0,
      proteins: nutrients["Proteínas"] ?? 0,
      carbohydrates: nutrients["Carbohidratos"] ?? 0,
      fiber: nutrients["Fibra"] ?? 0,
      totalSugars: nutrients["Azúcares totales"] ?? 0,
      totalFats: nutrients["Grasas totales"] ?? 0,
      saturatedFats: nutrients["Grasas saturadas"] ?? 0,
      omega3: nutrients["Omega-3"] ?? 0,
      omega6: nutrients["Omega-6"] ?? 0,
      omega9: nutrients["Omega-9"] ?? 0,
      calcium: nutrients["Calcio"] ?? 0,
      iron: nutrients["Hierro"] ?? 0,
      magnesium: nutrients["Magnesio"] ?? 0,
      phosphorus: nutrients["Fósforo"] ?? 0,
      potassium: nutrients["Potasio"] ?? 0,
      sodium: nutrients["Sodio"] ?? 0,
      zinc: nutrients["Zinc"] ?? 0,
      copper: nutrients["Cobre"] ?? 0,
      manganese: nutrients["Manganeso"] ?? 0,
      selenium: nutrients["Selenio"] ?? 0,
      iodine: nutrients["Yodo"] ?? 0,
      vitaminA: nutrients["Vitamina A"] ?? 0,
      vitaminC: nutrients["Vitamina C"] ?? 0,
      vitaminE: nutrients["Vitamina E"] ?? 0,
      vitaminK: nutrients["Vitamina K"] ?? 0,
      vitaminB1: nutrients["Vitamina B1 (Tiamina)"] ?? 0,
      vitaminB2: nutrients["Vitamina B2 (Riboflavina)"] ?? 0,
      vitaminB3: nutrients["Vitamina B3 (Niacina)"] ?? 0,
      vitaminB4: nutrients["Vitamina B4 (Colina)"] ?? 0,
      vitaminB5: nutrients["Vitamina B5 (Ácido pantoténico)"] ?? 0,
      vitaminB6: nutrients["Vitamina B6"] ?? 0,
      vitaminB7: nutrients["Vitamina B7 (Biotina)"] ?? 0,
      vitaminB9: nutrients["Vitamina B9 (Folato)"] ?? 0,
    );
  }
}
