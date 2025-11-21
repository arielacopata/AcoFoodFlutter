import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/food_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_factory.dart';
import 'sqlite_storage_service.dart';

class ExportService {
  /// Genera texto plano para Zepp (con cantidades sumadas y nombre completo)
  static String generateTextForZepp(List<FoodEntry> entries) {
    if (entries.isEmpty) return "Sin registros para exportar";

    // Mapa para agrupar por nombre completo del alimento
    final Map<String, double> foodTotals = {};

    for (final entry in entries) {
      // Usar fullName si existe, sino usar name
      final foodName = entry.food.fullName ?? entry.food.name;

      // Sumar los gramos al total de ese alimento
      foodTotals[foodName] = (foodTotals[foodName] ?? 0) + entry.grams;
    }

    // Construir el texto con los totales
    final buffer = StringBuffer();
    foodTotals.forEach((foodName, totalGrams) {
      buffer.writeln("${totalGrams.toStringAsFixed(0)}g de $foodName");
    });

    return buffer.toString();
  }

  /// Copia texto al portapapeles
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Genera JSON completo para backup (perfil, historial, hábitos, preferencias)
/// Genera JSON completo para backup (perfil, historial, hábitos, preferencias, recetas)
static Future<String> generateJsonBackup(List<FoodEntry> entries) async {
  final db = await (StorageFactory.instance as SQLiteStorageService).database;

  // Obtener todos los datos
  final profile = await StorageFactory.instance.getUserProfile();
  final allHistory = await db.query('history', orderBy: 'timestamp DESC');
  final habitLogs = await db.query('habit_logs', orderBy: 'timestamp DESC');
  final foodUsage = await db.query('food_usage');
  final habits = await db.query('habits');

  // Obtener recetas 👈 NUEVO
  final recipes = await StorageFactory.instance.getAllRecipes();
  final recipesData = <Map<String, dynamic>>[];
  
  for (final recipe in recipes) {
    final ingredients = await StorageFactory.instance.getRecipeIngredients(recipe.id!);
    
    recipesData.add({
      'recipe': recipe.toMap(),
      'ingredients': ingredients.map((i) => {
        'food_id': i.food.id,
        'grams': i.grams,
      }).toList(),
    });
  }

  // Obtener preferencias
  final prefs = await SharedPreferences.getInstance();
  final preferences = {
    'sort_order': prefs.getString('sort_order'),
    'theme_mode': prefs.getString('theme_mode'),
    'b12_enabled': prefs.getBool('b12_enabled'),
    'lino_enabled': prefs.getBool('lino_enabled'),
    'legumbres_enabled': prefs.getBool('legumbres_enabled'),
  };

  // Construir JSON completo
  final backup = {
    'version': '1.0',
    'exportDate': DateTime.now().toIso8601String(),
    'profile': profile?.toMap(),
    'history': allHistory,
    'habitLogs': habitLogs,
    'foodUsage': foodUsage,
    'habits': habits,
    'preferences': preferences,
    'recipes': recipesData,  // 👈 NUEVO
  };

  return jsonEncode(backup);
}

  /// Comparte archivo JSON usando share_plus (método actualizado)
  static Future<void> shareJsonFile(String jsonContent) async {
    final directory = await getTemporaryDirectory();
    final date = DateTime.now().toIso8601String().split('T')[0];
    final file = File('${directory.path}/acofood_backup_$date.json');
    await file.writeAsString(jsonContent);

    // Método actualizado sin deprecación
    final result = await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'Backup AcoFood');
  }
}
