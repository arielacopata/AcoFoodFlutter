// En: lib/models/food_entry.dart
import 'food.dart';

class FoodEntry {
  final int? id; // <-- AÑADE ESTO
  final Food food;
  final double grams;
  final DateTime timestamp;
  final bool isSupplement; // NUEVO: flag para identificar suplementos
  final String? supplementDose; // NUEVO: dosis del suplemento (ej: "1000 mcg")

  FoodEntry({
    this.id, // <-- AÑADE ESTO
    required this.food,
    required this.grams,
    DateTime? timestamp,
    this.isSupplement = false,  // 👈 Falta esto en el constructor
    this.supplementDose,         // 👈 Y esto
  }) : timestamp = timestamp ?? DateTime.now();

  // Método para convertir a Map (para la BD)
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'foodId': food.id,
    'grams': grams,
    'timestamp': timestamp.toIso8601String(),
    'isSupplement': isSupplement ? 1 : 0, // 👈 AGREGAR
    'supplementDose': supplementDose,      // 👈 AGREGAR
  };
}

// Para UPDATE (sin id)
Map<String, dynamic> toMapForUpdate() {
  return {
    'foodId': food.id,
    'grams': grams,
    'timestamp': timestamp.toIso8601String(),
    'isSupplement': isSupplement ? 1 : 0, // 👈 AGREGAR
    'supplementDose': supplementDose,      // 👈 AGREGAR
  };
}
}
