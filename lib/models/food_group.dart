// models/food_group.dart
import 'food.dart';

class FoodGroupDisplay {
  final String groupName;
  final String emoji;
  final List<Food> items;

  FoodGroupDisplay({
    required this.groupName,
    required this.emoji,
    required this.items,
  });

  bool get hasMultiple => items.length > 1;
}
