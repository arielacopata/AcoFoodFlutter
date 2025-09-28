// En: lib/services/food_repository.dart

import '../models/food.dart';
// Usamos un alias para evitar conflictos de nombres, ya que ambos archivos
// tienen una variable llamada "foods".
import '../data/foods.dart' as food_data;

class FoodRepository {
  // Lista privada que almacenará nuestros objetos Food "enriquecidos".
  List<Food> _allFoods = [];

  // Usamos un singleton para asegurarnos de que solo haya una instancia
  // de este repositorio en toda la app.
  static final FoodRepository _instance = FoodRepository._internal();
  factory FoodRepository() {
    return _instance;
  }
  FoodRepository._internal();

  // --- MÉTODOS PÚBLICOS ---

  /// Carga y combina los datos de los alimentos con sus nutrientes.
  /// Debe llamarse una vez al iniciar la aplicación.
  Future<void> loadFoods() async {
    // Si ya hemos cargado los datos, no hacemos nada para evitar trabajo extra.
    if (_allFoods.isNotEmpty) return;

    final List<Food> enrichedFoods = [];

    // Iteramos sobre la lista de alimentos base.
    for (final baseFood in food_data.foods) {
      // Buscamos sus nutrientes correspondientes por ID.
      final nutrients = food_data.nutrientsData[baseFood.id];

      // Si encontramos los nutrientes, creamos un objeto Food completo.
      if (nutrients != null) {
        enrichedFoods.add(Food.fromData(baseFood, nutrients));
      }
    }

    _allFoods = enrichedFoods;
    print(
      "✅ FoodRepository: Se cargaron ${_allFoods.length} alimentos con sus datos nutricionales.",
    );
  }

  /// Devuelve la lista completa de alimentos.
  List<Food> getAllFoods() {
    return _allFoods;
  }

  /// Busca y devuelve un alimento específico por su ID.
  Food? getFoodById(int id) {
    try {
      return _allFoods.firstWhere((food) => food.id == id);
    } catch (e) {
      // Si no se encuentra el alimento, devuelve null.
      return null;
    }
  }
}
