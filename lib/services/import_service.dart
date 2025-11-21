//services/import_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_factory.dart';
import '../models/user_profile.dart';
import 'sqlite_storage_service.dart';
import '../models/recipe.dart';
import '../services/food_repository.dart';

class ImportService {
  static Future<bool> importFromJson(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      // Validar versión
      final version = data['version'] as String?;
      if (version != '1.0') {
        print('Versión de backup no compatible: $version');
        return false;
      }

      final db =
          await (StorageFactory.instance as SQLiteStorageService).database;

      // 1. Restaurar perfil
      if (data['profile'] != null) {
        final profileData = data['profile'] as Map<String, dynamic>;
        final profile = UserProfile.fromMap(profileData);
        await StorageFactory.instance.saveUserProfile(profile);
      }

      // 2. Limpiar y restaurar historial
      await db.delete('history');
      final history = data['history'] as List<dynamic>?;
      if (history != null) {
        for (final entry in history) {
          await db.insert('history', entry as Map<String, dynamic>);
        }
      }

      // 3. Limpiar y restaurar logs de hábitos
      await db.delete('habit_logs');
      final habitLogs = data['habitLogs'] as List<dynamic>?;
      if (habitLogs != null) {
        for (final log in habitLogs) {
          await db.insert('habit_logs', log as Map<String, dynamic>);
        }
      }

      // 4. Restaurar contadores de uso
      await db.delete('food_usage');
      final foodUsage = data['foodUsage'] as List<dynamic>?;
      if (foodUsage != null) {
        for (final usage in foodUsage) {
          await db.insert('food_usage', usage as Map<String, dynamic>);
        }
      }

      // 5. Limpiar y restaurar recetas
      await db.delete('recipes'); // 👈 AGREGAR ESTO
      await db.delete('recipe_ingredients'); // 👈 Y ESTO

      final recipesData = data['recipes'] as List<dynamic>?;
      if (recipesData != null) {
        for (final recipeData in recipesData) {
          final recipeMap = recipeData['recipe'] as Map<String, dynamic>;
          final recipe = Recipe.fromMap(recipeMap);

          final ingredientsData = recipeData['ingredients'] as List<dynamic>;
          final ingredients = <RecipeIngredient>[];

          for (final ingData in ingredientsData) {
            final foodId = ingData['food_id'] as int;
            final food = FoodRepository().getFoodById(foodId);

            if (food != null) {
              ingredients.add(
                RecipeIngredient(
                  recipeId: 0, // Temporal
                  food: food,
                  grams: (ingData['grams'] as num).toDouble(),
                ),
              );
            }
          }

          // Guardar receta con ingredientes
          await StorageFactory.instance.saveRecipe(recipe, ingredients);
        }
      }

      // 6. Restaurar preferencias (era el paso 5)

      final prefs = await SharedPreferences.getInstance();
      final preferences = data['preferences'] as Map<String, dynamic>?;
      if (preferences != null) {
        if (preferences['sort_order'] != null) {
          await prefs.setString('sort_order', preferences['sort_order']);
        }
        if (preferences['theme_mode'] != null) {
          await prefs.setString('theme_mode', preferences['theme_mode']);
        }
        if (preferences['b12_enabled'] != null) {
          await prefs.setBool('b12_enabled', preferences['b12_enabled']);
        }
        if (preferences['lino_enabled'] != null) {
          await prefs.setBool('lino_enabled', preferences['lino_enabled']);
        }
        if (preferences['legumbres_enabled'] != null) {
          await prefs.setBool(
            'legumbres_enabled',
            preferences['legumbres_enabled'],
          );
        }
      }

      if (history != null) {
        await _markCompletedSupplementsFromImport(
          history.map((e) => e as Map<String, dynamic>).toList(),
        );
      }
      return true;
    } catch (e) {
      print('Error importando backup: $e');
      return false;
    }
  }

  static Future<void> _markCompletedSupplementsFromImport(
    List<Map<String, dynamic>> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Agrupar entradas por fecha
    final entriesByDate = <String, List<Map<String, dynamic>>>{};
    for (final entry in entries) {
      final timestamp = DateTime.parse(entry['timestamp']);
      final dateKey = timestamp.toIso8601String().split('T')[0];
      entriesByDate.putIfAbsent(dateKey, () => []).add(entry);
    }

    // Marcar suplementos completados para cada día
    for (final dateKey in entriesByDate.keys) {
      final dayEntries = entriesByDate[dateKey]!;

      // B12 (id: 9001)
      if (dayEntries.any((e) => e['foodId'] == 9001)) {
        await prefs.setBool('b12_completed_$dateKey', true);
      }

      // Yodo (id: 9004)
      if (dayEntries.any((e) => e['foodId'] == 9004)) {
        await prefs.setBool('yodo_completed_$dateKey', true);
      }
    }
  }
}
