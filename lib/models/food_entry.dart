import 'food.dart';

class FoodEntry {
  final Food food;
  final double grams;
  final DateTime timestamp;

  FoodEntry({
    required this.food,
    required this.grams,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
