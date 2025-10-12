// En: lib/widgets/nutrition_report_sheet.dart

import 'package:flutter/material.dart';
import '../models/nutrition_report.dart';
import '../data/nutrient_goals.dart';
import 'nutrient_progress_row.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const Map<String, String> nutrientNameMapping = {
  'calories': "Calorías",
  'proteins': "Proteínas",
  'carbohydrates': "Carbohidratos",
  'totalFats': "Grasas Totales",
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
  'vitaminB12': 'Vitamina B12',
  'vitaminD': 'Vitamina D',
  'iodine': 'Yodo',
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
    this.userWeight = 70.0,
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

  // Mostrar menú para elegir tipo de exportación
  void _showExportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copiar texto al portapapeles'),
              subtitle: const Text('Para compartir rápido'),
              onTap: () {
                Navigator.pop(context);
                _exportTextReport(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Generar PDF visual'),
              subtitle: const Text('Reporte completo con gráficos'),
              onTap: () {
                Navigator.pop(context);
                _exportPdfReport(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Exportar como texto (función original mejorada)
  Future<void> _exportTextReport(BuildContext context) async {
    final dateStr = DateFormat('dd/MM/yyyy', 'es').format(widget.selectedDate);
    final buffer = StringBuffer();

    buffer.writeln('📊 Reporte Nutricional - $dateStr\n');
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

    buffer.writeln('═══ NUTRIENTES ═══');
    for (final nutrientKey in nutrientOrder) {
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

    // Convertir aminoácidos de mg/kg/day a gramos totales
    double adjustedGoal = goal;
    String adjustedUnit = unit;

    if (unit == 'mg/kg/day') {
      final totalMg = goal * widget.userWeight;
      adjustedGoal = totalMg / 1000; // convertir mg a g
      adjustedUnit = 'g';
    }

    final percentage = adjustedGoal > 0
        ? ((value / adjustedGoal) * 100).toStringAsFixed(0)
        : '0';

    // Formatear valores según el tamaño
    String formattedValue = value < 10
        ? value.toStringAsFixed(2)
        : value.toStringAsFixed(0);
    String formattedGoal = adjustedGoal < 10
        ? adjustedGoal.toStringAsFixed(2)
        : adjustedGoal.toStringAsFixed(0);

    buffer.writeln(
      '$name: $formattedValue / $formattedGoal $adjustedUnit ($type) - $percentage%',
    );
  }

  // Nueva función: Exportar como PDF visual
  Future<void> _exportPdfReport(BuildContext context) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy', 'es').format(widget.selectedDate);

    // Calcular porcentajes de macros
    final proteinPct = widget.proteinGoalGrams > 0
        ? ((widget.report.proteins / widget.proteinGoalGrams) * 100).round()
        : 0;
    final carbsPct = widget.carbsGoalGrams > 0
        ? ((widget.report.carbohydrates / widget.carbsGoalGrams) * 100).round()
        : 0;
    final fatsPct = widget.fatGoalGrams > 0
        ? ((widget.report.totalFats / widget.fatGoalGrams) * 100).round()
        : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 2, color: PdfColors.green700),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Reporte Nutricional',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        dateStr,
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Text('🥑', style: const pw.TextStyle(fontSize: 40)),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Resumen de calorías
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Calorías',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${widget.report.calories.toStringAsFixed(0)} / ${widget.totalCaloriesGoal.toStringAsFixed(0)} kcal',
                    style: const pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.green800,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Macronutrientes
            pw.Text(
              'MACRONUTRIENTES',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green900,
              ),
            ),
            pw.SizedBox(height: 12),

            _buildPdfNutrientRow(
              'Proteínas',
              widget.report.proteins,
              widget.proteinGoalGrams,
              'g',
              proteinPct,
            ),
            _buildPdfNutrientRow(
              'Carbohidratos',
              widget.report.carbohydrates,
              widget.carbsGoalGrams,
              'g',
              carbsPct,
            ),
            _buildPdfNutrientRow(
              'Grasas',
              widget.report.totalFats,
              widget.fatGoalGrams,
              'g',
              fatsPct,
            ),

            pw.SizedBox(height: 20),

            // Otros nutrientes importantes
            pw.Text(
              'NUTRIENTES PRINCIPALES',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green900,
              ),
            ),
            pw.SizedBox(height: 12),

            // Lista de nutrientes con valores > 0
            ...nutrientOrder
                .skip(4) // Saltar los 4 primeros (macros)
                .map((key) {
                  final value = _getNutrientValue(key);
                  if (value <= 0 &&
                      ![
                        'omega3',
                        'omega6',
                        'vitaminB12',
                        'vitaminD',
                      ].contains(key)) {
                    return pw.SizedBox.shrink();
                  }

                  Map<String, dynamic>? goalData = nutrientGoals[key];

                  if (goalData != null && goalData['unit'] == 'mg/kg/day') {
                    final mgPerKg = goalData['value'] as double;
                    final totalMg = mgPerKg * widget.userWeight;
                    final totalGrams = totalMg / 1000;
                    goalData = {
                      'value': totalGrams,
                      'unit': 'g',
                      'type': goalData['type'],
                    };
                  }

                  if (goalData == null) return pw.SizedBox.shrink();

                  const nutrientNames = {
                    'fiber': 'Fibra',
                    'omega3': 'Omega-3',
                    'omega6': 'Omega-6',
                    'vitaminA': 'Vitamina A',
                    'vitaminC': 'Vitamina C',
                    'vitaminB12': 'Vitamina B12',
                    'vitaminD': 'Vitamina D',
                    'calcium': 'Calcio',
                    'iron': 'Hierro',
                    'magnesium': 'Magnesio',
                    'zinc': 'Zinc',
                    'iodine': 'Yodo',
                  };

                  final name = nutrientNames[key];
                  if (name == null) return pw.SizedBox.shrink();

                  final goal = goalData['value'] as double;
                  final pct = goal > 0 ? ((value / goal) * 100).round() : 0;

                  return _buildPdfNutrientRow(
                    name,
                    value,
                    goal,
                    goalData['unit'],
                    pct,
                  );
                })
                .toList(),

            pw.SizedBox(height: 20),

            // Footer
            pw.Divider(color: PdfColors.green700),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Generado por AcoFood 🌱',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Compartir el PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'reporte_nutricional_$dateStr.pdf',
    );
  }

  // Helper para construir filas de nutrientes en PDF
  pw.Widget _buildPdfNutrientRow(
    String name,
    double value,
    double goal,
    String unit,
    int percentage,
  ) {
    final progress = (goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0);

    // Determinar color
    PdfColor barColor;
    if (percentage >= 90) {
      barColor = PdfColors.green;
    } else if (percentage >= 50) {
      barColor = PdfColors.orange;
    } else {
      barColor = PdfColors.red;
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${_formatValue(value)} / ${_formatValue(goal)} $unit ($percentage%)',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          // Barra de progreso usando Row con Expanded
          pw.Container(
            height: 8,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: (progress * 100).round(),
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      color: barColor,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (progress < 1.0)
                  pw.Expanded(
                    flex: ((1 - progress) * 100).round(),
                    child: pw.Container(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double val) {
    if (val < 1.0) {
      return val.toStringAsFixed(2);
    } else {
      return val.toStringAsFixed(1);
    }
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
              final newDate = widget.selectedDate.subtract(
                const Duration(days: 1),
              );
              widget.onDateChanged(newDate);
            } else if (details.primaryVelocity! < 0) {
              final today = DateTime.now();
              final todayStart = DateTime(today.year, today.month, today.day);
              final selectedStart = DateTime(
                widget.selectedDate.year,
                widget.selectedDate.month,
                widget.selectedDate.day,
              );

              if (selectedStart.isAtSameMomentAs(todayStart) ||
                  selectedStart.isAfter(todayStart)) {
                return;
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
                // Botón de exportar con menú
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Exportar Reporte'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: () => _showExportMenu(context),
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

      if (goalData != null && goalData['unit'] == 'mg/kg/day') {
        final mgPerKg = goalData['value'] as double;
        final totalMg = mgPerKg * widget.userWeight;
        final totalGrams = totalMg / 1000;

        goalData = {'value': totalGrams, 'unit': 'g', 'type': goalData['type']};
      }
    }

    if (goalData == null) return null;

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
              final today = DateTime.now();
              final todayStart = DateTime(today.year, today.month, today.day);
              final selectedStart = DateTime(
                widget.selectedDate.year,
                widget.selectedDate.month,
                widget.selectedDate.day,
              );

              if (selectedStart.isAtSameMomentAs(todayStart) ||
                  selectedStart.isAfter(todayStart)) {
                return;
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
