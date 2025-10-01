import '../models/food.dart';
import '../models/food_group.dart';

// Convertimos la variable en una función que necesita la lista de alimentos
List<FoodGroupDisplay> getFoodGroups(List<Food> allFoods) {
  return [
    FoodGroupDisplay(
      groupName: "Avena",
      emoji: "🍚",
      items: allFoods.where((f) => [1, 2].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Batata / Boniato",
      emoji: "🍠",
      items: allFoods.where((f) => [15, 16, 17, 18].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Calabaza",
      emoji: "🎃",
      items: allFoods.where((f) => [12, 13, 14].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Cebolla",
      emoji: "🧅",
      items: allFoods.where((f) => [7, 8, 9].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Garbanzos",
      emoji: "🥣",
      items: allFoods.where((f) => [10, 11, 43].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Lentejas",
      emoji: "🥣",
      items: allFoods.where((f) => [49, 50, 51].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Manzana",
      emoji: "🍎",
      items: allFoods.where((f) => [52, 69].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Palta",
      emoji: "🥑",
      items: allFoods.where((f) => [22, 42].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Papa",
      emoji: "🥔",
      items: allFoods.where((f) => [23, 24].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Porotos",
      emoji: "🥣",
      items: allFoods.where((f) => [44, 45, 46, 47].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Remolacha",
      emoji: "🍠",
      items: allFoods.where((f) => [26, 27, 28].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Zanahoria",
      emoji: "🥕",
      items: allFoods.where((f) => [25, 32, 33].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Morrones",
      emoji: "🌶️",
      items: allFoods.where((f) => [70, 71, 72].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Repollo",
      emoji: "🥬",
      items: allFoods.where((f) => [75, 76, 77].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Melón",
      emoji: "🍈",
      items: allFoods.where((f) => [82, 83, 84].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Frutas",
      emoji: "🍓",
      items: allFoods
          .where((f) => [79, 80, 81, 91, 61, 73].contains(f.id))
          .toList(),
    ),
    FoodGroupDisplay(
      groupName: "Frutos Secos",
      emoji: "🥜",
      items: allFoods.where((f) => [4, 6, 89, 90].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Semillas",
      emoji: "🌱",
      items: allFoods.where((f) => [30, 58, 59, 60].contains(f.id)).toList(),
    ),
    // En data/food_groups.dart, después de los otros grupos:
    FoodGroupDisplay(
      groupName: "Aceitunas",
      emoji: "🫒",
      items: allFoods.where((f) => [65, 93].contains(f.id)).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Verduras",
      emoji: "🥦",
      items: allFoods
          .where((f) => [62, 63, 64, 66, 67, 68, 74, 78].contains(f.id))
          .toList(),
    ),
    // Individuales
    FoodGroupDisplay(
      groupName: "Banana",
      emoji: "🍌",
      items: allFoods.where((f) => f.id == 3).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Mandarina",
      emoji: "🍊",
      items: allFoods.where((f) => f.id == 5).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Lechuga",
      emoji: "🥬",
      items: allFoods.where((f) => f.id == 21).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Maní",
      emoji: "🥜",
      items: allFoods.where((f) => f.id == 4).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Mandarina",
      emoji: "🍊",
      items: allFoods.where((f) => f.id == 5).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Nueces",
      emoji: "🌰",
      items: allFoods.where((f) => f.id == 6).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Quinoa",
      emoji: "🍚",
      items: allFoods.where((f) => f.id == 20).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Lechuga",
      emoji: "🥬",
      items: allFoods.where((f) => f.id == 21).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Rúcula",
      emoji: "🌿",
      items: allFoods.where((f) => f.id == 29).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Semillas de lino",
      emoji: "🌱",
      items: allFoods.where((f) => f.id == 30).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Tomate",
      emoji: "🍅",
      items: allFoods.where((f) => f.id == 31).toList(),
    ),
    FoodGroupDisplay(
      groupName: "Soja texturizada",
      emoji: "🥣",
      items: allFoods.where((f) => f.id == 41).toList(),
    ),
  ];
}
