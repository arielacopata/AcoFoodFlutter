// En: lib/data/nutrient_goals.dart

// Valores de referencia para un adulto promedio.
// RDA: Recommended Dietary Allowance
// AI: Adequate Intake

// En: lib/data/nutrient_goals.dart

final Map<String, Map<String, dynamic>> nutrientGoals = {
  // Simplemente agregamos .0 a los números enteros
  'calories': {'value': 2000.0, 'unit': 'kcal', 'type': 'Meta'},
  'proteins': {'value': 89.0, 'unit': 'g', 'type': 'Meta'},
  'carbohydrates': {'value': 289.0, 'unit': 'g', 'type': 'Meta'},
  'totalFats': {'value': 30.0, 'unit': 'g', 'type': 'Meta'},
  'fiber': {'value': 30.0, 'unit': 'g', 'type': 'RDA'},
  'saturatedFats': {'value': 13.0, 'unit': 'g', 'type': 'Límite'},

  'omega3': {'value': 1.6, 'unit': 'g', 'type': 'AI'},
  'omega6': {'value': 17.0, 'unit': 'g', 'type': 'AI'},

  'calcium': {'value': 1000.0, 'unit': 'mg', 'type': 'RDA'},
  'iron': {'value': 18.0, 'unit': 'mg', 'type': 'RDA'},
  'magnesium': {'value': 420.0, 'unit': 'mg', 'type': 'RDA'},
  'phosphorus': {'value': 700.0, 'unit': 'mg', 'type': 'RDA'},
  'potassium': {'value': 3400.0, 'unit': 'mg', 'type': 'AI'},
  'sodium': {'value': 2300.0, 'unit': 'mg', 'type': 'Límite'},
  'zinc': {'value': 11.0, 'unit': 'mg', 'type': 'RDA'},
  'copper': {'value': 0.9, 'unit': 'mg', 'type': 'RDA'},
  'manganese': {'value': 2.3, 'unit': 'mg', 'type': 'AI'},
  'selenium': {'value': 55.0, 'unit': 'mcg', 'type': 'RDA'},

  'vitaminA': {'value': 900.0, 'unit': 'mcg', 'type': 'RDA'},
  'vitaminC': {'value': 90.0, 'unit': 'mg', 'type': 'RDA'},
  'vitaminE': {'value': 15.0, 'unit': 'mg', 'type': 'RDA'},
  'vitaminK': {'value': 120.0, 'unit': 'mcg', 'type': 'AI'},
  'vitaminB1': {'value': 1.2, 'unit': 'mg', 'type': 'RDA'},
  'vitaminB2': {'value': 1.3, 'unit': 'mg', 'type': 'RDA'},
  'vitaminB3': {'value': 16.0, 'unit': 'mg', 'type': 'RDA'},
  'vitaminB4': {'value': 550.0, 'unit': 'mg', 'type': 'AI'},
  'vitaminB5': {'value': 5.0, 'unit': 'mg', 'type': 'AI'},
  'vitaminB6': {'value': 1.7, 'unit': 'mg', 'type': 'RDA'},
  'vitaminB7': {'value': 30.0, 'unit': 'mcg', 'type': 'AI'},
  'vitaminB9': {'value': 400.0, 'unit': 'mcg', 'type': 'RDA'},
  'vitaminB12': {'value': 2.4, 'unit': 'mcg', 'type': 'RDA'},
  'vitaminD': {'value': 15.0, 'unit': 'mcg', 'type': 'RDA'},
  'iodine': {'value': 150.0, 'unit': 'mcg', 'type': 'RDA'},
  "histidine": {"value": 10.0, "unit": "mg/kg/day", "type": "RDA"},
  "isoleucine": {"value": 20.0, "unit": "mg/kg/day", "type": "RDA"},
  "leucine": {"value": 39.0, "unit": "mg/kg/day", "type": "RDA"},
  "lysine": {"value": 30.0, "unit": "mg/kg/day", "type": "RDA"},
  "methionine": {"value": 15.0, "unit": "mg/kg/day", "type": "RDA"},
  "phenylalanine": {"value": 25.0, "unit": "mg/kg/day", "type": "RDA"},
  "threonine": {"value": 15.0, "unit": "mg/kg/day", "type": "RDA"},
  "tryptophan": {"value": 4.0, "unit": "mg/kg/day", "type": "RDA"},
  "valine": {"value": 26.0, "unit": "mg/kg/day", "type": "RDA"},
};
