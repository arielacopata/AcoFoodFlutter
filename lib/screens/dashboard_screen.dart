import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';

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

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedPeriod) {
      case '7days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '90days':
        startDate = now.subtract(const Duration(days: 90));
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }
    
    final stats = await DatabaseService.instance.getDashboardStats(startDate, now);
    
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
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
                  
                  _buildTopFoods(),
                  
                  const SizedBox(height: 16),
                  
                  _buildHabitsCompletion(),
                ],
              ),
            ),
    );
  }

  Widget _buildMacrosCard() {
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
                  _stats!.avgCalories.toStringAsFixed(0),
                  'kcal',
                  Colors.orange,
                  'calories',
                ),
                _buildMacroItem(
                  'Proteínas',
                  _stats!.avgProtein.toStringAsFixed(1),
                  'g',
                  Colors.red,
                  'protein',
                ),
                _buildMacroItem(
                  'Carbos',
                  _stats!.avgCarbs.toStringAsFixed(1),
                  'g',
                  Colors.blue,
                  'carbs',
                ),
                _buildMacroItem(
                  'Grasas',
                  _stats!.avgFat.toStringAsFixed(1),
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartSpots(),
                      isCurved: true,
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

List<FlSpot> _getChartSpots() {
  return _stats!.dailyData.asMap().entries.map((entry) {
    double value;
    switch (_selectedMacro) {
      case 'protein':
        value = entry.value.protein;
        break;
      case 'carbs':
        value = entry.value.carbs;
        break;
      case 'fat':
        value = entry.value.fat;
        break;
      default:
        value = entry.value.calories;
    }
    
    return FlSpot(entry.key.toDouble(), value);
  }).toList();
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
              ButtonSegment(
                value: 'times',
                label: Text('Más consumidos'),
              ),
              ButtonSegment(
                value: 'weight',
                label: Text('Mayor peso'),
              ),
            ],
            selected: {_topFoodsSort},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _topFoodsSort = newSelection.first;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          ...sortedFoods.take(5).map((food) => ListTile(
            dense: true,
            leading: Text(food.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(food.name),
            trailing: Text(
              _topFoodsSort == 'times'
                  ? '${food.timesConsumed}x'
                  : '${food.totalGrams.toStringAsFixed(0)}g',
            ),
          )),
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
              final percentage = (entry.value / totalDays * 100).toStringAsFixed(0);
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
}