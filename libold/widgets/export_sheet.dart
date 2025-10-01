// En: lib/widgets/export_sheet.dart

import 'package:flutter/material.dart';
import '../services/export_service.dart';
import '../models/food_entry.dart';

class ExportSheet extends StatelessWidget {
  final List<FoodEntry> history;
  final ExportService _exportService = ExportService();

  ExportSheet({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título del Modal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Importar / Exportar",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 24),

          // Sección de Exportar
          const Text(
            "EXPORTAR DATOS DEL DÍA",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final textToExport = _exportService.generateHistoryAsText(
                      history,
                    );
                    _exportService.shareText(
                      textToExport,
                      subject: "Resumen de Comidas",
                    );
                    Navigator.of(
                      context,
                    ).pop(); // Cierra el modal después de compartir
                  },
                  child: const Text("Como Texto (para Zepp)"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implementar la lógica para guardar como archivo
                    print("Exportar como archivo presionado");
                  },
                  child: const Text("Como Archivo (Backup)"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
