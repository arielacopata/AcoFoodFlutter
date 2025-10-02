// En: lib/models/food_entry.dart
import 'food.dart';

class FoodEntry {
  final int? id; // <-- AÑADE ESTO
  final Food food;
  final double grams;
  final DateTime timestamp;

  FoodEntry({
    this.id, // <-- AÑADE ESTO
    required this.food,
    required this.grams,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Método para convertir a Map (para la BD)
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'foodId': food.id,
    'grams': grams,
    'timestamp': timestamp.toIso8601String(),
  };
}

// Para UPDATE (sin id)
Map<String, dynamic> toMapForUpdate() {
  return {
    'foodId': food.id,
    'grams': grams,
    'timestamp': timestamp.toIso8601String(),
  };
}
}
