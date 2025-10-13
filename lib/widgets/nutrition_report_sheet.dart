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
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final Future<List<Map<String, dynamic>>> Function(
    DateTime start,
    DateTime end,
  )?
  getReportsForRange;

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
    this.getReportsForRange,
  });

  @override
  State<NutritionReportSheet> createState() => _NutritionReportSheetState();
}

class _NutritionReportSheetState extends State<NutritionReportSheet> {
  late BuildContext _scaffoldContext;

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

  // Grupos de nutrientes para las páginas del PDF
  static const List<String> page1Nutrients = [
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
  ];

  static const List<String> page2Nutrients = [
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
  ];

  static const List<String> page3Nutrients = [
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
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copiar texto al portapapeles'),
              subtitle: const Text('Para compartir rápido'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _exportTextReport(_scaffoldContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Generar PDF visual'),
              subtitle: const Text('Reporte completo con gráficos (3 páginas)'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _exportPdfReport(_scaffoldContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Exportar a Excel'),
              subtitle: const Text('Múltiples días con tablas dinámicas'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                // Usar el context guardado del scaffold principal
                Future.delayed(const Duration(milliseconds: 300), () {
                  _showDateRangePicker(_scaffoldContext);
                });
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

  // Nueva función: Exportar como PDF visual (3 páginas)
  Future<void> _exportPdfReport(BuildContext context) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy', 'es').format(widget.selectedDate);

    // PÁGINA 1: Macros + Vitaminas A-C
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(dateStr, '1/3'),
              pw.SizedBox(height: 20),
              _buildCaloriesSummary(),
              pw.SizedBox(height: 20),
              _buildSectionTitle('MACRONUTRIENTES'),
              pw.SizedBox(height: 12),
              ..._buildNutrientsList(page1Nutrients.sublist(1, 4)),
              pw.SizedBox(height: 20),
              _buildSectionTitle('FIBRA Y ÁCIDOS GRASOS'),
              pw.SizedBox(height: 12),
              ..._buildNutrientsList(page1Nutrients.sublist(4, 7)),
              pw.SizedBox(height: 20),
              _buildSectionTitle('VITAMINAS (Grupo 1)'),
              pw.SizedBox(height: 12),
              ..._buildNutrientsList(page1Nutrients.sublist(7)),
            ],
          );
        },
      ),
    );

    // PÁGINA 2: Vitaminas E-D + Minerales
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(dateStr, '2/3'),
              pw.SizedBox(height: 20),
              _buildSectionTitle('VITAMINAS (Grupo 2)'),
              pw.SizedBox(height: 12),
              ..._buildNutrientsList(page2Nutrients.sublist(0, 7)),
              pw.SizedBox(height: 20),
              _buildSectionTitle('MINERALES'),
              pw.SizedBox(height: 12),
              ..._buildNutrientsList(page2Nutrients.sublist(7)),
            ],
          );
        },
      ),
    );

    // PÁGINA 3: Aminoácidos Esenciales
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(dateStr, '3/3'),
              pw.SizedBox(height: 20),
              _buildSectionTitle('AMINOÁCIDOS ESENCIALES'),
              pw.SizedBox(height: 8),
              pw.Text(
                'Requerimientos calculados en base a peso corporal: ${widget.userWeight.toStringAsFixed(1)} kg',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 12),
              ..._buildNutrientsList(page3Nutrients),
            ],
          );
        },
      ),
    );

    // Compartir el PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'reporte_nutricional_${DateFormat('dd-MM-yyyy').format(widget.selectedDate)}.pdf',
    );
  }

  // Helper: Header del PDF
  pw.Widget _buildPdfHeader(String dateStr, String pageNumber) {
    return pw.Container(
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
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('AcoFood', style: const pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 4),
              pw.Text(
                'Página $pageNumber',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Resumen de calorías
  pw.Widget _buildCaloriesSummary() {
    return pw.Container(
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
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${widget.report.calories.toStringAsFixed(0)} / ${widget.totalCaloriesGoal.toStringAsFixed(0)} kcal',
            style: const pw.TextStyle(fontSize: 16, color: PdfColors.green800),
          ),
        ],
      ),
    );
  }

  // Helper: Título de sección
  pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.green900,
      ),
    );
  }

  // Helper: Lista de nutrientes para PDF
  List<pw.Widget> _buildNutrientsList(List<String> nutrients) {
    return nutrients.map((key) {
      final value = _getNutrientValue(key);

      Map<String, dynamic>? goalData;
      if (key == 'proteins') {
        goalData = {
          'value': widget.proteinGoalGrams,
          'unit': 'g',
          'type': 'Meta',
        };
      } else if (key == 'carbohydrates') {
        goalData = {
          'value': widget.carbsGoalGrams,
          'unit': 'g',
          'type': 'Meta',
        };
      } else if (key == 'totalFats') {
        goalData = {'value': widget.fatGoalGrams, 'unit': 'g', 'type': 'Meta'};
      } else {
        goalData = nutrientGoals[key];
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
      }

      if (goalData == null) return pw.SizedBox.shrink();

      final name = nutrientNameMapping[key];
      if (name == null) return pw.SizedBox.shrink();

      final goal = goalData['value'] as double;
      final pct = goal > 0 ? ((value / goal) * 100).round() : 0;

      return _buildPdfNutrientRow(name, value, goal, goalData['unit'], pct);
    }).toList();
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
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${_formatValue(value)} / ${_formatValue(goal)} $unit ($percentage%)',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Container(
            height: 6,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Row(
              children: [
                if (progress > 0)
                  pw.Expanded(
                    flex: (progress * 100).round(),
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: barColor,
                        borderRadius: pw.BorderRadius.circular(3),
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

  // Mostrar selector de rango de fechas
  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: widget.selectedDate.subtract(const Duration(days: 6)),
        end: widget.selectedDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      await _exportExcelReport(context, picked.start, picked.end);
    }
  }

  // 🔧 REEMPLAZA la función _exportExcelReport completa (desde línea 679 hasta 951)
  // en nutrition_report_sheet.dart con este código:

  Future<void> _exportExcelReport(
    BuildContext context,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (widget.getReportsForRange == null) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Función no disponible'),
            content: const Text(
              'La exportación a Excel requiere que se proporcione la función '
              'getReportsForRange al widget. Por favor contacta al desarrollador.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
      return;
    }

    bool loadingShown = false;
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      loadingShown = true;
    }

    try {
      final reports = await widget.getReportsForRange!(startDate, endDate);

      if (reports.isEmpty) {
        if (context.mounted && loadingShown) {
          Navigator.pop(context);
          loadingShown = false;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No hay datos en el rango seleccionado'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final excel = Excel.createExcel();

      // ========================================
      // HOJA 1: Resumen Diario (formato ancho simplificado)
      // ========================================
      final summarySheet = excel['Resumen Diario'];
      excel.setDefaultSheet('Resumen Diario');

      summarySheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        'Fecha',
      );
      summarySheet.cell(CellIndex.indexByString('B1')).value = TextCellValue(
        'Calorías',
      );
      summarySheet.cell(CellIndex.indexByString('C1')).value = TextCellValue(
        'Proteínas (g)',
      );
      summarySheet.cell(CellIndex.indexByString('D1')).value = TextCellValue(
        'Carbohidratos (g)',
      );
      summarySheet.cell(CellIndex.indexByString('E1')).value = TextCellValue(
        'Grasas (g)',
      );
      summarySheet.cell(CellIndex.indexByString('F1')).value = TextCellValue(
        'Fibra (g)',
      );
      summarySheet.cell(CellIndex.indexByString('G1')).value = TextCellValue(
        'Omega-3 (g)',
      );
      summarySheet.cell(CellIndex.indexByString('H1')).value = TextCellValue(
        'Omega-6 (g)',
      );
      summarySheet.cell(CellIndex.indexByString('I1')).value = TextCellValue(
        'Vit A (µg)',
      );
      summarySheet.cell(CellIndex.indexByString('J1')).value = TextCellValue(
        'Vit C (mg)',
      );
      summarySheet.cell(CellIndex.indexByString('K1')).value = TextCellValue(
        'Vit D (µg)',
      );
      summarySheet.cell(CellIndex.indexByString('L1')).value = TextCellValue(
        'Calcio (mg)',
      );
      summarySheet.cell(CellIndex.indexByString('M1')).value = TextCellValue(
        'Hierro (mg)',
      );
      summarySheet.cell(CellIndex.indexByString('N1')).value = TextCellValue(
        '% Calorías',
      );
      summarySheet.cell(CellIndex.indexByString('O1')).value = TextCellValue(
        '% Proteínas',
      );
      summarySheet.cell(CellIndex.indexByString('P1')).value = TextCellValue(
        '% Carbos',
      );
      summarySheet.cell(CellIndex.indexByString('Q1')).value = TextCellValue(
        '% Grasas',
      );

      int row = 2;
      for (final report in reports) {
        final date = report['date'] as DateTime;
        final nutritionReport = report['report'] as NutritionReport;

        summarySheet.cell(CellIndex.indexByString('A$row')).value =
            TextCellValue(DateFormat('dd/MM/yyyy').format(date));
        summarySheet.cell(CellIndex.indexByString('B$row')).value =
            DoubleCellValue(nutritionReport.calories);
        summarySheet.cell(CellIndex.indexByString('C$row')).value =
            DoubleCellValue(nutritionReport.proteins);
        summarySheet.cell(CellIndex.indexByString('D$row')).value =
            DoubleCellValue(nutritionReport.carbohydrates);
        summarySheet.cell(CellIndex.indexByString('E$row')).value =
            DoubleCellValue(nutritionReport.totalFats);
        summarySheet.cell(CellIndex.indexByString('F$row')).value =
            DoubleCellValue(nutritionReport.fiber);
        summarySheet.cell(CellIndex.indexByString('G$row')).value =
            DoubleCellValue(nutritionReport.omega3);
        summarySheet.cell(CellIndex.indexByString('H$row')).value =
            DoubleCellValue(nutritionReport.omega6);
        summarySheet.cell(CellIndex.indexByString('I$row')).value =
            DoubleCellValue(nutritionReport.vitaminA);
        summarySheet.cell(CellIndex.indexByString('J$row')).value =
            DoubleCellValue(nutritionReport.vitaminC);
        summarySheet.cell(CellIndex.indexByString('K$row')).value =
            DoubleCellValue(nutritionReport.vitaminD);
        summarySheet.cell(CellIndex.indexByString('L$row')).value =
            DoubleCellValue(nutritionReport.calcium);
        summarySheet.cell(CellIndex.indexByString('M$row')).value =
            DoubleCellValue(nutritionReport.iron);

        final calPct = widget.totalCaloriesGoal > 0
            ? (nutritionReport.calories / widget.totalCaloriesGoal) * 100
            : 0.0;
        final protPct = widget.proteinGoalGrams > 0
            ? (nutritionReport.proteins / widget.proteinGoalGrams) * 100
            : 0.0;
        final carbPct = widget.carbsGoalGrams > 0
            ? (nutritionReport.carbohydrates / widget.carbsGoalGrams) * 100
            : 0.0;
        final fatPct = widget.fatGoalGrams > 0
            ? (nutritionReport.totalFats / widget.fatGoalGrams) * 100
            : 0.0;

        summarySheet.cell(CellIndex.indexByString('N$row')).value =
            DoubleCellValue(calPct);
        summarySheet.cell(CellIndex.indexByString('O$row')).value =
            DoubleCellValue(protPct);
        summarySheet.cell(CellIndex.indexByString('P$row')).value =
            DoubleCellValue(carbPct);
        summarySheet.cell(CellIndex.indexByString('Q$row')).value =
            DoubleCellValue(fatPct);

        row++;
      }

      // ========================================
      // HOJA 2: Datos Completos (formato largo para Pivot Tables)
      // ========================================
      final detailSheet = excel['Datos Completos'];

      detailSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        'Fecha',
      );
      detailSheet.cell(CellIndex.indexByString('B1')).value = TextCellValue(
        'Nutriente',
      );
      detailSheet.cell(CellIndex.indexByString('C1')).value = TextCellValue(
        'Valor',
      );
      detailSheet.cell(CellIndex.indexByString('D1')).value = TextCellValue(
        'Unidad',
      );
      detailSheet.cell(CellIndex.indexByString('E1')).value = TextCellValue(
        'Meta',
      );
      detailSheet.cell(CellIndex.indexByString('F1')).value = TextCellValue(
        'Porcentaje',
      );
      detailSheet.cell(CellIndex.indexByString('G1')).value = TextCellValue(
        'Categoría',
      );

      int detailRow = 2;
      for (final report in reports) {
        final date = report['date'] as DateTime;
        final nutritionReport = report['report'] as NutritionReport;
        final dateStr = DateFormat('dd/MM/yyyy').format(date);

        for (final nutrientKey in nutrientOrder) {
          final value = _getNutrientValueFromReport(
            nutritionReport,
            nutrientKey,
          );

          double goal = 0;
          String unit = '';
          String category = '';

          if (nutrientKey == 'calories') {
            goal = widget.totalCaloriesGoal;
            unit = 'kcal';
            category = 'Macronutrientes';
          } else if (nutrientKey == 'proteins') {
            goal = widget.proteinGoalGrams;
            unit = 'g';
            category = 'Macronutrientes';
          } else if (nutrientKey == 'carbohydrates') {
            goal = widget.carbsGoalGrams;
            unit = 'g';
            category = 'Macronutrientes';
          } else if (nutrientKey == 'totalFats') {
            goal = widget.fatGoalGrams;
            unit = 'g';
            category = 'Macronutrientes';
          } else {
            final goalData = nutrientGoals[nutrientKey];
            if (goalData != null) {
              goal = goalData['value'] as double;
              unit = goalData['unit'] as String;

              if (unit == 'mg/kg/day') {
                final totalMg = goal * widget.userWeight;
                goal = totalMg / 1000;
                unit = 'g';
              }

              if (nutrientKey.startsWith('vitamin')) {
                category = 'Vitaminas';
              } else if ([
                'histidine',
                'isoleucine',
                'leucine',
                'lysine',
                'methionine',
                'phenylalanine',
                'threonine',
                'tryptophan',
                'valine',
              ].contains(nutrientKey)) {
                category = 'Aminoácidos';
              } else if (['fiber', 'omega3', 'omega6'].contains(nutrientKey)) {
                category = 'Fibra y Ácidos Grasos';
              } else {
                category = 'Minerales';
              }
            }
          }

          final percentage = goal > 0 ? (value / goal) * 100 : 0.0;
          final name = nutrientNameMapping[nutrientKey] ?? nutrientKey;

          detailSheet.cell(CellIndex.indexByString('A$detailRow')).value =
              TextCellValue(dateStr);
          detailSheet.cell(CellIndex.indexByString('B$detailRow')).value =
              TextCellValue(name);
          detailSheet.cell(CellIndex.indexByString('C$detailRow')).value =
              DoubleCellValue(value);
          detailSheet.cell(CellIndex.indexByString('D$detailRow')).value =
              TextCellValue(unit);
          detailSheet.cell(CellIndex.indexByString('E$detailRow')).value =
              DoubleCellValue(goal);
          detailSheet.cell(CellIndex.indexByString('F$detailRow')).value =
              DoubleCellValue(percentage);
          detailSheet.cell(CellIndex.indexByString('G$detailRow')).value =
              TextCellValue(category);

          detailRow++;
        }
      }

      // ========================================
      // ⭐ HOJA 3: Análisis por Día (NUEVA - formato ultra ancho)
      // ========================================
      final analysisSheet = excel['Análisis por Día'];

      // Headers - Triples por nutriente importante (Valor, Meta/RDA/AI, %)
      int col = 0;
      analysisSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0))
          .value = TextCellValue(
        'Fecha',
      );

      // Lista de nutrientes clave para análisis
      final keyNutrients = [
        'calories',
        'proteins',
        'carbohydrates',
        'totalFats',
        'fiber',
        'omega3',
        'omega6',
        'calcium',
        'iron',
        'magnesium',
        'zinc',
        'vitaminA',
        'vitaminB1',
        'vitaminB2',
        'vitaminB3',
        'vitaminB6',
        'vitaminB9',
        'vitaminB12',
        'vitaminC',
        'vitaminD',
        'vitaminE',
        'vitaminK',
      ];

      for (final nutrientKey in keyNutrients) {
        final name = nutrientNameMapping[nutrientKey] ?? nutrientKey;

        // Determinar si es Meta, RDA o AI
        String goalType = 'Meta';
        if (![
          'calories',
          'proteins',
          'carbohydrates',
          'totalFats',
        ].contains(nutrientKey)) {
          final goalData = nutrientGoals[nutrientKey];
          if (goalData != null) {
            goalType = goalData['type'] as String;
          }
        }

        // Columna 1: Valor
        analysisSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0))
            .value = TextCellValue(
          name,
        );

        // Columna 2: Meta/RDA/AI
        analysisSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0))
            .value = TextCellValue(
          '$name $goalType',
        );

        // Columna 3: Porcentaje
        analysisSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0))
            .value = TextCellValue(
          '$name %',
        );
      }

      // Datos por día
      int analysisRow = 1;
      for (final report in reports) {
        final date = report['date'] as DateTime;
        final nutritionReport = report['report'] as NutritionReport;

        int analysisCol = 0;

        // Fecha
        analysisSheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: analysisCol++,
                rowIndex: analysisRow,
              ),
            )
            .value = TextCellValue(
          DateFormat('dd/MM/yyyy').format(date),
        );

        // Cada nutriente: Valor, Meta/RDA/AI, %
        for (final nutrientKey in keyNutrients) {
          final value = _getNutrientValueFromReport(
            nutritionReport,
            nutrientKey,
          );

          double goal = 0;

          if (nutrientKey == 'calories') {
            goal = widget.totalCaloriesGoal;
          } else if (nutrientKey == 'proteins') {
            goal = widget.proteinGoalGrams;
          } else if (nutrientKey == 'carbohydrates') {
            goal = widget.carbsGoalGrams;
          } else if (nutrientKey == 'totalFats') {
            goal = widget.fatGoalGrams;
          } else {
            final goalData = nutrientGoals[nutrientKey];
            if (goalData != null) {
              goal = goalData['value'] as double;
              final unit = goalData['unit'] as String;

              if (unit == 'mg/kg/day') {
                final totalMg = goal * widget.userWeight;
                goal = totalMg / 1000;
              }
            }
          }

          final percentage = goal > 0 ? (value / goal) * 100 : 0.0;

          // Valor
          analysisSheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: analysisCol++,
                  rowIndex: analysisRow,
                ),
              )
              .value = DoubleCellValue(
            value,
          );

          // Meta/RDA/AI
          analysisSheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: analysisCol++,
                  rowIndex: analysisRow,
                ),
              )
              .value = DoubleCellValue(
            goal,
          );

          // Porcentaje
          analysisSheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: analysisCol++,
                  rowIndex: analysisRow,
                ),
              )
              .value = DoubleCellValue(
            percentage,
          );
        }

        analysisRow++;
      }

      // ========================================
      // ⭐ HOJA 4: % Distribución Macros (para gráfico de áreas apiladas)
      // ========================================
      final percentSheet = excel['% Distribución Macros'];

      // Headers
      percentSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        'Fecha',
      );
      percentSheet.cell(CellIndex.indexByString('B1')).value = TextCellValue(
        '% Proteínas',
      );
      percentSheet.cell(CellIndex.indexByString('C1')).value = TextCellValue(
        '% Carbohidratos',
      );
      percentSheet.cell(CellIndex.indexByString('D1')).value = TextCellValue(
        '% Grasas',
      );

      // Datos
      int percentRow = 2;
      for (final report in reports) {
        final date = report['date'] as DateTime;
        final nutritionReport = report['report'] as NutritionReport;

        // Calcular % de calorías de cada macro
        final proteinCals = nutritionReport.proteins * 4; // 4 cal/g
        final carbsCals = nutritionReport.carbohydrates * 4; // 4 cal/g
        final fatCals = nutritionReport.totalFats * 9; // 9 cal/g
        final totalCals = proteinCals + carbsCals + fatCals;

        double proteinPercent = 0;
        double carbsPercent = 0;
        double fatPercent = 0;

        if (totalCals > 0) {
          proteinPercent = (proteinCals / totalCals) * 100;
          carbsPercent = (carbsCals / totalCals) * 100;
          fatPercent = (fatCals / totalCals) * 100;
        }

        // Escribir datos
        percentSheet.cell(CellIndex.indexByString('A$percentRow')).value =
            TextCellValue(DateFormat('dd/MM/yyyy').format(date));
        percentSheet.cell(CellIndex.indexByString('B$percentRow')).value =
            DoubleCellValue(proteinPercent);
        percentSheet.cell(CellIndex.indexByString('C$percentRow')).value =
            DoubleCellValue(carbsPercent);
        percentSheet.cell(CellIndex.indexByString('D$percentRow')).value =
            DoubleCellValue(fatPercent);

        percentRow++;
      }

      // 🗑️ Eliminar hoja Sheet1 vacía (si existe)
      try {
        excel.delete('Sheet1');
      } catch (e) {
        print('Sheet1 no encontrada: $e');
      }

      // Guardar archivo
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Error al generar Excel');

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/reporte_nutricional_${DateFormat('dd-MM-yyyy').format(startDate)}_a_${DateFormat('dd-MM-yyyy').format(endDate)}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (context.mounted && loadingShown) {
        Navigator.pop(context);
        loadingShown = false;
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text:
            'Reporte Nutricional ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Excel generado exitosamente (4 hojas)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted && loadingShown) {
        Navigator.pop(context);
        loadingShown = false;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al generar Excel: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  double _getNutrientValueFromReport(NutritionReport report, String key) {
    switch (key) {
      case 'calories':
        return report.calories;
      case 'proteins':
        return report.proteins;
      case 'carbohydrates':
        return report.carbohydrates;
      case 'totalFats':
        return report.totalFats;
      case 'fiber':
        return report.fiber;
      case 'omega3':
        return report.omega3;
      case 'omega6':
        return report.omega6;
      case 'calcium':
        return report.calcium;
      case 'iron':
        return report.iron;
      case 'magnesium':
        return report.magnesium;
      case 'phosphorus':
        return report.phosphorus;
      case 'potassium':
        return report.potassium;
      case 'sodium':
        return report.sodium;
      case 'zinc':
        return report.zinc;
      case 'copper':
        return report.copper;
      case 'manganese':
        return report.manganese;
      case 'selenium':
        return report.selenium;
      case 'vitaminA':
        return report.vitaminA;
      case 'vitaminC':
        return report.vitaminC;
      case 'vitaminE':
        return report.vitaminE;
      case 'vitaminK':
        return report.vitaminK;
      case 'vitaminB1':
        return report.vitaminB1;
      case 'vitaminB2':
        return report.vitaminB2;
      case 'vitaminB3':
        return report.vitaminB3;
      case 'vitaminB4':
        return report.vitaminB4;
      case 'vitaminB5':
        return report.vitaminB5;
      case 'vitaminB6':
        return report.vitaminB6;
      case 'vitaminB7':
        return report.vitaminB7;
      case 'vitaminB9':
        return report.vitaminB9;
      case 'vitaminB12':
        return report.vitaminB12;
      case 'vitaminD':
        return report.vitaminD;
      case 'iodine':
        return report.iodine;
      case 'histidine':
        return report.histidine;
      case 'isoleucine':
        return report.isoleucine;
      case 'leucine':
        return report.leucine;
      case 'lysine':
        return report.lysine;
      case 'methionine':
        return report.methionine;
      case 'phenylalanine':
        return report.phenylalanine;
      case 'threonine':
        return report.threonine;
      case 'tryptophan':
        return report.tryptophan;
      case 'valine':
        return report.valine;
      default:
        return 0.0;
    }
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
    // Guardar el context para usarlo en callbacks asíncronos
    _scaffoldContext = context;

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
                    onPressed: () => _showExportMenu(_scaffoldContext),
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
    return _getNutrientValueFromReport(widget.report, key);
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
