// En: lib/services/export_service.dart

import 'package:share_plus/share_plus.dart';
import '../models/food_entry.dart';
import 'dart:convert'; // Para la exportación JSON

class ExportService {
  /// Genera un string simple con la lista de comidas del día.
  /// Ideal para copiar y pegar en otras apps como Zepp.
  String generateHistoryAsText(List<FoodEntry> history) {
    if (history.isEmpty) {
      return "No hay registros para exportar.";
    }

    // Usamos un StringBuffer para construir el string de forma eficiente
    final buffer = StringBuffer();
    buffer.writeln("Resumen de Comidas del Día:");
    buffer.writeln("-------------------------");

    for (final entry in history) {
      buffer.writeln(
        "- ${entry.food.name}: ${entry.grams.toStringAsFixed(1)} g",
      );
    }

    return buffer.toString();
  }

  /// Genera un string en formato JSON con el historial.
  /// Ideal para crear un archivo de backup que la app pueda importar en el futuro.
  String generateBackupAsJson(List<FoodEntry> history) {
    if (history.isEmpty) {
      return "[]"; // Devuelve una lista JSON vacía
    }

    // Convertimos cada FoodEntry a un formato simple (Map) para el JSON
    final listToEncode = history
        .map(
          (entry) => {
            'foodId': entry.food.id,
            'grams': entry.grams,
            'timestamp': entry.timestamp.toIso8601String(),
          },
        )
        .toList();

    // Usamos jsonEncode para convertir la lista de Maps a un string JSON
    return jsonEncode(listToEncode);
  }

  /// Usa el paquete share_plus para compartir el texto generado.
  Future<void> shareText(String textToShare, {String? subject}) async {
    await Share.share(textToShare, subject: subject);
  }
}
