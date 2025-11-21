// En: lib/widgets/nutrient_progress_row.dart

import 'package:flutter/material.dart';

class NutrientProgressRow extends StatelessWidget {
  final String name;
  final String type; // 'RDA', 'AI', 'Límite', 'Meta'
  final String unit;
  final double value;
  final double goal;

  const NutrientProgressRow({
    super.key,
    required this.name,
    required this.type,
    required this.unit,
    required this.value,
    required this.goal,
  });

  // Función helper para formatear valores con precisión adecuada
  String _formatValue(double val) {
    if (val < 10.0) {
      return val.toStringAsFixed(2); // 2 decimales para valores < 10
    } else {
      return val.toStringAsFixed(0); // Sin decimales para valores >= 10
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lógica para calcular el progreso (de 0.0 a 1.0)
    final double progress = (goal > 0) ? (value / goal).clamp(0.0, 1.0) : 0.0;

    // Lógica para determinar el color de la barra
    final Color progressColor;
    if (type == 'Límite') {
      // Para límites como el Sodio, se pone rojo si te pasas
      progressColor = progress > 1.0 ? Colors.red.shade700 : Colors.green;
    } else {
      // Para metas (RDA/AI), va de rojo a verde
      if (progress < 0.5) {
        progressColor = Colors.red.shade400;
      } else if (progress < 0.9) {
        progressColor = Colors.orange.shade400;
      } else {
        progressColor = Colors.green;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila con el nombre y los valores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${_formatValue(value)} / ${_formatValue(goal)} $unit ($type)",
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Barra de progreso lineal
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }
}
