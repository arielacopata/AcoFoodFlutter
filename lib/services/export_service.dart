import 'package:flutter/services.dart'; // Agregar este import
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/food_entry.dart';

class ExportService {
  /// Genera texto plano para Zepp
  static String generateTextForZepp(List<FoodEntry> entries) {
    if (entries.isEmpty) return "Sin registros para exportar";
    
    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.writeln("${entry.grams.toStringAsFixed(0)}g de ${entry.food.name}");
    }
    return buffer.toString();
  }

  /// Copia texto al portapapeles
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Genera JSON para backup
  static String generateJsonBackup(List<FoodEntry> entries) {
    if (entries.isEmpty) return "[]";
    
    final list = entries.map((entry) => {
      'foodId': entry.food.id,
      'grams': entry.grams,
      'timestamp': entry.timestamp.toIso8601String(),
    }).toList();
    
    return jsonEncode(list);
  }

  /// Comparte archivo JSON usando share_plus
  static Future<void> shareJsonFile(String jsonContent) async {
    final directory = await getTemporaryDirectory();
    final date = DateTime.now().toIso8601String().split('T')[0];
    final file = File('${directory.path}/acofood_backup_$date.json');
    await file.writeAsString(jsonContent);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Backup AcoFood',
    );
  }
}