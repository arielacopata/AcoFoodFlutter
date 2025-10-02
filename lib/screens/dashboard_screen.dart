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
                  // Selector de período
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
                  
                  // Promedios de macros
                  _buildMacrosCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Gráfico de calorías
                  _buildCaloriesChart(),
                  
                  const SizedBox(height: 16),
                  
                  // Top alimentos
                  _buildTopFoods(),
                  
                  const SizedBox(height: 16),
                  
                  // Completitud de hábitos
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
                ),
                _buildMacroItem(
                  'Proteínas',
                  _stats!.avgProtein.toStringAsFixed(1),
                  'g',
                  Colors.red,
                ),
                _buildMacroItem(
                  'Carbos',
                  _stats!.avgCarbs.toStringAsFixed(1),
                  'g',
                  Colors.blue,
                ),
                _buildMacroItem(
                  'Grasas',
                  _stats!.avgFat.toStringAsFixed(1),
                  'g',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendencia de Calorías',
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: _stats!.dailyData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.calories,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
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

  Widget _buildTopFoods() {
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
            ..._stats!.topFoods.map((food) => ListTile(
              dense: true,
              leading: Text(food.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(food.name),
              trailing: Text('${food.timesConsumed}x'),
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