import 'package:flutter/services.dart'; // Agregar este import
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/food_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class ExportService {
  /// Genera texto plano para Zepp
  static String generateTextForZepp(List<FoodEntry> entries) {
    if (entries.isEmpty) return "Sin registros para exportar";

    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.writeln(
        "${entry.grams.toStringAsFixed(0)}g de ${entry.food.name}",
      );
    }
    return buffer.toString();
  }

  /// Copia texto al portapapeles
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Genera JSON completo para backup (perfil, historial, hábitos, preferencias)
  static Future<String> generateJsonBackup(List<FoodEntry> entries) async {
    final db = await DatabaseService.instance.database;

    // Obtener todos los datos
    final profile = await DatabaseService.instance.getUserProfile();
    final allHistory = await db.query('history', orderBy: 'timestamp DESC');
    final habitLogs = await db.query('habit_logs', orderBy: 'timestamp DESC');
    final foodUsage = await db.query('food_usage');
    final habits = await db.query('habits');

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
    };

    return jsonEncode(backup);
  }

  /// Comparte archivo JSON usando share_plus
  static Future<void> shareJsonFile(String jsonContent) async {
    final directory = await getTemporaryDirectory();
    final date = DateTime.now().toIso8601String().split('T')[0];
    final file = File('${directory.path}/acofood_backup_$date.json');
    await file.writeAsString(jsonContent);

    await Share.shareXFiles([XFile(file.path)], subject: 'Backup AcoFood');
  }
}
