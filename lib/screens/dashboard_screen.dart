import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// PDF direct imports no longer needed here
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
// import 'dart:io';
import 'package:intl/intl.dart';
import '../models/dashboard_stats.dart';
import '../models/dashboard_preferences.dart';
import '../models/user_profile.dart';
import '../services/storage_factory.dart';
import '../utils/nutrients_helper.dart';
import 'dashboard_settings_screen.dart';
import '../services/dashboard_pdf_export.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/file_saver.dart';
import 'report_setup_screen.dart';
import '../services/food_repository.dart';
import '../models/food.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPeriod = '7days';
  String _selectedMacro = 'calories';
  String _selectedNutrient = 'fiber';
  String _topFoodsSort = 'times';
  DashboardStats? _stats;
  bool _loading = true;
  DashboardPreferences _preferences = const DashboardPreferences();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Esto cargará las preferencias y luego los stats
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await StorageFactory.instance.getUserProfile();
    setState(() {
      _userProfile = profile;
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('dashboard_preferences');
    if (jsonString != null) {
      setState(() {
        _preferences = DashboardPreferences.fromJson(jsonDecode(jsonString));
      });
    }
    // Cargar umbral de sugerencias
    final threshold = prefs.getDouble('suggestion_threshold') ?? 85.0;
    setState(() {
      _suggestionThreshold = threshold;
    });
    // Cargar stats después de cargar las preferencias
    _loadStats();
  }

  List<_Suggestion> _suggestions = <_Suggestion>[];
  // Mostrar sugerencias hasta 300% de cumplimiento para que siempre haya variedad
  double _suggestionThreshold = 85.0; // porcentaje de cumplimiento (se carga desde settings)

  Future<void> _computeSuggestions() async {
    if (!mounted) return;
    if (_stats == null || _stats!.dailyData.isEmpty) {
      setState(() {
        _suggestions = <_Suggestion>[];
      });
      return;
    }

    await FoodRepository().loadFoods();
    final foods = FoodRepository().getAllFoods();
    final weight = _userProfile?.weight ?? 70.0;

    final List<_Suggestion> deficits = [];

    for (final n in availableNutrients) {
      if (n.key == 'sodium' || n.key == 'saturatedFats') continue;

      double total = 0;
      for (final d in _stats!.dailyData) {
        total += (d.nutrients[n.key] ?? 0);
      }
      final avg = _stats!.dailyData.isNotEmpty
          ? total / _stats!.dailyData.length
          : 0.0;

      double goal = n.rdaValue;
      if (n.unit == 'mg/kg/day') goal = (goal * weight) / 1000.0;
      if (goal <= 0) continue;

      final perc = goal > 0 ? (avg / goal) * 100.0 : 0.0;

      final ranked =
          foods
              .map((f) => MapEntry(f, _foodValueByKey(f, n.key)))
              .where((e) => e.value > 0)
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      final topFoods = ranked.take(3).map((e) => e.key).toList();
      if (topFoods.isNotEmpty && perc < _suggestionThreshold) {
        deficits.add(_Suggestion(
          key: n.key,
          name: n.displayName,
          percentage: perc,
          foods: topFoods,
        ));
      }
    }

    // sort by lower compliance and cap to 3
    deficits.sort((a, b) => a.percentage.compareTo(b.percentage));

    if (!mounted) return;
    setState(() {
      _suggestions = deficits.take(3).toList();
    });
  }

  Widget _buildSuggestedFoodsCard() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alimentos sugeridos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth * 0.9;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const PageScrollPhysics().applyTo(
                      const BouncingScrollPhysics(),
                    ),
                    itemCount: _suggestions.length,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final s = _suggestions[i];
                      final foods = s.foods.take(3).toList();
                      return SizedBox(
                        width: cardWidth,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            color: Colors.blueGrey.shade50,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Text(
                                    'Aumenta tu consumo de:',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: foods
                                      .map(
                                        (f) => Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                f.emoji,
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                f.fullName ?? f.name,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const Spacer(),
                                Center(
                                  child: Text(
                                    'Motivo: ${s.name} (${s.percentage.toStringAsFixed(0)}%)',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Excluir el dí­a de hoy - usar hasta el final de ayer
    final yesterday = today.subtract(const Duration(days: 1));
    final endDate = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
      23,
      59,
      59,
    );
    DateTime startDate;

    switch (_selectedPeriod) {
      case '7days':
        // 7 dias completos: desde hace 7 dias a las 00:00:00
        startDate = yesterday.subtract(const Duration(days: 6));
        break;
      case '30days':
        // 30 dias completos
        startDate = yesterday.subtract(const Duration(days: 29));
        break;
      case '90days':
        // 90 dias completos
        startDate = yesterday.subtract(const Duration(days: 89));
        break;
      default:
        startDate = yesterday.subtract(const Duration(days: 6));
    }

    try {
      final stats = await StorageFactory.instance.getDashboardStats(
        startDate,
        endDate,
        includeFastingInAverages: _preferences.includeFastingInAverages,
      );
      setState(() {
        _stats = stats;
        _loading = false;
      });
      if (mounted) {
        // no await, deja que el dashboard ya se vea
        _computeSuggestions();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = DashboardStats(
            startDate: startDate,
            endDate: endDate,
            avgCalories: 0,
            avgProtein: 0,
            avgCarbs: 0,
            avgFat: 0,
            dailyData: [],
            topFoods: [],
            topFoodsByWeight: [],
            habitCompletion: {},
          );
          _loading = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<DashboardPreferences>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DashboardSettingsScreen(currentPreferences: _preferences),
      ),
    );

    if (result != null) {
      setState(() {
        _preferences = result;
      });
      // Recargar estadísticas con la nueva configuración
      _loadStats();
    }
  }

  Future<void> _openReportSetup() async {
    final result = await Navigator.push<DashboardPreferences>(
      context,
      MaterialPageRoute(
        builder: (context) => ReportSetupScreen(current: _preferences),
      ),
    );

    if (result != null) {
      setState(() {
        _preferences = result;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'dashboard_preferences',
        jsonEncode(_preferences.toJson()),
      );
    }
  }

  Future<void> _openExportStylePopup() async {
    String style = _preferences.reportStyle;
    bool zebra = _preferences.tableZebra;
    String page = _preferences.pageFormat;
    String nutrientsMode = _preferences.nutrientsExportMode;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Opciones de exportación'),
          content: StatefulBuilder(
            builder: (context, setLocalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tema'),
                    RadioListTile<String>(
                      title: const Text('Mínimo'),
                      value: 'minimal',
                      groupValue: style,
                      onChanged: (v) => setLocalState(() => style = v!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Clásico'),
                      value: 'classic',
                      groupValue: style,
                      onChanged: (v) => setLocalState(() => style = v!),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Usar filas tipo "zebra"'),
                      value: zebra,
                      onChanged: (v) => setLocalState(() => zebra = v),
                    ),
                    const Divider(),
                    const Text('Tamaño de página'),
                    RadioListTile<String>(
                      title: const Text('A4'),
                      value: 'a4',
                      groupValue: page,
                      onChanged: (v) => setLocalState(() => page = v!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Carta (Letter)'),
                      value: 'letter',
                      groupValue: page,
                      onChanged: (v) => setLocalState(() => page = v!),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _preferences = _preferences.copyWith(
                    reportStyle: style,
                    tableZebra: zebra,
                    pageFormat: page,
                  );
                });
                final sp = await SharedPreferences.getInstance();
                await sp.setString(
                  'dashboard_preferences',
                  jsonEncode(_preferences.toJson()),
                );
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  void _nextNutrient() {
    final currentIndex = availableNutrients.indexWhere(
      (n) => n.key == _selectedNutrient,
    );
    if (currentIndex < availableNutrients.length - 1) {
      setState(() {
        _selectedNutrient = availableNutrients[currentIndex + 1].key;
      });
    }
  }

  void _previousNutrient() {
    final currentIndex = availableNutrients.indexWhere(
      (n) => n.key == _selectedNutrient,
    );
    if (currentIndex > 0) {
      setState(() {
        _selectedNutrient = availableNutrients[currentIndex - 1].key;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Opciones de exportación',
            icon: const Icon(Icons.palette, size: 26),
            onPressed: _openExportStylePopup,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Ajustes',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _stats != null ? _shareDashboardPdf : null,
            tooltip: 'Compartir PDF',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kIsWeb && (_stats?.dailyData.isEmpty ?? true))
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sin datos en Web',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No hay datos históricos para mostrar en Web.',
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: '7days', label: Text('7 dias')),
                      ButtonSegment(value: '30days', label: Text('30 dias')),
                      ButtonSegment(value: '90days', label: Text('90 dias')),
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

                  if (_preferences.showMacrosCard) ...[
                    _buildMacrosCard(),
                    const SizedBox(height: 16),
                  ],

                  if (_preferences.showCaloriesChart) ...[
                    _buildCaloriesChart(),
                    const SizedBox(height: 16),
                  ],

                  if (_preferences.showMacrosPercentChart) ...[
                    _buildMacrosPercentChart(),
                    const SizedBox(height: 16),
                  ],
                  if (_preferences.showSuggestedFoods) ...[
                    _buildSuggestedFoodsCard(),
                    const SizedBox(height: 16),
                  ],
                  if (_preferences.showNutrientsAnalysis) ...[
                    _buildNutrientsAnalysis(),
                    const SizedBox(height: 16),
                  ],

                  if (_preferences.showTopFoods) ...[
                    _buildTopFoods(),
                    const SizedBox(height: 16),
                  ],

                  if (_preferences.showHabitsCompletion) ...[
                    _buildHabitsCompletion(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMacrosCard() {
    // Contar días de ayuno en el período
    final fastingDaysCount =
        _stats!.dailyData.where((day) => day.isFasting).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Promedio Diario',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (fastingDaysCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🚫 $fastingDaysCount día${fastingDaysCount > 1 ? 's' : ''} de ayuno',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
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
                  minY: _getMinYForMacros(),
                  maxY: _getMaxYForMacros(),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          String unit;
                          switch (_selectedMacro) {
                            case 'protein':
                            case 'carbs':
                            case 'fat':
                              unit = 'g';
                              break;
                            default:
                              unit = 'kcal';
                          }

                          // Verificar si es día de ayuno
                          final dayIndex = spot.x.toInt();
                          final isFasting = dayIndex >= 0 &&
                              dayIndex < _stats!.dailyData.length &&
                              _stats!.dailyData[dayIndex].isFasting;

                          final text = isFasting
                              ? '🚫 Ayuno'
                              : '${spot.y.toStringAsFixed(1)} $unit';

                          return LineTooltipItem(
                            text,
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartSpots(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: chartColor,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          // Mostrar puntos de días de ayuno de forma diferente
                          final isFasting = index >= 0 &&
                              index < _stats!.dailyData.length &&
                              _stats!.dailyData[index].isFasting;

                          return FlDotCirclePainter(
                            radius: isFasting ? 6 : 4,
                            color: isFasting ? Colors.red : chartColor,
                            strokeWidth: isFasting ? 2 : 1,
                            strokeColor:
                                isFasting ? Colors.redAccent : Colors.white,
                          );
                        },
                      ),
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

  double _getMinYForMacros() {
    final spots = _getChartSpots();
    if (spots.isEmpty) return 0;

    final values = spots.map((spot) => spot.y).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final range = dataMax - dataMin;

    if (range < 10) {
      return (dataMin - 10).clamp(0, double.infinity);
    }

    final minY = dataMin - (range * 0.20);
    return minY.clamp(0, double.infinity);
  }

  double _getMaxYForMacros() {
    final spots = _getChartSpots();
    if (spots.isEmpty) return 100;

    final values = spots.map((spot) => spot.y).toList();
    final dataMin = values.reduce((a, b) => a < b ? a : b);
    final dataMax = values.reduce((a, b) => a > b ? a : b);
    final range = dataMax - dataMin;

    if (range < 10) {
      return dataMax + 10;
    }

    return dataMax + (range * 0.20);
  }

  Widget _buildNutrientsAnalysis() {
    if (_stats!.dailyData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay datos de nutrientes para mostrar'),
        ),
      );
    }

    final selectedNutrient = availableNutrients.firstWhere(
      (n) => n.key == _selectedNutrient,
      orElse: () => availableNutrients[0],
    );

    final hasRDA = selectedNutrient.rdaValue > 0;

    // Calcular promedio del nutriente seleccionado
    double totalNutrient = 0;
    int daysWithData = 0;

    for (var day in _stats!.dailyData) {
      final value = day.nutrients[_selectedNutrient] ?? 0;
      totalNutrient += value;
      if (value > 0) daysWithData++;
    }

    final avgNutrient = daysWithData > 0
        ? totalNutrient / _stats!.dailyData.length
        : 0.0;
    final percentage = hasRDA
        ? (avgNutrient / selectedNutrient.rdaValue * 100)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análisis de Nutrientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Dropdown para seleccionar nutriente
            DropdownButtonFormField<String>(
              value: _selectedNutrient,
              decoration: const InputDecoration(
                labelText: 'Seleccionar nutriente',
                border: OutlineInputBorder(),
              ),
              items: availableNutrients.map((nutrient) {
                return DropdownMenuItem(
                  value: nutrient.key,
                  child: Text(nutrient.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedNutrient = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Estadí­sticas del nutriente con swipe e indicadores visuales
            Row(
              children: [
                // Flecha izquierda
                Icon(Icons.chevron_left, color: Colors.grey.shade400, size: 32),
                // Contenedor con estadí­sticas
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      // Swipe a la izquierda (siguiente nutriente)
                      if (details.primaryVelocity! < 0) {
                        _nextNutrient();
                      }
                      // Swipe a la derecha (nutriente anterior)
                      else if (details.primaryVelocity! > 0) {
                        _previousNutrient();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildNutrientStats(
                        selectedNutrient,
                        avgNutrient,
                        percentage,
                        hasRDA,
                      ),
                    ),
                  ),
                ),
                // Flecha derecha
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 32,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Gráfico de evolución
            const Text(
              'Evolución Temporal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  minY: _getNutrientMinY(selectedNutrient),
                  maxY: _getNutrientMaxY(selectedNutrient),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} ${selectedNutrient.unit}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    // Lí­nea de consumo real
                    LineChartBarData(
                      spots: _getNutrientChartSpots(selectedNutrient),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    // Lí­nea de objetivo (solo si tiene RDA)
                    if (hasRDA)
                      LineChartBarData(
                        spots: _getGoalLineSpots(selectedNutrient),
                        isCurved: false,
                        color: Colors.green.withOpacity(0.5),
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        dashArray: [5, 5],
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

  Widget _buildNutrientStats(
    NutrientInfo nutrient,
    double avgValue,
    double percentage,
    bool hasRDA,
  ) {
    // Para aminoácidos (mg/kg/day), convertir RDA a gramos totales
    final userWeight = _userProfile?.weight ?? 70.0;
    double displayAvg = avgValue;
    double displayGoal = nutrient.rdaValue;
    String displayUnit = nutrient.unit;
    double displayPercentage = percentage;

    if (nutrient.unit == 'mg/kg/day') {
      // avgValue ya está en gramos totales (sumado desde los alimentos)
      // Solo convertir objetivo de mg/kg/day a gramos totales
      displayGoal = (nutrient.rdaValue * userWeight) / 1000;
      displayUnit = 'g';
      // Recalcular porcentaje con valores en gramos
      displayPercentage = displayGoal > 0
          ? (displayAvg / displayGoal * 100)
          : 0.0;
    }

    // Formateo de meta sin decimales para nutrientes grandes o metas enteras
    final noDecimalKeys = <String>{
      'calcium',
      'magnesium',
      'phosphorus',
      'potassium',
      'sodium',
      'fluorine',
      'vitaminA',
      'vitaminB9',
      'vitaminK',
    };
    String fmtNumber(double v, {int fallback = 1, bool forceInt = false}) {
      if (forceInt ||
          v.roundToDouble() == v ||
          noDecimalKeys.contains(nutrient.key) ||
          v.abs() >= 100)
        return v.toStringAsFixed(0);
      return v.toStringAsFixed(fallback);
    }

    final isLimit = nutrient.key == 'sodium';
    // Build the list of children widgets
    final List<Widget> children = [];

    // Always add the average column
    children.add(
      Column(
        children: [
          const Text(
            'Promedio',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '${fmtNumber(displayAvg)} $displayUnit',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );

    // Add RDA-related columns only if hasRDA is true
    if (hasRDA) {
      children.add(
        Column(
          children: [
            const Text(
              'Objetivo',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '${fmtNumber(displayGoal)} $displayUnit',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );

      children.add(
        Column(
          children: [
            Text(
              isLimit ? 'Límite' : 'Cumplimiento',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '${displayPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isLimit
                    ? (displayPercentage <= 100 ? Colors.green : Colors.orange)
                    : (displayPercentage >= 100 ? Colors.green : Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    // Return the Row with the dynamically built children
    return Row(
      mainAxisAlignment: hasRDA
          ? MainAxisAlignment.spaceAround
          : MainAxisAlignment.center,
      children: children,
    );
  }

  List<FlSpot> _getNutrientChartSpots(NutrientInfo nutrient) {
    return _stats!.dailyData.asMap().entries.map((entry) {
      final value = entry.value.nutrients[nutrient.key] ?? 0;
      return FlSpot(entry.key.toDouble(), value);
    }).toList();
  }

  List<FlSpot> _getGoalLineSpots(NutrientInfo nutrient) {
    if (_stats!.dailyData.isEmpty) return [];

    // Para aminoácidos, convertir de mg/kg/day a gramos totales
    double goalValue = nutrient.rdaValue;
    if (nutrient.unit == 'mg/kg/day') {
      final userWeight = _userProfile?.weight ?? 70.0;
      goalValue = (nutrient.rdaValue * userWeight) / 1000;
    }

    return [
      FlSpot(0, goalValue),
      FlSpot(_stats!.dailyData.length - 1.0, goalValue),
    ];
  }

  double _getNutrientMinY(NutrientInfo nutrient) {
    if (_stats!.dailyData.isEmpty) return -10;

    double maxValue = 0;

    // Encontrar el valor máximo consumido
    for (var day in _stats!.dailyData) {
      final value = day.nutrients[nutrient.key] ?? 0;
      if (value > maxValue) maxValue = value;
    }

    // Considerar RDA/objetivo si existe
    double goalValue = 0;
    if (nutrient.unit == 'mg/kg/day') {
      final userWeight = _userProfile?.weight ?? 70.0;
      goalValue = (nutrient.rdaValue * userWeight) / 1000;
    } else if (nutrient.rdaValue > 0) {
      goalValue = nutrient.rdaValue;
    }

    // Usar el máximo entre el valor consumido y el objetivo
    final displayMax = maxValue > goalValue ? maxValue : goalValue;

    // Si el valor es muy pequeño
    if (displayMax < 1) {
      return -0.20; // 10% de 2.0
    }

    // Padding 10% abajo (como valor negativo para dar espacio visual)
    return -(displayMax * 0.20);
  }

  double _getNutrientMaxY(NutrientInfo nutrient) {
    if (_stats!.dailyData.isEmpty) return 100;

    double maxValue = 0;

    // Encontrar el valor máximo consumido
    for (var day in _stats!.dailyData) {
      final value = day.nutrients[nutrient.key] ?? 0;
      if (value > maxValue) maxValue = value;
    }

    // Considerar RDA/objetivo si existe
    double goalValue = 0;
    if (nutrient.unit == 'mg/kg/day') {
      final userWeight = _userProfile?.weight ?? 70.0;
      goalValue = (nutrient.rdaValue * userWeight) / 1000;
    } else if (nutrient.rdaValue > 0) {
      goalValue = nutrient.rdaValue;
    }

    // Usar el máximo entre el valor consumido y el objetivo
    final displayMax = maxValue > goalValue ? maxValue : goalValue;

    // Si el valor es muy pequeño, usar un mínimo razonable
    if (displayMax < 1) {
      return 1.5;
    }

    // Agregar 10% de padding arriba (el 10% abajo se maneja en minY)
    // Total: 20% de padding (10% arriba + 10% abajo)
    return displayMax * 1.20;
  }

  Widget _buildTopFoods() {
    final sortedFoods = _stats!.topFoods.toList();
    if (_topFoodsSort == 'weight') {
      sortedFoods.sort((a, b) => b.totalGrams.compareTo(a.totalGrams));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top 5 Alimentos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    final byUse = _stats!.topFoods;
                    final byWeight = _stats!.topFoodsByWeight;
                    final map = <String, TopFood>{};

                    for (final f in byUse) {
                      map[f.fullName] = f;
                    }
                    for (final f in byWeight) {
                      map.putIfAbsent(f.fullName, () => f);
                    }

                    var list = map.values.toList();
                    if (_topFoodsSort == 'weight') {
                      list.sort((a, b) => b.totalGrams.compareTo(a.totalGrams));
                    } else {
                      list.sort(
                        (a, b) => b.timesConsumed.compareTo(a.timesConsumed),
                      );
                    }

                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Todos los alimentos'),
                        content: SizedBox(
                          width: double.maxFinite,
                          height: 420,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final f = list[i];
                              final trailing = _topFoodsSort == 'times'
                                  ? '${f.timesConsumed}x'
                                  : '${f.totalGrams.toStringAsFixed(0)}g';
                              return ListTile(
                                dense: true,
                                leading: Text(
                                  f.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                title: Text(f.fullName),
                                trailing: Text(trailing),
                              );
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Mostrar todos'),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
                    title: Text(food.fullName),
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
                    Text('${entry.value}/$totalDays dias ($percentage%)'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, double> _getFilteredAverages() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filtrar dias (igual que en el gráfico)
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

  Future<void> _shareDashboardPdf() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generar bytes del PDF mediante servicio modular
      final bytes = await DashboardPdfExport.generateDashboardPdf(
        stats: _stats!,
        prefs: _preferences,
        periodKey: _selectedPeriod,
        startDate: _stats!.startDate,
        endDate: _stats!.endDate,
        user: _userProfile,
      );

      // Calcular promedios filtrados
      final averages = _getFilteredAverages();

      // Informacion del periodo
      String periodText;
      switch (_selectedPeriod) {
        case '7days':
          periodText = '7 dias';
          break;
        case '30days':
          periodText = '30 dias';
          break;
        case '90days':
          periodText = '90 dias';
          break;
        default:
          periodText = '7 dias';
      }

      final dateRange =
          '${DateFormat('dd/MM/yyyy').format(_stats!.startDate)} - ${DateFormat('dd/MM/yyyy').format(_stats!.endDate)}';

      // Obtener datos filtrados
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final filteredData = _stats!.dailyData.where((day) {
        final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
        return dayDate.isBefore(today);
      }).toList();
      filteredData.sort((a, b) => a.date.compareTo(b.date));

      // Guardar/descargar PDF (IO/Web)
      final fileName =
          'dashboard_${DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now())}.pdf';
      final savedPath = await savePdf(bytes, fileName);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        if (!kIsWeb && savedPath != null) {
          Share.shareXFiles([XFile(savedPath)], subject: 'Dashboard - AcoFood');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Descarga iniciada: $fileName')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('No se pudo exportar el dashboard:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }
  }

  // PDF helper methods moved to service (lib/services/dashboard_pdf_export.dart)

  Widget _buildMacrosPercentChart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filtrar: excluir hoy, días de ayuno, y días con muy pocas calorías
    final filteredData = _stats!.dailyData.where((day) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      final totalCals = (day.protein * 4) + (day.carbs * 4) + (day.fat * 9);

      // Excluir día actual, días de ayuno, y días con menos de 100 calorías
      return dayDate.isBefore(today) && !day.isFasting && totalCals >= 100;
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
            // Si no hay suficientes puntos válidos, mostrar fallback
            if (filteredData.length < 2)
              const SizedBox(
                height: 200,
                child: Center(
                  child: Text('Sin datos suficientes para graficar'),
                ),
              )
            else
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
                        getTooltipItems: (touchedSpots) {
                          if (touchedSpots.isEmpty) return [];
                          final idx = touchedSpots.first.x.round().clamp(
                            0,
                            filteredData.length - 1,
                          );
                          final day = filteredData[idx];

                          final pC = day.protein * 4;
                          final cC = day.carbs * 4;
                          final fC = day.fat * 9;
                          final tot = pC + cC + fC;

                          final p = tot > 0 ? (pC / tot) * 100 : 0.0;
                          final c = tot > 0 ? (cC / tot) * 100 : 0.0;
                          final f = tot > 0 ? (fC / tot) * 100 : 0.0;

                          final text =
                              'Proteínas: ${p.toStringAsFixed(1)}%\n'
                              'Carbohidratos: ${c.toStringAsFixed(1)}%\n'
                              'Grasas: ${f.toStringAsFixed(1)}%';

                          final first = LineTooltipItem(
                            text,
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                          final blank = LineTooltipItem('', const TextStyle());
                          return List.generate(
                            touchedSpots.length,
                            (i) => i == 0 ? first : blank,
                          );
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

  List<FlSpot> _getMacroSpots(List<DailyData> data, String macroType) {
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

      // Evitar NaN/Infinity
      if (!value.isFinite) value = 0;
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

class _Suggestion {
  final String key;
  final String name;
  final double percentage;
  final List<Food> foods;
  _Suggestion({
    required this.key,
    required this.name,
    required this.percentage,
    required this.foods,
  });
}

double _foodValueByKey(Food f, String k) {
  switch (k) {
    case 'vitaminA':
      return f.vitaminA;
    case 'vitaminC':
      return f.vitaminC;
    case 'calcium':
      return f.calcium;
    case 'iron':
      return f.iron;
    case 'zinc':
      return f.zinc;
    case 'magnesium':
      return f.magnesium;
    case 'fiber':
      return f.fiber;
    case 'omega3':
      return f.omega3;
    default:
      return 0.0;
  }
}



