import 'package:flutter/material.dart';
import '../models/dashboard_preferences.dart';

class ReportSetupScreen extends StatefulWidget {
  final DashboardPreferences current;
  const ReportSetupScreen({super.key, required this.current});

  @override
  State<ReportSetupScreen> createState() => _ReportSetupScreenState();
}

class _ReportSetupScreenState extends State<ReportSetupScreen> {
  late String _style; // 'minimal' | 'classic'
  late bool _zebra;
  late String _habitsPageMode; // '30days' | 'always' | 'never'
  late String _pageFormat; // 'a4' | 'letter'
  late bool _exportNutrients;

  @override
  void initState() {
    super.initState();
    _style = widget.current.reportStyle;
    _zebra = widget.current.tableZebra;
    _habitsPageMode = widget.current.habitsPageMode;
    _pageFormat = widget.current.pageFormat;
    _exportNutrients = widget.current.exportNutrientsAnalysis;
  }

  Future<void> _saveAndClose() async {
    final updated = widget.current.copyWith(
      reportStyle: _style,
      tableZebra: _zebra,
      habitsPageMode: _habitsPageMode,
      pageFormat: _pageFormat,
      exportNutrientsAnalysis: _exportNutrients,
    );
    if (mounted) Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Reporte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar',
            onPressed: _saveAndClose,
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          await _saveAndClose();
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Estilo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
            value: _style,
            items: const [
              DropdownMenuItem(value: 'minimal', child: Text('Minimalista (actual)')),
              DropdownMenuItem(value: 'classic', child: Text('Clásico (con período/rango)')),
            ],
            onChanged: (v) => setState(() => _style = v ?? 'minimal'),
          ),
          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text('Zebra en tablas'),
            value: _zebra,
            onChanged: (v) => setState(() => _zebra = v),
          ),

          const SizedBox(height: 8),
          const Text('Hábitos en nueva página'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _habitsPageMode,
            items: const [
              DropdownMenuItem(value: '30days', child: Text('Solo en 30 días')),
              DropdownMenuItem(value: 'always', child: Text('Siempre')),
              DropdownMenuItem(value: 'never', child: Text('Nunca')),
            ],
            onChanged: (v) => setState(() => _habitsPageMode = v ?? '30days'),
          ),

          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Incluir análisis de nutrientes'),
            value: _exportNutrients,
            onChanged: (v) => setState(() => _exportNutrients = v),
          ),

          const SizedBox(height: 8),
          const Text('Tamaño de página'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _pageFormat,
            items: const [
              DropdownMenuItem(value: 'a4', child: Text('A4')),
              DropdownMenuItem(value: 'letter', child: Text('Letter')),
            ],
            onChanged: (v) => setState(() => _pageFormat = v ?? 'a4'),
          ),
        ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saveAndClose,
              icon: const Icon(Icons.check),
              label: const Text('Guardar'),
            ),
          ),
        ),
      ),
    );
  }
}
