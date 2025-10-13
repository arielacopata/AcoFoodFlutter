import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPeriod = '7days';
  String _selectedMacro = 'calories';
  String _topFoodsSort = 'times'; // Nuevo estado
  DashboardStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // 🔧 FIX: Pedir 1 día extra al backend para compensar el filtro de HOY

  // En dashboard_screen.dart, REEMPLAZA la función _loadStats() completa:

  // 🔧 FIX CORRECTO: Volver a Duration(days: 7)

  // En dashboard_screen.dart, función _loadStats()
  // CAMBIAR de Duration(days: 8) a Duration(days: 7)

  Future<void> _loadStats() async {
    setState(() => _loading = true);

    // ⭐ Normalizar "now" a medianoche de hoy
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime startDate;

    switch (_selectedPeriod) {
      case '7days':
        startDate = today.subtract(const Duration(days: 7));
        break;
      case '30days':
        startDate = today.subtract(const Duration(days: 30));
        break;
      case '90days':
        startDate = today.subtract(const Duration(days: 90));
        break;
      default:
        startDate = today.subtract(const Duration(days: 7));
    }

    final stats = await DatabaseService.instance.getDashboardStats(
      startDate,
      today, // ⭐ Pasar "today" (medianoche) en lugar de "now"
    );

    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  Map<String, double> _getFilteredAverages() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filtrar días (igual que en el gráfico)
    final filteredData = _stats!.dailyData.where((day) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      return dayDate.isBefore(today);
    }).toList();

    if (filteredData.isEmpty) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var day in filteredData) {
      totalCalories += day.calories;
      totalProtein += day.protein;
      totalCarbs += day.carbs;
      totalFat += day.fat;
    }

    final count = filteredData.length;

    return {
      'calories': totalCalories / count,
      'protein': totalProtein / count,
      'carbs': totalCarbs / count,
      'fat': totalFat / count,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: '7days', label: Text('7 días')),
                      ButtonSegment(value: '30days', label: Text('30 días')),
                      ButtonSegment(value: '90days', label: Text('90 días')),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedPeriod = newSelection.first;
                      });
                      _loadStats();
                    },
                  ),

                  const SizedBox(height: 24),

                  _buildMacrosCard(),

                  const SizedBox(height: 16),

                  _buildCaloriesChart(),

                  const SizedBox(height: 16),

                  _buildMacrosPercentChart(),

                  const SizedBox(height: 16),

                  _buildTopFoods(),

                  const SizedBox(height: 16),

                  _buildHabitsCompletion(),
                ],
              ),
            ),
    );
  }

  Widget _buildMacrosCard() {
    final averages = _getFilteredAverages();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Promedio Diario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem(
                  'Calorías',
                  averages['calories']!.toStringAsFixed(0),
                  'kcal',
                  Colors.orange,
                  'calories',
                ),
                _buildMacroItem(
                  'Proteínas',
                  averages['protein']!.toStringAsFixed(1),
                  'g',
                  Colors.red,
                  'protein',
                ),
                _buildMacroItem(
                  'Carbos',
                  averages['carbs']!.toStringAsFixed(1),
                  'g',
                  Colors.blue,
                  'carbs',
                ),
                _buildMacroItem(
                  'Grasas',
                  averages['fat']!.toStringAsFixed(1),
                  'g',
                  Colors.green,
                  'fat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(
    String label,
    String value,
    String unit,
    Color color,
    String macroKey,
  ) {
    final isSelected = _selectedMacro == macroKey;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMacro = macroKey;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? color : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesChart() {
    if (_stats!.dailyData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay datos para mostrar'),
        ),
      );
    }

    // Verificar si hay datos después de excluir hoy
    final spots = _getChartSpots();
    if (spots.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay datos históricos para mostrar'),
        ),
      );
    }

    // Determinar título y color según el macro seleccionado
    String chartTitle;
    Color chartColor;

    switch (_selectedMacro) {
      case 'protein':
        chartTitle = 'Tendencia de Proteínas';
        chartColor = Colors.red;
        break;
      case 'carbs':
        chartTitle = 'Tendencia de Carbohidratos';
        chartColor = Colors.blue;
        break;
      case 'fat':
        chartTitle = 'Tendencia de Grasas';
        chartColor = Colors.green;
        break;
      default:
        chartTitle = 'Tendencia de Calorías';
        chartColor = Colors.orange;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chartTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  minY: _getMinY(), // ⭐ NUEVO - padding 20% abajo
                  maxY: _getMaxY(), // ⭐ NUEVO - padding 20% arriba
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartSpots(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: chartColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔍 CÓDIGO DE DEBUG - Agregar a _getChartSpots()

  // REEMPLAZA tu función _getChartSpots() COMPLETA con esto:

  List<FlSpot> _getChartSpots() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filtrar días válidos (antes de hoy)
    final filteredData = _stats!.dailyData.where((day) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      return dayDate.isBefore(today);
    }).toList();

    // Ordenar cronológicamente (del más antiguo al más reciente)
    filteredData.sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    for (var i = 0; i < filteredData.length; i++) {
      final day = filteredData[i];

      double value;
      switch (_selectedMacro) {
        case 'protein':
          value = day.protein;
          break;
        case 'carbs':
          value = day.carbs;
          break;
        case 'fat':
          value = day.fat;
          break;
        default:
          value = day.calories;
      }

      spots.add(FlSpot(i.toDouble(), value.roundToDouble()));
    }

    return spots;
  }

  // ⭐ NUEVAS FUNCIONES - Calcular min/max con padding 20/20
  double _getMinY() {
    final spots = _getChartSpots(); // Ya viene filtrado sin el día actual
    if (spots.isEmpty) return 0;

    final values = spots.map((spot) => spot.y).toList();

    final dataMin = values.reduce(min);
    final dataMax = values.reduce(max);
    final range = dataMax - dataMin;

    // Si el rango es muy pequeño (datos casi iguales), usar un padding fijo
    if (range < 10) {
      return (dataMin - 10).clamp(0, double.infinity);
    }

    // Padding 20% abajo
    final minY = dataMin - (range * 0.20);

    // No permitir valores negativos para calorías/macros
    return minY.clamp(0, double.infinity);
  }

  double _getMaxY() {
    final spots = _getChartSpots(); // Ya viene filtrado sin el día actual
    if (spots.isEmpty) return 100;

    final values = spots.map((spot) => spot.y).toList();

    final dataMin = values.reduce(min);
    final dataMax = values.reduce(max);
    final range = dataMax - dataMin;

    // Si el rango es muy pequeño, usar un padding fijo
    if (range < 10) {
      return dataMax + 10;
    }

    // Padding 20% arriba
    return dataMax + (range * 0.20);
  }

  Widget _buildTopFoods() {
    // Ordenar según el criterio seleccionado
    final sortedFoods = _stats!.topFoods.toList();
    if (_topFoodsSort == 'weight') {
      sortedFoods.sort((a, b) => b.totalGrams.compareTo(a.totalGrams));
    }
    // Si es 'times' ya viene ordenado del getDashboardStats

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 Alimentos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'times', label: Text('Más consumidos')),
                ButtonSegment(value: 'weight', label: Text('Mayor peso')),
              ],
              selected: {_topFoodsSort},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _topFoodsSort = newSelection.first;
                });
              },
            ),

            const SizedBox(height: 12),

            ...sortedFoods
                .take(5)
                .map(
                  (food) => ListTile(
                    dense: true,
                    leading: Text(
                      food.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(food.fullName ?? food.name),
                    trailing: Text(
                      _topFoodsSort == 'times'
                          ? '${food.timesConsumed}x'
                          : '${food.totalGrams.toStringAsFixed(0)}g',
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsCompletion() {
    if (_stats!.habitCompletion.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalDays = _stats!.endDate.difference(_stats!.startDate).inDays + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hábitos Completados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._stats!.habitCompletion.entries.map((entry) {
              final percentage = (entry.value / totalDays * 100)
                  .toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value}/$totalDays días ($percentage%)'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMacrosPercentChart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filteredData = _stats!.dailyData.where((day) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      return dayDate.isBefore(today);
    }).toList();

    if (filteredData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay datos históricos para mostrar'),
        ),
      );
    }

    // Calcular puntos apilados
    final proteinSpots = _getMacroSpots(filteredData, 'protein');
    final carbsSpots = _getMacroSpots(filteredData, 'carbs');
    final fatSpots = _getMacroSpots(filteredData, 'fat');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución porcentual de macronutrientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: 100,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 6,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (spots) {
                        if (spots.isEmpty) return [];
                        final index = spots.first.x.toInt();
                        if (index < 0 || index >= filteredData.length)
                          return [];

                        final day = filteredData[index];
                        final proteinCals = day.protein * 4;
                        final carbsCals = day.carbs * 4;
                        final fatCals = day.fat * 9;
                        final totalCals = proteinCals + carbsCals + fatCals;

                        final proteinPercent = totalCals > 0
                            ? (proteinCals / totalCals) * 100
                            : 0;
                        final carbsPercent = totalCals > 0
                            ? (carbsCals / totalCals) * 100
                            : 0;
                        final fatPercent = totalCals > 0
                            ? (fatCals / totalCals) * 100
                            : 0;

                        return [
                          LineTooltipItem(
                            'Proteínas: ${proteinPercent.toStringAsFixed(1)}%\n'
                            'Carbohidratos: ${carbsPercent.toStringAsFixed(1)}%\n'
                            'Grasas: ${fatPercent.toStringAsFixed(1)}%',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                  betweenBarsData: [
                    BetweenBarsData(
                      fromIndex: 0,
                      toIndex: 1,
                      color: Colors.blue.withOpacity(0.5),
                    ),
                    BetweenBarsData(
                      fromIndex: 1,
                      toIndex: 2,
                      color: Colors.green.withOpacity(0.5),
                    ),
                  ],
                  lineBarsData: [
                    LineChartBarData(
                      spots: proteinSpots,
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withOpacity(0.5),
                      ),
                    ),
                    LineChartBarData(
                      spots: carbsSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: fatSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 1.5,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
              ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Proteínas', Colors.orange),
                const SizedBox(width: 16),
                _buildLegendItem('Carbohidratos', Colors.blue),
                const SizedBox(width: 16),
                _buildLegendItem('Grasas', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Genera puntos acumulativos por macro
  List<FlSpot> _getMacroSpots(List<dynamic> data, String macroType) {
    return data.asMap().entries.map((entry) {
      final day = entry.value;
      final proteinCals = day.protein * 4;
      final carbsCals = day.carbs * 4;
      final fatCals = day.fat * 9;
      final totalCals = proteinCals + carbsCals + fatCals;

      double value = 0;
      if (totalCals > 0) {
        final proteinPercent = (proteinCals / totalCals) * 100;
        final carbsPercent = (carbsCals / totalCals) * 100;
        final fatPercent = (fatCals / totalCals) * 100;

        if (macroType == 'protein') {
          value = proteinPercent;
        } else if (macroType == 'carbs') {
          value = proteinPercent + carbsPercent;
        } else if (macroType == 'fat') {
          value = proteinPercent + carbsPercent + fatPercent;
        }
      }

      return FlSpot(entry.key.toDouble(), value);
    }).toList();
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.5),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
