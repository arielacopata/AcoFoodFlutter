// En: lib/widgets/nutrition_report_sheet.dart

import 'package:flutter/material.dart';
import '../models/nutrition_report.dart';
import '../data/nutrient_goals.dart';
import 'nutrient_progress_row.dart';
import 'package:flutter/services.dart'; // Para Clipboard
import 'package:intl/intl.dart'; // Para formatear la fecha

class NutritionReportSheet extends StatefulWidget {
  final NutritionReport report;
  final double totalCaloriesGoal;
  final double proteinGoalGrams;
  final double carbsGoalGrams;
  final double fatGoalGrams;
  final double userWeight;
  final DateTime selectedDate;
  final Function(DateTime newDate) onDateChanged;

  const NutritionReportSheet({
    super.key,
    required this.report,
    required this.totalCaloriesGoal,
    required this.proteinGoalGrams,
    required this.carbsGoalGrams,
    required this.fatGoalGrams,
    required this.selectedDate,
    required this.onDateChanged,
    this.userWeight = 70.0, // Default 70kg
  });
  @override
  State<NutritionReportSheet> createState() => _NutritionReportSheetState();
}

class _NutritionReportSheetState extends State<NutritionReportSheet> {
  static const List<String> nutrientOrder = [
    'calories',
    'proteins',
    'totalFats',
    'carbohydrates',
    'fiber',
    'omega3',
    'omega6',
    'vitaminA',
    'vitaminB1',
    'vitaminB2',
    'vitaminB3',
    'vitaminB6',
    'vitaminB9',
    'vitaminC',
    'vitaminE',
    'vitaminK',
    'vitaminB4',
    'vitaminB5',
    'vitaminB7',
    'vitaminB12',
    'vitaminD',
    'calcium',
    'iron',
    'magnesium',
    'phosphorus',
    'potassium',
    'sodium',
    'zinc',
    'copper',
    'manganese',
    'selenium',
    'iodine',
    'histidine',
    'isoleucine',
    'leucine',
    'lysine',
    'methionine',
    'phenylalanine',
    'threonine',
    'tryptophan',
    'valine',
  ];

