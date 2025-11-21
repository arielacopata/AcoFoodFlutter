// Crear archivo: lib/models/recipe.dart

import 'food.dart';

class Recipe {
  final int? id;
  final String? firestoreDocId; // 👈 AGREGAR
  final String name;
  final String? emoji;
  final DateTime? createdAt; // 👈 Hacerlo nullable
  final List<RecipeIngredient> ingredients;

  Recipe({
    this.id,
    this.firestoreDocId, // 👈 AGREGAR
    required this.name,
    this.emoji,
    this.createdAt, // 👈 Ya no required
    this.ingredients = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      emoji: map['emoji'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : (map['created_at'] != null
                ? DateTime.parse(map['created_at'] as String)
                : null),
    );
  }

  // Calcular calorías totales de la receta
  double getTotalCalories() {
    // Esto requeriría acceso a los datos nutricionales de cada ingrediente
    // Lo implementaremos cuando sea necesario
    return 0;
  }
}

class RecipeIngredient {
  final int? id;
  final int recipeId;
  final Food food;
  final double grams;

  RecipeIngredient({
    this.id,
    required this.recipeId,
    required this.food,
    required this.grams,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'food_id': food.id,
      'grams': grams,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map, Food food) {
    return RecipeIngredient(
      id: map['id'] as int?,
      recipeId: map['recipe_id'] as int,
      food: food,
      grams: (map['grams'] as num).toDouble(),
    );
  }
}
