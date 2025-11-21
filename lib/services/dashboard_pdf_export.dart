import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/dashboard_stats.dart';
import '../models/dashboard_preferences.dart';
import '../models/user_profile.dart';
import '../utils/nutrients_helper.dart';

enum DashboardPdfStyle { minimal, classic }

class DashboardPdfExport {
  static Future<Uint8List> generateDashboardPdf({
    required DashboardStats stats,
    required DashboardPreferences prefs,
    required String periodKey,
    required DateTime startDate,
    required DateTime endDate,
    UserProfile? user,
    DashboardPdfStyle style = DashboardPdfStyle.minimal,
  }) async {
    final pdf = pw.Document();

    final periodText = _periodText(periodKey);
    final dateRange =
        '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}';

    // Metadatos del documento PDF (compatibles con pdf 3.11.x)
    try {
      pdf.document.info = PdfInfo(
        pdf.document,
        title: 'AcoFood • Dashboard $periodText',
        author: 'AcoFood',
        subject: 'Dashboard $periodText — $dateRange',
        creator: 'AcoFood',
        producer: 'dart_pdf',
      );
    } catch (_) {
      // Ignorar silenciosamente si la API difiere.
    }

    // Excluir hoy
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filteredData =
        stats.dailyData
            .where(
              (d) => DateTime(
                d.date.year,
                d.date.month,
                d.date.day,
              ).isBefore(today),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final averages = _computeAverages(filteredData);
    final isClassic = prefs.reportStyle == 'classic';
    final isA4 = (prefs.pageFormat.toLowerCase() == 'a4');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: isA4 ? PdfPageFormat.a4 : PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(20),
        header: (context) =>
            _buildHeader(periodText, dateRange, includePeriod: isClassic),
        footer: (context) => _buildFooter(context),
        build: (context) {
          final dailyHeaders = <String>[
            'Fecha',
            'Calorías',
            'Proteínas',
            'Carbos',
            'Grasas',
          ];
          final dailyRows = filteredData
              .map(
                (day) => [
                  DateFormat('dd/MM/yyyy').format(day.date),
                  '${day.calories.toStringAsFixed(0)} kcal',
                  '${day.protein.toStringAsFixed(1)} g',
                  '${day.carbs.toStringAsFixed(1)} g',
                  '${day.fat.toStringAsFixed(1)} g',
                ],
              )
              .toList();

          final widgets = <pw.Widget>[
            pw.Text(
              'Promedio diario',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroItem(
                    'Calorías',
                    averages['calories']!.toStringAsFixed(0),
                    'kcal',
                    PdfColors.orange,
                  ),
                  _buildMacroItem(
                    'Proteínas',
                    averages['protein']!.toStringAsFixed(1),
                    'g',
                    PdfColors.red,
                  ),
                  _buildMacroItem(
                    'Carbos',
                    averages['carbs']!.toStringAsFixed(1),
                    'g',
                    PdfColors.blue,
                  ),
                  _buildMacroItem(
                    'Grasas',
                    averages['fat']!.toStringAsFixed(1),
                    'g',
                    PdfColors.green,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            pw.Text(
              'Top 5 alimentos',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: stats.topFoods.take(5).map((food) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          food.fullName ?? food.name,
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          '${food.timesConsumed}x',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            pw.SizedBox(height: 24),
          ];

          if (stats.topFoodsByWeight.isNotEmpty) {
            widgets.addAll([
              pw.Text(
                'Top 5 alimentos (por peso)',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: stats.topFoodsByWeight.take(5).map((food) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            food.fullName ?? food.name,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.Text(
                            '${food.totalGrams.toStringAsFixed(0)} g',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              pw.SizedBox(height: 24),
            ]);
          }

          if (prefs.exportDailyData && dailyRows.isNotEmpty) {
            widgets.addAll([
              pw.Text(
                'Datos diarios',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              if (prefs.tableZebra)
                _buildZebraTable(
                  headers: dailyHeaders,
                  rows: dailyRows,
                  cellAlignments: const {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: dailyHeaders,
                  data: dailyRows,
                  headerCount: 1,
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignments: const {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                ),
            ]);
          }

          if (stats.habitCompletion.isNotEmpty) {
            final totalDays = filteredData.length;
            final habitHeaders = <String>['Hábito', 'Completado'];
            final habitRows = stats.habitCompletion.entries
                .map(
                  (e) => [
                    e.key,
                    '${e.value}/$totalDays días (${(e.value / totalDays * 100).toStringAsFixed(0)}%)',
                  ],
                )
                .toList();

            if (prefs.habitsPageMode == 'always' ||
                (prefs.habitsPageMode == '30days' && periodKey == '30days')) {
              widgets.add(pw.NewPage());
            }

            widgets.addAll([
              pw.SizedBox(height: 24),
              pw.Text(
                'Hábitos completados',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              if (prefs.tableZebra)
                _buildZebraTable(
                  headers: habitHeaders,
                  rows: habitRows,
                  cellAlignments: const {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                  },
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: habitHeaders,
                  data: habitRows,
                  headerCount: 1,
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignments: const {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                  },
                ),
            ]);
          }

          return widgets;
        },
      ),
    );

    // Pagina de Nutrientes (separada para paginacion)
    if (prefs.exportNutrientsAnalysis && stats.dailyData.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: isA4 ? PdfPageFormat.a4 : PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(20),
          header: (context) =>
              _buildHeader(periodText, dateRange, includePeriod: isClassic),
          footer: (context) => _buildFooter(context),
          build: (context) {
            final nutrientsData = _computeNutrientsAverages(stats, user);
            if (prefs.nutrientsExportMode == 'avg_bars') {
              return [
                pw.Text(
                  'Analisis de nutrientes (promedio del periodo)',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildNutrientBars(nutrientsData),
              ];
            }
            final headers = <String>[
              'Nutriente',
              'Promedio',
              'Meta/Límite',
              '%',
            ];
            final rows = nutrientsData.map((n) {
              final name = n['name'] as String;
              final avgVal = (n['avg'] as double);
              final unit = n['unit'] as String;
              final hasRDA = n['hasRDA'] as bool;
              final key = n['key'] as String;
              String goalStr = 'N/A';
              String percStr = 'N/A';
              if (hasRDA) {
                final goalVal = n['goal'] as double;
                final formattedGoal = _fmtNum(goalVal);
                goalStr = '$formattedGoal $unit';
                percStr = '${(n['percentage'] as double).toStringAsFixed(0)}%';
              }
              return <String>[
                name,
                '${_fmtNum(avgVal)} $unit',
                goalStr,
                percStr,
              ];
            }).toList();

            return [
              pw.Text(
                'Analisis de nutrientes',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              if (prefs.tableZebra)
                _buildZebraTable(
                  headers: headers,
                  rows: rows,
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(1),
                  },
                  cellAlignments: const {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  data: rows,
                  headerCount: 1,
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(1),
                  },
                  cellAlignments: const {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                ),
            ];
          },
        ),
      );
    }

    return pdf.save();
  }

  // Helpers
  static String _periodText(String key) {
    switch (key) {
      case '7days':
        return '7 días';
      case '30days':
        return '30 días';
      case '90days':
        return '90 días';
      default:
        return '7 días';
    }
  }

  static Map<String, double> _computeAverages(List<dynamic> filteredData) {
    if (filteredData.isEmpty) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }
    double totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0;
    for (var day in filteredData) {
      totalCalories += day.calories;
      totalProtein += day.protein;
      totalCarbs += day.carbs;
      totalFat += day.fat;
    }
    final count = filteredData.length.toDouble();
    return {
      'calories': totalCalories / count,
      'protein': totalProtein / count,
      'carbs': totalCarbs / count,
      'fat': totalFat / count,
    };
  }

  static List<Map<String, dynamic>> _computeNutrientsAverages(
    DashboardStats stats,
    UserProfile? user,
  ) {
    final results = <Map<String, dynamic>>[];
    final days = stats.dailyData;
    final count = days.isNotEmpty ? days.length : 1;

    for (final nutrient in availableNutrients) {
      double total = 0;
      for (final d in days) {
        total += d.nutrients[nutrient.key] ?? 0;
      }
      final avg = total / count;

      double goal = nutrient.rdaValue;
      String unit = nutrient.unit;
      if (unit == 'mg/kg/day') {
        final weight = user?.weight ?? 70.0;
        // Convert to grams/day for display
        goal = (goal * weight) / 1000.0;
        unit = 'g';
      }

      final hasRDA = nutrient.rdaValue > 0;
      final percentage = hasRDA && goal > 0 ? (avg / goal) * 100.0 : 0.0;

      results.add({
        'key': nutrient.key,
        'name': nutrient.displayName,
        'unit': unit,
        'avg': avg,
        'goal': goal,
        'hasRDA': hasRDA,
        'percentage': percentage,
      });
    }

    return results;
  }

  static String _fmtNum(double v) {
    if (v.isNaN || v.isInfinite) return '0';
    final absV = v.abs();
    final decimals = (absV >= 100 || v % 1 == 0) ? 0 : 1;
    return v.toStringAsFixed(decimals);
  }

  static pw.Widget _buildHeader(
    String periodText,
    String dateRange, {
    bool includePeriod = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Dashboard',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.orange,
          ),
        ),
        pw.Text(includePeriod ? '$periodText - $dateRange' : ' '),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  static pw.Widget _buildMacroItem(
    String label,
    String value,
    String unit,
    PdfColor color,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(
          unit,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static pw.Widget _buildNutrientBars(
    List<Map<String, dynamic>> nutrientsData,
  ) {
    final items = <pw.Widget>[];
    for (final n in nutrientsData) {
      final name = n['name'] as String;
      final avgVal = (n['avg'] as double);
      final unit = n['unit'] as String;
      final hasRDA = n['hasRDA'] as bool;
      final percentage = (n['percentage'] as double);
      final perc = percentage.isFinite ? percentage : 0.0;
      final cap = perc.clamp(0, 200);

      items.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      name,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Text(
                    hasRDA
                        ? '${_fmtNum(avgVal)} $unit · ${perc.toStringAsFixed(0)}%'
                        : '${_fmtNum(avgVal)} $unit',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.LayoutBuilder(
                builder: (context, constraints) {
                  final totalW = constraints!.maxWidth;
                  final filledW = totalW * (cap / 100.0);
                  return pw.Stack(
                    children: [
                      pw.Container(
                        width: totalW,
                        height: 8,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey300,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                      pw.Container(
                        width: filledW,
                        height: 8,
                        decoration: pw.BoxDecoration(
                          color: cap >= 100 ? PdfColors.green : PdfColors.blue,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
    return pw.Column(children: items);
  }

  static pw.Widget _buildZebraTable({
    required List<String> headers,
    required List<List<String>> rows,
    Map<int, pw.TableColumnWidth>? columnWidths,
    Map<int, pw.Alignment>? cellAlignments,
  }) {
    final headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    const cellStyle = pw.TextStyle(fontSize: 9);

    pw.Widget cell(String text, {int columnIndex = 0, bool isHeader = false}) {
      final align =
          cellAlignments != null && cellAlignments.containsKey(columnIndex)
          ? cellAlignments[columnIndex]!
          : pw.Alignment.centerLeft;
      return pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, style: isHeader ? headerStyle : cellStyle),
      );
    }

    final tableRows = <pw.TableRow>[];
    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          for (var i = 0; i < headers.length; i++)
            cell(headers[i], columnIndex: i, isHeader: true),
        ],
      ),
    );
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      tableRows.add(
        pw.TableRow(
          decoration: r % 2 == 1
              ? const pw.BoxDecoration(color: PdfColors.grey100)
              : null,
          children: [
            for (var i = 0; i < row.length; i++) cell(row[i], columnIndex: i),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: columnWidths,
      children: tableRows,
    );
  }
}