  Future<void> _exportReport(BuildContext context) async {
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy', 'es').format(now);

    final buffer = StringBuffer();
    buffer.writeln('📊 Reporte Nutricional - $dateStr\n');

    // Macronutrientes principales
    buffer.writeln('═══ MACRONUTRIENTES ═══');
    _addNutrientLine(
      buffer,
      'calories',
      'Calorías',
      'kcal',
      widget.totalCaloriesGoal,
      'Meta',
    );
    _addNutrientLine(
      buffer,
      'proteins',
      'Proteínas',
      'g',
      widget.proteinGoalGrams,
      'Meta',
    );
    _addNutrientLine(
      buffer,
      'totalFats',
      'Grasas Totales',
      'g',
      widget.fatGoalGrams,
      'Meta',
    );
    _addNutrientLine(
      buffer,
      'carbohydrates',
      'Carbohidratos',
      'g',
      widget.carbsGoalGrams,
      'Meta',
    );
    buffer.writeln();

    // Resto de nutrientes
    buffer.writeln('═══ NUTRIENTES ═══');
    for (final nutrientKey in nutrientOrder) {
      // Saltar los macros principales que ya agregamos
      if ([
        'calories',
        'proteins',
        'totalFats',
        'carbohydrates',
      ].contains(nutrientKey)) {
        continue;
      }

      final value = _getNutrientValue(nutrientKey);
      if (value > 0 || ['omega3', 'omega6'].contains(nutrientKey)) {
        final goalData = nutrientGoals[nutrientKey];
        if (goalData != null) {
          const nutrientNameMapping = {
            'fiber': 'Fibra',
            'omega3': 'Omega-3',
            'omega6': 'Omega-6',
            'calcium': 'Calcio',
            'iron': 'Hierro',
            'magnesium': 'Magnesio',
            'phosphorus': 'Fósforo',
            'potassium': 'Potasio',
            'sodium': 'Sodio',
            'zinc': 'Zinc',
            'copper': 'Cobre',
            'manganese': 'Manganeso',
            'selenium': 'Selenio',
            'vitaminA': 'Vitamina A',
            'vitaminC': 'Vitamina C',
            'vitaminE': 'Vitamina E',
            'vitaminK': 'Vitamina K',
            'vitaminB1': 'Vitamina B1 (Tiamina)',
            'vitaminB2': 'Vitamina B2 (Riboflavina)',
            'vitaminB3': 'Vitamina B3 (Niacina)',
            'vitaminB4': 'Vitamina B4 (Colina)',
            'vitaminB5': 'Vitamina B5 (Ác. Pantoténico)',
            'vitaminB6': 'Vitamina B6',
            'vitaminB7': 'Vitamina B7 (Biotina)',
            'vitaminB9': 'Vitamina B9 (Folato)',
            'iodine': 'Yodo',
          };

          final name = nutrientNameMapping[nutrientKey] ?? nutrientKey;
          _addNutrientLine(
            buffer,
            nutrientKey,
            name,
            goalData['unit'],
            goalData['value'],
            goalData['type'],
          );
        }
      }
    }

    // Copiar al portapapeles
    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reporte copiado al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _addNutrientLine(
    StringBuffer buffer,
    String key,
    String name,
    String unit,
    double goal,
    String type,
  ) {
    final value = _getNutrientValue(key);
    final percentage = goal > 0
        ? ((value / goal) * 100).toStringAsFixed(0)
        : '0';
    buffer.writeln(
      '$name: ${value.toStringAsFixed(1)} / ${goal.toStringAsFixed(0)} $unit ($type) - $percentage%',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity!.abs() < 300) return;

            if (details.primaryVelocity! > 0) {
              // Swipe derecha → día anterior (siempre permitido)
              final newDate = widget.selectedDate.subtract(
                const Duration(days: 1),
              );
              widget.onDateChanged(newDate);
            } else if (details.primaryVelocity! < 0) {
              // Swipe izquierda → día siguiente (solo si no es futuro)
              final today = DateTime.now();
              final todayStart = DateTime(today.year, today.month, today.day);
              final selectedStart = DateTime(
                widget.selectedDate.year,
                widget.selectedDate.month,
                widget.selectedDate.day,
              );

              // Si ya estás viendo hoy, no permitir ir al futuro
              if (selectedStart.isAtSameMomentAs(todayStart) ||
                  selectedStart.isAfter(todayStart)) {
                return; // Bloquear
              }

              final newDate = widget.selectedDate.add(const Duration(days: 1));
              widget.onDateChanged(newDate);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                _buildDateHeader(),
                const Text(
                  "Reporte Nutricional",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: nutrientOrder.length,
                    itemBuilder: (context, index) {
                      final nutrientKey = nutrientOrder[index];
                      final row = _buildNutrientRow(nutrientKey);
                      return row ?? const SizedBox.shrink();
                    },
                  ),
                ),
                // Al final de la Column, después del ListView
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Exportar Reporte'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () => _exportReport(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? _buildNutrientRow(String nutrientKey) {
    final value = _getNutrientValue(nutrientKey);

    if (value <= 0 &&
        !['omega3', 'omega6', 'vitaminB12', 'vitaminD'].contains(nutrientKey)) {
      return null;
    }
    Map<String, dynamic>? goalData;

    if (nutrientKey == 'calories') {
      goalData = {
        'value': widget.totalCaloriesGoal,
        'unit': 'kcal',
        'type': 'Meta',
      };
    } else if (nutrientKey == 'proteins') {
      goalData = {
        'value': widget.proteinGoalGrams,
        'unit': 'g',
        'type': 'Meta',
      };
    } else if (nutrientKey == 'carbohydrates') {
      goalData = {'value': widget.carbsGoalGrams, 'unit': 'g', 'type': 'Meta'};
    } else if (nutrientKey == 'totalFats') {
      goalData = {'value': widget.fatGoalGrams, 'unit': 'g', 'type': 'Meta'};
    } else {
      goalData = nutrientGoals[nutrientKey];

      // Convertir aminoácidos de mg/kg/day a gramos totales
      if (goalData != null && goalData['unit'] == 'mg/kg/day') {
        final mgPerKg = goalData['value'] as double;
        final totalMg = mgPerKg * widget.userWeight;
        final totalGrams = totalMg / 1000; // convertir mg a g

        goalData = {'value': totalGrams, 'unit': 'g', 'type': goalData['type']};
      }
    }

    if (goalData == null) return null;

    const nutrientNameMapping = {
      'calories': "Calorías",
      'proteins': "Proteínas",
      'carbohydrates': "Carbohidratos",
      'totalFats': "Grasas Totales",
      'fiber': "Fibra",
      'saturatedFats': "Grasas Saturadas",
      'omega3': "Omega-3",
      'omega6': "Omega-6",
      'calcium': "Calcio",
      'iron': "Hierro",
      'magnesium': "Magnesio",
      'phosphorus': "Fósforo",
      'potassium': "Potasio",
      'sodium': "Sodio",
      'zinc': "Zinc",
      'copper': "Cobre",
      'manganese': "Manganeso",
      'selenium': "Selenio",
      'vitaminA': "Vitamina A",
      'vitaminC': "Vitamina C",
      'vitaminE': "Vitamina E",
      'vitaminK': "Vitamina K",
      'vitaminB1': "Vitamina B1 (Tiamina)",
      'vitaminB2': "Vitamina B2 (Riboflavina)",
      'vitaminB3': "Vitamina B3 (Niacina)",
      'vitaminB4': "Vitamina B4 (Colina)",
      'vitaminB5': "Vitamina B5 (Ác. Pantoténico)",
      'vitaminB6': "Vitamina B6",
      'vitaminB7': "Vitamina B7 (Biotina)",
      'vitaminB9': "Vitamina B9 (Folato)",
      'vitaminB12': "Vitamina B12",
      'vitaminD': "Vitamina D",
      'iodine': "Yodo",
      'histidine': "Histidina",
      'isoleucine': "Isoleucina",
      'leucine': "Leucina",
      'lysine': "Lisina",
      'methionine': "Metionina",
      'phenylalanine': "Fenilalanina",
      'threonine': "Treonina",
      'tryptophan': "Triptófano",
      'valine': "Valina",
    };

    // Agregar divisor antes del primer aminoácido
    if (nutrientKey == 'histidine') {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(thickness: 2),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Aminoácidos Esenciales',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          NutrientProgressRow(
            name: nutrientNameMapping[nutrientKey] ?? "Desconocido",
            value: value,
            goal: goalData['value'],
            unit: goalData['unit'],
            type: goalData['type'],
          ),
        ],
      );
    }
    return NutrientProgressRow(
      name: nutrientNameMapping[nutrientKey] ?? "Desconocido",
      value: value,
      goal: goalData['value'],
      unit: goalData['unit'],
      type: goalData['type'],
    );
  }

  double _getNutrientValue(String key) {
    switch (key) {
      case 'calories':
        return widget.report.calories;
      case 'proteins':
        return widget.report.proteins;
      case 'carbohydrates':
        return widget.report.carbohydrates;
      case 'totalFats':
        return widget.report.totalFats;
      case 'fiber':
        return widget.report.fiber;
      case 'saturatedFats':
        return widget.report.saturatedFats;
      case 'omega3':
        return widget.report.omega3;
      case 'omega6':
        return widget.report.omega6;
      case 'calcium':
        return widget.report.calcium;
      case 'iron':
        return widget.report.iron;
      case 'magnesium':
        return widget.report.magnesium;
      case 'phosphorus':
        return widget.report.phosphorus;
      case 'potassium':
        return widget.report.potassium;
      case 'sodium':
        return widget.report.sodium;
      case 'zinc':
        return widget.report.zinc;
      case 'copper':
        return widget.report.copper;
      case 'manganese':
        return widget.report.manganese;
      case 'selenium':
        return widget.report.selenium;
      case 'vitaminA':
        return widget.report.vitaminA;
      case 'vitaminC':
        return widget.report.vitaminC;
      case 'vitaminE':
        return widget.report.vitaminE;
      case 'vitaminK':
        return widget.report.vitaminK;
      case 'vitaminB1':
        return widget.report.vitaminB1;
      case 'vitaminB2':
        return widget.report.vitaminB2;
      case 'vitaminB3':
        return widget.report.vitaminB3;
      case 'vitaminB4':
        return widget.report.vitaminB4;
      case 'vitaminB5':
        return widget.report.vitaminB5;
      case 'vitaminB6':
        return widget.report.vitaminB6;
      case 'vitaminB7':
        return widget.report.vitaminB7;
      case 'vitaminB9':
        return widget.report.vitaminB9;
      case 'vitaminB12':
        return widget.report.vitaminB12;
      case 'vitaminD':
        return widget.report.vitaminD;
      case 'iodine':
        return widget.report.iodine;
      case 'histidine':
        return widget.report.histidine;
      case 'isoleucine':
        return widget.report.isoleucine;
      case 'leucine':
        return widget.report.leucine;
      case 'lysine':
        return widget.report.lysine;
      case 'methionine':
        return widget.report.methionine;
      case 'phenylalanine':
        return widget.report.phenylalanine;
      case 'threonine':
        return widget.report.threonine;
      case 'tryptophan':
        return widget.report.tryptophan;
      case 'valine':
        return widget.report.valine;
      default:
        return 0.0;
    }
  }

  Widget _buildDateHeader() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final selectedStart = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );

    final isToday = selectedStart.isAtSameMomentAs(todayStart);
    final isFuture = selectedStart.isAfter(todayStart);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final newDate = widget.selectedDate.subtract(
                const Duration(days: 1),
              );
              widget.onDateChanged(newDate);
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat(
                    'EEEE d \'de\' MMMM',
                    'es',
                  ).format(widget.selectedDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isToday)
                  Text(
                    'Hoy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isFuture ? Colors.grey.shade300 : null,
            ),
            onPressed: () {
              // Verificar si ya estamos en hoy
              final today = DateTime.now();
              final todayStart = DateTime(today.year, today.month, today.day);
              final selectedStart = DateTime(
                widget.selectedDate.year,
                widget.selectedDate.month,
                widget.selectedDate.day,
              );

              // Si ya estás viendo hoy o en el futuro, bloquear
              if (selectedStart.isAtSameMomentAs(todayStart) ||
                  selectedStart.isAfter(todayStart)) {
                return; // No permitir avanzar
              }

              final newDate = widget.selectedDate.add(const Duration(days: 1));
              widget.onDateChanged(newDate);
            },
          ),
        ],
      ),
    );
  }
}
