import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/dashboard_preferences.dart';

class DashboardSettingsScreen extends StatefulWidget {
  final DashboardPreferences currentPreferences;

  const DashboardSettingsScreen({super.key, required this.currentPreferences});

  @override
  State<DashboardSettingsScreen> createState() =>
      _DashboardSettingsScreenState();
}

class _DashboardSettingsScreenState extends State<DashboardSettingsScreen> {
  late DashboardPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.currentPreferences;
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'dashboard_preferences',
      jsonEncode(_preferences.toJson()),
    );
    if (mounted) {
      Navigator.pop(context, _preferences);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes del Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar',
            onPressed: _savePreferences,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Mostrar en Dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Promedio diario'),
                  value: _preferences.showMacrosCard,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        showMacrosCard: value,
                      );
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Grafico de tendencias'),
                  value: _preferences.showCaloriesChart,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        showCaloriesChart: value,
                      );
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Distribución de macronutrientes'),
                  value: _preferences.showMacrosPercentChart,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        showMacrosPercentChart: value,
                      );
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Top 5 alimentos'),
                  value: _preferences.showTopFoods,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(showTopFoods: value);
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Hábitos completados'),
                  value: _preferences.showHabitsCompletion,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        showHabitsCompletion: value,
                      );
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Análisis de nutrientes'),
                  value: _preferences.showNutrientsAnalysis,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        showNutrientsAnalysis: value,
                      );
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Alimentos sugeridos'),
                  // (opcional) subtitle: const Text('Muestra tarjeta con sugerencias'),
                  value: _preferences.showSuggestedFoods,
                  onChanged: (v) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        showSuggestedFoods: v,
                      );
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Incluir ayunos en promedios'),
                  subtitle: const Text(
                    'Incluir días de ayuno en el cálculo de promedios (con 0 calorías)',
                  ),
                  value: _preferences.includeFastingInAverages,
                  onChanged: (v) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        includeFastingInAverages: v,
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Incluir en exportación PDF',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Promedio diario'),
                  value: _preferences.exportMacrosCard,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        exportMacrosCard: value,
                      );
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Distribución porcentual de macros'),
                  value: _preferences.exportMacrosPercentChart,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        exportMacrosPercentChart: value,
                      );
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Datos diarios'),
                  value: _preferences.exportDailyData,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        exportDailyData: value,
                      );
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Top 5 alimentos'),
                  value: _preferences.exportTopFoods,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        exportTopFoods: value,
                      );
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Hábitos completados'),
                  value: _preferences.exportHabitsCompletion,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        exportHabitsCompletion: value,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Análisis de nutrientes'),
            value: _preferences.exportNutrientsAnalysis,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(
                  exportNutrientsAnalysis: value,
                );
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formato de análisis de nutrientes',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                RadioListTile<String>(
                  title: const Text('Lista diaria'),
                  value: 'daily',
                  groupValue: _preferences.nutrientsExportMode,
                  onChanged: (v) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        nutrientsExportMode: v,
                      );
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Barras (promedio del período)'),
                  value: 'avg_bars',
                  groupValue: _preferences.nutrientsExportMode,
                  onChanged: (v) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        nutrientsExportMode: v,
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _preferences = const DashboardPreferences();
              });
            },
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar valores predeterminados'),
          ),
        ],
      ),
    );
  }
}
