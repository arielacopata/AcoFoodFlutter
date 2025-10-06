import 'package:acofoodflutter/models/food.dart';
import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'services/database_service.dart';

import 'dart:async';
import 'models/food_entry.dart';
import 'models/food_group.dart';
import 'data/food_groups.dart';
import 'models/nutrition_report.dart';

import 'services/food_repository.dart';
import 'services/nutrition_calculator.dart';

import 'settings_drawer.dart';
import 'widgets/bluetooth_manager.dart';
import 'widgets/food_amount_sheet.dart';
import '../widgets/macro_progress_circle.dart';
import '../widgets/nutrition_report_sheet.dart';

import 'services/calorie_calculator.dart';
import 'services/export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'widgets/habits_modal.dart';
import 'models/habit.dart';
import 'screens/dashboard_screen.dart';
import '../models/dashboard_stats.dart';
import 'data/supplements_data.dart';

import 'package:file_picker/file_picker.dart';
import 'services/import_service.dart';
import 'models/recipe.dart';
import 'dart:io';

final StreamController<double> _weightController = StreamController.broadcast();
bool _isScaleConnected = false; // Agregar esta variabl

class HomePage extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onUpdateProfile;
  final VoidCallback onToggleTheme;

  const HomePage({
    super.key,
    required this.profile,
    required this.onUpdateProfile,
    required this.onToggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = "";
  double _weight = 0.0;
  double _tareWeight = 0.0;
  bool _scaleExpanded = false;
  bool _isSearchFocused = false;
  // Variables para recordatorios
  bool _b12Completed = false;
  bool _linoCompleted = false;
  bool _legumbresCompleted = false;

  bool _b12Enabled = true;
  bool _linoEnabled = true;
  bool _legumbresEnabled = true;
  String _sortOrder = 'alfabetico';
  Map<int, int> _foodUsageCounts = {};
  DateTime _selectedDate = DateTime.now();
  bool _isListView = false; // false = grilla, true = lista
  final FocusNode _searchFocusNode = FocusNode(); // <-- Agrega esto
  // Peso neto (siempre positivo para tu caso de uso)
  double get _netWeight => (_weight - _tareWeight).abs();

  List<FoodEntry> _history = [];
  List<FoodGroupDisplay> _displayGroups = [];

  List<RecipeIngredient> _pendingIngredients = [];
  bool _isBuildingMultiple = false;

  final FoodRepository _foodRepo = FoodRepository();
  final NutritionCalculator _calculator = NutritionCalculator();
  NutritionReport? _currentReport;

  @override
  void initState() {
    super.initState();
    _buildDisplayGroups();
    _loadHistory();
    _loadDailyReminders();
    _loadSortOrder();
    // 1. AÑADE un "oyente" al foco del buscador
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  Future<void> _loadSortOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final counts = await DatabaseService.instance.getFoodUsageCounts();
    setState(() {
      _sortOrder = prefs.getString('sort_order') ?? 'alfabetico';
      _foodUsageCounts = counts;
    });
    _buildDisplayGroups(); // Reconstruir con el nuevo orden
  }

  Future<bool?> _openSupplementSheet(Food supplement) async {
    _searchFocusNode.unfocus();

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _buildSupplementModal(supplement),
    );

    //print('DEBUG: result = $result'); // 👈 AGREGAR

    if (result != null && result['dose'] != null) {
      final entry = FoodEntry(
        food: supplement,
        grams: 0,
        isSupplement: true,
        supplementDose: result['dose'],
      );

      //print(        'DEBUG: Guardando entry: ${entry.food.name}, dosis: ${entry.supplementDose}, isSupplement: ${entry.isSupplement}',      ); // 👈 AGREGAR

      await DatabaseService.instance.createEntry(entry);

      //print('DEBUG: Entry guardado, recargando historial'); // 👈 AGREGAR

      _loadHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${supplement.name} registrado: ${result['dose']}'),
        ),
      );
      return true;
    }
    return false;
  }

  Widget _buildSupplementModal(Food supplement) {
    final doseController = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      '${supplement.emoji}  ${supplement.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Si es B12, mostrar botones rápidos
                if (supplement.id == 9001) ...[
                  const Text(
                    'Dosis común:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quickDoseButton(context, '500 mcg'),
                      _quickDoseButton(context, '1000 mcg'),
                      _quickDoseButton(context, '3500 mcg'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],

                if (supplement.id == 9004) ...[
                  const Text(
                    'Dosis común:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quickDoseButton(context, '150 mcg'),
                      _quickDoseButton(context, '225 mcg'),
                      _quickDoseButton(context, '325 mcg'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ Límite seguro: 1100 mcg/día',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],

                // Input libre
                const Text(
                  'Dosis personalizada:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: doseController,
                        decoration: const InputDecoration(
                          hintText: 'Ej: 2 cápsulas, 2000 UI',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (doseController.text.isNotEmpty) {
                          Navigator.pop(context, {'dose': doseController.text});
                        }
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickDoseButton(BuildContext context, String dose) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context, {'dose': dose}),
      child: Text(dose),
    );
  }

  /// Importar backup desde archivo JSON
  Future<void> _importBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final jsonContent = await file.readAsString();

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Importación'),
          content: const Text(
            '¿Deseas importar este backup?\n\n'
            'ADVERTENCIA: Esto reemplazará todos tus datos actuales.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Importar'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await ImportService.importFromJson(jsonContent);

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (success) {
        // 🔥 AGREGAR: Recargar perfil desde BD
        final newProfile = await DatabaseService.instance.getUserProfile();
        if (newProfile != null) {
          widget.onUpdateProfile(newProfile); // Actualizar perfil en el padre
        }

        // Recargar todo lo demás
        await _loadHistory();
        await _loadDailyReminders();
        await _loadSortOrder();
        _buildDisplayGroups();

        setState(() {}); // Forzar rebuild

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Backup importado exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error: Archivo de backup no válido'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al importar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mostrar modal de In/Out
  // REEMPLAZA el método _showInOutModal() completo en home_page.dart:

  void _showInOutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Importar / Exportar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SECCIÓN EXPORTAR
            const Text(
              'EXPORTAR DATOS DEL DÍA',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _exportAsText,
                    child: const Text('Como Texto\n(para Zepp)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _exportAsJson,
                    child: const Text('Como Archivo\n(Backup)'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // SECCIÓN IMPORTAR
            const Text(
              'IMPORTAR DATOS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context); // Cerrar el modal primero
                await _importBackup(); // Ejecutar la importación
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Restaurar desde Archivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showHabitsSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<List<Habit>>(
        future: DatabaseService.instance.getAllHabits(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Configurar tareas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          onPressed: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => HabitsModal(
                                onSettingsTap: _showHabitsSettings,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...snapshot.data!.map((habit) {
                  return CheckboxListTile(
                    secondary: Text(
                      habit.emoji ?? '',
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(habit.name),
                    value: habit.enabled,
                    onChanged: (value) async {
                      await DatabaseService.instance.updateHabitEnabled(
                        habit.id!,
                        value ?? true,
                      );
                      Navigator.pop(context);
                      _showHabitsSettings();
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadDailyReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _getTodayKey(); // 👈 Usar el mismo método

    setState(() {
      // Estados diarios (se resetean)
      _b12Completed =
          prefs.getBool('b12_completed_$todayKey') ??
          false; // 👈 Agregar _completed
      _linoCompleted = prefs.getBool('lino_completed_$todayKey') ?? false;
      _legumbresCompleted =
          prefs.getBool('legumbres_completed_$todayKey') ?? false;

      // Estados habilitados (permanentes)
      _b12Enabled = prefs.getBool('b12_enabled') ?? true;
      _linoEnabled = prefs.getBool('lino_enabled') ?? true;
      _legumbresEnabled = prefs.getBool('legumbres_enabled') ?? true;
    });
  }

  void _toggleReminder(String key) async {
    if (key == 'b12') {
      // Abrir modal de B12 en lugar de solo marcar como completado
      final b12Supplement = supplementsList.firstWhere((s) => s.id == 9001);
      final wasRegistered = await _openSupplementSheet(
        b12Supplement,
      ); // 👈 Declarar acá
      // Marcar como completado
      // Solo marcar como completado SI se registró
      if (wasRegistered == true) {
        // 👈 CAMBIAR
        setState(() => _b12Completed = true);
        final prefs = await SharedPreferences.getInstance();
        final todayKey = _getTodayKey();
        await prefs.setBool('b12_completed_$todayKey', true);
      }
    } else if (key == 'lino') {
      setState(() => _linoCompleted = true);
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _getTodayKey();
      await prefs.setBool('lino_completed_$todayKey', true);
    } else if (key == 'legumbres') {
      setState(() => _legumbresCompleted = true);
      final prefs = await SharedPreferences.getInstance();
      final todayKey = _getTodayKey();
      await prefs.setBool('legumbres_completed_$todayKey', true);
    }
  }

  Widget _buildReminderBanner() {
    String? currentReminder;
    String? reminderKey;

    if (!_b12Completed && _b12Enabled) {
      currentReminder = '💊 Recordatorio: Tomar B12';
      reminderKey = 'b12';
    } else if (!_linoCompleted && _linoEnabled) {
      currentReminder = '🌾 Recordatorio: Semillas de lino';
      reminderKey = 'lino';
    } else if (!_legumbresCompleted && _legumbresEnabled) {
      currentReminder = '🫘 Recordatorio: Remojar legumbres';
      reminderKey = 'legumbres';
    }

    if (currentReminder == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade100, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Text(
          currentReminder,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        trailing: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 24,
          ),
          onPressed: () => _toggleReminder(reminderKey!),
        ),
      ),
    );
  }

  // AGREGAR esta función en home_page.dart, cerca de las otras funciones de modales

  /// Modal para registrar Yodo
  Future<void> _showIodineModal() async {
    final TextEditingController doseController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🧂 Yodo (suplemento)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Dosis del suplemento',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Botones de dosis predefinidas
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, {'dose': '150 mcg'}),
                    child: const Text('150 mcg'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, {'dose': '225 mcg'}),
                    child: const Text('225 mcg'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, {'dose': '325 mcg'}),
                    child: const Text('325 mcg'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Input personalizado
            const Text(
              'O ingresa una dosis personalizada:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: doseController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      hintText: 'Ej: 400 mcg, 2000 UI',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (doseController.text.isNotEmpty) {
                      Navigator.pop(context, {'dose': doseController.text});
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Text(
              '⚠️ Límite seguro: 1100 mcg/día',
              style: TextStyle(fontSize: 11, color: Colors.orange),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    // Si se seleccionó una dosis, registrarla
    if (result != null && result['dose'] != null) {
      final iodineFood = supplementsList.firstWhere((s) => s.id == 9004);
      final entry = FoodEntry(
        food: iodineFood,
        grams: 0, // Los suplementos no tienen gramos
        isSupplement: true,
        supplementDose: result['dose'],
      );

      await DatabaseService.instance.createEntry(entry);
      _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yodo registrado: ${result['dose']}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Exportar como texto
  Future<void> _exportAsText() async {
    final text = ExportService.generateTextForZepp(_history);
    await ExportService.copyToClipboard(text);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Texto copiado al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Exportar como JSON
  // Elimina el import de file_picker
  // import 'package:file_picker/file_picker.dart';  // ← ELIMINA

  // Modifica _exportAsJson para usar share en lugar de guardar
  Future<void> _exportAsJson() async {
    try {
      final jsonContent = await ExportService.generateJsonBackup(_history);
      await ExportService.shareJsonFile(jsonContent);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup listo para compartir')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  // Elimina el método _importFromFile por ahora
  // (lo agregaremos más tarde con otra solución)

  // Función para mostrar información nutricional completa
  Future<void> _showNutritionInfo(FoodEntry entry) async {
    // Calculamos los valores para la cantidad específica
    final double factor = entry.grams / 100;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${entry.food.emoji} ${entry.food.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cantidad: ${entry.grams.toStringAsFixed(1)} g',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Divider(),
              _nutritionRow(
                'Calorías',
                (entry.food.calories * factor).toStringAsFixed(1),
                'kcal',
              ),
              _nutritionRow(
                'Proteínas',
                (entry.food.proteins * factor).toStringAsFixed(1),
                'g',
              ),
              _nutritionRow(
                'Carbohidratos',
                (entry.food.carbohydrates * factor).toStringAsFixed(1),
                'g',
              ),
              _nutritionRow(
                'Grasas',
                (entry.food.totalFats * factor).toStringAsFixed(1),
                'g',
              ),
              if (entry.food.fiber > 0)
                _nutritionRow(
                  'Fibra',
                  (entry.food.fiber * factor).toStringAsFixed(1),
                  'g',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // Widget helper para mostrar filas de información nutricional
  Widget _nutritionRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value $unit',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Función para editar la cantidad de un entry
  Future<void> _editEntry(FoodEntry entry) async {
    final newGrams = await showModalBottomSheet<double?>(
      context: context,
      builder: (ctx) => FoodAmountSheet(
        food: entry.food,
        isScaleConnected: _isScaleConnected,
        weightStream: _weightController.stream.map(
          (w) => (w - _tareWeight).abs(),
        ),
        onTare: _setTare,
      ),
    );

    if (newGrams != null && newGrams > 0) {
      // Actualizar el entry existente con la nueva cantidad
      final updatedEntry = FoodEntry(
        id: entry.id,
        food: entry.food,
        grams: newGrams,
        timestamp: entry.timestamp, // Mantiene el timestamp original
      );

      await DatabaseService.instance.updateEntry(updatedEntry);
      _loadHistory(); // Recarga el historial

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cantidad actualizada')));
    }
  }

  // Función para eliminar un entry del historial
  Future<void> _deleteEntry(FoodEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar ${entry.food.name} del historial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.deleteEntry(entry.id!);
      _loadHistory(); // Recarga el historial

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro eliminado')));
    }
  }

  Future<void> _showClearConfirmationDialog() async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Borrado"),
        content: const Text(
          "¿Estás seguro de que quieres borrar todos los registros de hoy? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false), // Devuelve 'false' si cancela
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(true), // Devuelve 'true' si confirma
            child: const Text("Borrar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // Si el usuario confirmó, procedemos a borrar
    if (confirmed == true) {
      await DatabaseService.instance.clearTodayHistory();
      _loadHistory(); // Recargamos el historial para actualizar la UI
    }
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadHistory();
  }

  void _nextDay() {
    final tomorrow = _selectedDate.add(const Duration(days: 1));
    final today = DateTime.now();

    // No permitir ir más allá de hoy
    if (tomorrow.isBefore(today) ||
        tomorrow.year == today.year &&
            tomorrow.month == today.month &&
            tomorrow.day == today.day) {
      setState(() {
        _selectedDate = tomorrow;
      });
      _loadHistory();
    }
  }

  String _getDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final yesterday = today.subtract(const Duration(days: 1));

    if (selected == today) {
      return 'Hoy';
    } else if (selected == yesterday) {
      return 'Ayer';
    } else {
      return DateFormat('EEE, d \'de\' MMM', 'es').format(_selectedDate);
    }
  }

  Future<void> _loadHistory() async {
    final entries = await DatabaseService.instance.getEntriesByDate(
      _selectedDate,
    );
    setState(() {
      _history = entries;
    });
    _recalculateTotals(); // Recalculamos al cargar
  }

  // 2. SIMPLIFICA este método.
  void _buildDisplayGroups() {
    final allFoods = _foodRepo.getAllFoods();
    setState(() {
      _displayGroups = getFoodGroups(
        allFoods,
        sortOrder: _sortOrder,
        usageCounts: _foodUsageCounts,
      );
    });
  }

  @override
  void dispose() {
    _weightController.close();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (_searchFocusNode.hasFocus && _scaleExpanded) {
      // Si el buscador gana el foco y el panel está expandido, lo cerramos.
      setState(() {
        _scaleExpanded = false;
      });
    }
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _setTare() {
    setState(() {
      _tareWeight = _weight;
    });

    // Solo mostrar snackbar si la balanza está conectada
    if (_isScaleConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tara establecida: ${_weight.toStringAsFixed(1)}g'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetTare() {
    setState(() {
      _tareWeight = 0.0;
    });
  }

  /// Dispara el cálculo de los totales nutricionales basados en el historial.
  Future<void> _recalculateTotals() async {
    // Si no hay nada en el historial, reseteamos el reporte.
    if (_history.isEmpty) {
      setState(() => _currentReport = null);
      // print("Historial vacío, reporte reseteado.");
      return;
    }

    // Llamamos a nuestro calculador
    final report = await _calculator.calculateDailyTotals(_history);

    setState(() {
      _currentReport = report;
    });
  }

  Future<void> _openFoodBottomSheet(Food food) async {
    _searchFocusNode.unfocus();
    final grams = await showModalBottomSheet<double?>(
      context: context,
      builder: (ctx) => FoodAmountSheet(
        food: food,
        isScaleConnected: true,
        weightStream: _weightController.stream.map(
          (w) => (w - _tareWeight).abs(),
        ),
        onTare: _setTare,
      ),
    );

    if (grams != null && grams > 0) {
      final fullFood = _foodRepo.getFoodById(food.id!);
      if (fullFood != null) {
        // Agregar a la lista temporal
        _pendingIngredients.add(
          RecipeIngredient(
            recipeId: 0, // Temporal, se asigna al guardar
            food: fullFood,
            grams: grams,
          ),
        );

        // Mostrar confirmación con opciones
        if (!mounted) return;

        final action = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Ingrediente agregado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✓ ${grams.toStringAsFixed(0)}g de ${fullFood.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_pendingIngredients.length > 1) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingredientes en esta comida:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  ..._pendingIngredients.map(
                    (ing) => Text(
                      '• ${ing.grams.toStringAsFixed(0)}g de ${ing.food.name}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context, 'add_more'),
                icon: const Icon(Icons.add),
                label: const Text('Agregar otro ingrediente'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'finish'),
                child: const Text('Finalizar'),
              ),
            ],
          ),
        );

        if (action == 'add_more') {
          // Volver a abrir la lista de alimentos para agregar otro
          setState(() {
            _isBuildingMultiple = true;
          });
          // No hacer nada más, el usuario volverá a seleccionar otro alimento
        } else if (action == 'finish') {
          // Registrar todos los ingredientes
          await _finishAddingIngredients();
        }
      }
    }
  }

  Future<void> _finishAddingIngredients() async {
    if (_pendingIngredients.isEmpty) return;

    // Si hay más de un ingrediente, preguntar si guardar como receta
    if (_pendingIngredients.length > 1 && mounted) {
      final saveAsRecipe = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Guardar como receta?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Has agregado varios ingredientes:'),
              const SizedBox(height: 8),
              ..._pendingIngredients.map(
                (ing) => Text(
                  '• ${ing.grams.toStringAsFixed(0)}g de ${ing.food.name}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '¿Quieres guardar esto como una receta para usarla más tarde?',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, solo registrar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, guardar receta'),
            ),
          ],
        ),
      );

      if (saveAsRecipe == true) {
        await _saveAsRecipe();
      }
    }

    // Registrar todos los ingredientes en el historial
    for (final ingredient in _pendingIngredients) {
      final newEntry = FoodEntry(
        food: ingredient.food,
        grams: ingredient.grams,
      );
      await DatabaseService.instance.createEntry(newEntry);
      await DatabaseService.instance.incrementFoodUsage(ingredient.food.id!);
    }

    // Limpiar la lista temporal
    setState(() {
      _pendingIngredients.clear();
      _isBuildingMultiple = false;
    });

    _setTare();
    _loadHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingredientes registrados'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveAsRecipe() async {
    final nameController = TextEditingController();

    final recipeName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre de la receta'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Ej: Desayuno habitual',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context, nameController.text);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (recipeName != null && recipeName.isNotEmpty) {
      final recipe = Recipe(
        name: recipeName,
        emoji: '🍽️',
        createdAt: DateTime.now(),
      );

      await DatabaseService.instance.saveRecipe(recipe, _pendingIngredients);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receta "$recipeName" guardada'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showVariantDialog(FoodGroupDisplay group) async {
    final selected = await showDialog<Food>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Elige tipo de ${group.groupName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: group.items
              .map(
                (food) => ListTile(
                  title: Text(food.name),
                  onTap: () => Navigator.pop(ctx, food),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected != null) {
      _openFoodBottomSheet(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos la lista completa de alimentos desde el repositorio.
    final allFoods = _foodRepo.getAllFoods();

    // 2. Definimos la lista que se mostrará en pantalla.
    List<dynamic> displayItems;

    if (_searchQuery.isEmpty) {
      // 3. SI NO HAY BÚSQUEDA: mostramos los grupos predefinidos.
      displayItems = _displayGroups;
    } else {
      // 4. Mapa de nutrientes para filtrado
      final nutrientMap = {
        // Macronutrientes
        'proteina': (Food f) => f.proteins,
        'proteínas': (Food f) => f.proteins,
        'carbohidratos': (Food f) => f.carbohydrates,
        'fibra': (Food f) => f.fiber,
        'grasas': (Food f) => f.totalFats,

        // Ácidos grasos
        'omega3': (Food f) => f.omega3,
        'omega-3': (Food f) => f.omega3,
        'omega6': (Food f) => f.omega6,
        'omega-6': (Food f) => f.omega6,
        'omega9': (Food f) => f.omega9,
        'omega-9': (Food f) => f.omega9,

        // Vitaminas
        'vitamina a': (Food f) => f.vitaminA,
        'vitamina c': (Food f) => f.vitaminC,
        'vitamina d': (Food f) => f.vitaminD,
        'vitamina e': (Food f) => f.vitaminE,
        'vitamina k': (Food f) => f.vitaminK,
        'vitamina b1': (Food f) => f.vitaminB1,
        'b1': (Food f) => f.vitaminB1,
        'tiamina': (Food f) => f.vitaminB1,
        'vitamina b2': (Food f) => f.vitaminB2,
        'b2': (Food f) => f.vitaminB2,
        'riboflavina': (Food f) => f.vitaminB2,
        'vitamina b3': (Food f) => f.vitaminB3,
        'b3': (Food f) => f.vitaminB3,
        'niacina': (Food f) => f.vitaminB3,
        'vitamina b4': (Food f) => f.vitaminB4,
        'b4': (Food f) => f.vitaminB4,
        'colina': (Food f) => f.vitaminB4,
        'vitamina b5': (Food f) => f.vitaminB5,
        'b5': (Food f) => f.vitaminB5,
        'vitamina b6': (Food f) => f.vitaminB6,
        'b6': (Food f) => f.vitaminB6,
        'vitamina b7': (Food f) => f.vitaminB7,
        'b7': (Food f) => f.vitaminB7,
        'biotina': (Food f) => f.vitaminB7,
        'vitamina b9': (Food f) => f.vitaminB9,
        'b9': (Food f) => f.vitaminB9,
        'folato': (Food f) => f.vitaminB9,
        'vitamina b12': (Food f) => f.vitaminB12,
        'b12': (Food f) => f.vitaminB12,

        // Minerales
        'calcio': (Food f) => f.calcium,
        'hierro': (Food f) => f.iron,
        'magnesio': (Food f) => f.magnesium,
        'fosforo': (Food f) => f.phosphorus,
        'fósforo': (Food f) => f.phosphorus,
        'potasio': (Food f) => f.potassium,
        'sodio': (Food f) => f.sodium,
        'zinc': (Food f) => f.zinc,
        'cobre': (Food f) => f.copper,
        'manganeso': (Food f) => f.manganese,
        'selenio': (Food f) => f.selenium,
        'yodo': (Food f) => f.iodine,

        // Aminoácidos
        'histidina': (Food f) => f.histidine,
        'isoleucina': (Food f) => f.isoleucine,
        'leucina': (Food f) => f.leucine,
        'lisina': (Food f) => f.lysine,
        'metionina': (Food f) => f.methionine,
        'fenilalanina': (Food f) => f.phenylalanine,
        'treonina': (Food f) => f.threonine,
        'triptofano': (Food f) => f.tryptophan,
        'triptófano': (Food f) => f.tryptophan,
        'valina': (Food f) => f.valine,
      };

      final query = _searchQuery.toLowerCase().trim();

      // Verificar si la búsqueda coincide con un nutriente
      if (nutrientMap.containsKey(query)) {
        // Ordenar por contenido del nutriente
        final nutrientGetter = nutrientMap[query]!;
        displayItems = allFoods.toList()
          ..sort((a, b) => nutrientGetter(b).compareTo(nutrientGetter(a)));
      } else {
        // Búsqueda normal por nombre
        displayItems = allFoods.where((food) {
          return food.name.toLowerCase().contains(query) ||
              (food.fullName?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    }
    // --- LÓGICA DE CÁLCULO DE METAS ---
    // (La ponemos aquí mismo para tener todo a mano)

    // 1. Calorías objetivo calculadas según el perfil
    final double totalCaloriesGoal =
        widget.profile.goalCalories?.toDouble() ??
        CalorieCalculator.calculateRecommendedCalories(
          dob: widget.profile.dob,
          gender: widget.profile.gender,
          weight: widget.profile.weight,
          height: widget.profile.height,
          lifestyle: widget.profile.lifestyle,
          exerciseLevel: widget.profile.exerciseLevel,
          expenditure: widget.profile.expenditure,
        );

    // 2. Calculamos los gramos objetivo para cada macro
    final double proteinGoalGrams =
        (totalCaloriesGoal * ((widget.profile.protein ?? 30) / 100)) / 4;
    final double carbsGoalGrams =
        (totalCaloriesGoal * ((widget.profile.carbs ?? 50) / 100)) / 4;
    final double fatGoalGrams =
        (totalCaloriesGoal * ((widget.profile.fat ?? 20) / 100)) / 9;

    // 3. Calculamos el porcentaje de progreso (0.0 a 1.0)
    // Añadimos una comprobación para evitar dividir por cero si la meta es 0
    // REEMPLAZA CON:
    final double proteinPercentage =
        _currentReport != null && proteinGoalGrams > 0
        ? _currentReport!.proteins / proteinGoalGrams
        : 0.0;
    final double carbsPercentage = _currentReport != null && carbsGoalGrams > 0
        ? _currentReport!.carbohydrates / carbsGoalGrams
        : 0.0;
    final double fatPercentage = _currentReport != null && fatGoalGrams > 0
        ? _currentReport!.totalFats / fatGoalGrams
        : 0.0;
    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      }, // Solo grupos con resultados
      child: Scaffold(
        appBar: AppBar(
          title: InkWell(
            onTap: () {
              setState(() {
                _isListView = !_isListView;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('AcoFood'),
                const SizedBox(width: 8),
                Icon(_isListView ? Icons.list : Icons.grid_view, size: 20),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.task_alt),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) =>
                      HabitsModal(onSettingsTap: _showHabitsSettings),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: widget.onToggleTheme,
            ),
          ],
        ),
        drawer: SettingsDrawer(
          profile: widget.profile,
          onProfileUpdated: (newProfile) {
            // 👈 AGREGA ESTO
            widget.onUpdateProfile(newProfile);
            setState(() {}); // Fuerza rebuild para actualizar la UI
          },
          onHistoryChanged: () {
            _loadHistory(); // Recarga el historial
          },
          onOpenImportExport: _showInOutModal,
          onRecipeUsed: () {
            _loadHistory();
            _setTare();
          },
          onSortOrderChanged: (newOrder) async {
            setState(() => _sortOrder = newOrder);
            final counts = await DatabaseService.instance.getFoodUsageCounts();
            setState(() => _foodUsageCounts = counts);
            _buildDisplayGroups();
          },
          onRemindersChanged: () {
            // Agregar esto
            _loadDailyReminders();
          },
        ),
        body: Column(
          children: [
            // Panel de balanza colapsable
            _buildReminderBanner(),
            Card(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8), // Ya lo tienes
              child: Column(
                children: [
                  // Header siempre visible - COMPACTAR ESTO
                  InkWell(
                    onTap: () =>
                        setState(() => _scaleExpanded = !_scaleExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ), // Reducir de 16 a 12/8
                      child: Row(
                        children: [
                          if (!_isScaleConnected)
                            const Text(
                              'Balanza',
                              style: TextStyle(
                                fontSize: 14, // Reducir de 16 a 14
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const Spacer(),
                          BluetoothManager(
                            onWeightChanged: (grams) {
                              setState(() => _weight = grams);
                              _weightController.add(grams);
                            },
                            onConnectionChanged: (isConnected) {
                              setState(() => _isScaleConnected = isConnected);
                            },
                          ),
                          // Botones más compactos
                          if (_tareWeight == 0)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: const Size(0, 32),
                              ),
                              onPressed: _weight != 0 ? _setTare : null,
                              icon: const Icon(Icons.exposure_zero, size: 16),
                              label: const Text(
                                'TARA',
                                style: TextStyle(fontSize: 12),
                              ),
                            )
                          else
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(0, 28),
                              ),
                              onPressed: _resetTare,
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text(
                                'RESET',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(
                            _scaleExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Contenido expandible
                  if (_scaleExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12), // Reducir de 16 a 12
                      child: Column(
                        children: [
                          if (_tareWeight != 0)
                            Text(
                              "Bruto: ${_weight.toStringAsFixed(1)} g",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          Text(
                            "${_netWeight.toStringAsFixed(1)} g",
                            style: TextStyle(
                              fontSize: 40, // Reducir de 48 a 40
                              fontWeight: FontWeight.bold,
                              color: _tareWeight > 0 ? Colors.green : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Grid de alimentos
            Expanded(
              child: _isListView
                  ? ListView.builder(
                      itemCount: _displayGroups.length,
                      itemBuilder: (context, index) {
                        final group = _displayGroups[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header de categoría
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                '${group.emoji} ${group.groupName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Lista compacta de alimentos
                            ...group.items.map(
                              (food) => ListTile(
                                dense: true,
                                leading: Text(
                                  food.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                title: Text(food.name),
                                subtitle: Text('${food.calories} kcal/100g'),
                                trailing: Text(
                                  '${food.proteins.toStringAsFixed(1)}P • ${food.carbohydrates.toStringAsFixed(1)}C • ${food.totalFats.toStringAsFixed(1)}G',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onTap: () => _openFoodBottomSheet(food),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(
                          context,
                        ), // 👈 CAMBIAR AQUÍ
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),

                      // 5. ¡AQUÍ USAMOS LA VARIABLE!
                      itemCount: displayItems.length + supplementsList.length,
                      itemBuilder: (context, index) {
                        if (index < displayItems.length) {
                          final item = displayItems[index];

                          // 6. RENDERIZADO INTELIGENTE
                          if (item is FoodGroupDisplay) {
                            // Si el item es un Grupo, lo mostramos como grupo
                            return InkWell(
                              onTap: () {
                                if (item.hasMultiple) {
                                  _showVariantDialog(item);
                                } else {
                                  _openFoodBottomSheet(item.items.first);
                                }
                              },
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.emoji,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.groupName,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else if (item is Food) {
                            // Si el item es un Alimento (de la búsqueda), lo mostramos individualmente
                            return InkWell(
                              onTap: () => _openFoodBottomSheet(item),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.emoji,
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        } // Cierra el if (index < displayItems.length)
                        else {
                          // Es un suplemento
                          final supplement =
                              supplementsList[index - displayItems.length];
                          return GestureDetector(
                            onTap: () => _openSupplementSheet(supplement),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      supplement.emoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      supplement.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } // Fallback por si acaso
                      },
                    ),
            ),

            if (!_isSearchFocused)
              // Historial colapsable
              Column(
                children: [
                  // ¡AQUÍ VA EL NUEVO WIDGET DE TOTALES!
                  if (_currentReport != null)
                    // AHORA CONSTRUIMOS EL WIDGET CON LOS DATOS REALES
                    Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // --- NUEVO HEADER CON BOTÓN ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Título con calorías
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 16),
                                    children: [
                                      const TextSpan(text: "🔥 "),
                                      TextSpan(
                                        text:
                                            "${_currentReport!.calories.toStringAsFixed(0)} / ${totalCaloriesGoal.toStringAsFixed(0)} kcal",
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ), // Más compacto
                                        minimumSize: const Size(
                                          0,
                                          0,
                                        ), // Sin tamaño mínimo
                                        tapTargetSize: MaterialTapTargetSize
                                            .shrinkWrap, // Reduce el área táctil
                                      ),
                                      onPressed: () {
                                        if (_currentReport != null) {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) =>
                                                NutritionReportSheet(
                                                  report: _currentReport!,
                                                  totalCaloriesGoal:
                                                      totalCaloriesGoal,
                                                  proteinGoalGrams:
                                                      proteinGoalGrams,
                                                  carbsGoalGrams:
                                                      carbsGoalGrams,
                                                  fatGoalGrams: fatGoalGrams,
                                                  userWeight:
                                                      widget.profile.weight ??
                                                      70.0,
                                                ),
                                          );
                                        }
                                      },
                                      child: const Text(
                                        "Reporte",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: _showInOutModal,
                                      child: const Text(
                                        "In/Out",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // --- CÍRCULOS DE PROGRESO ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                MacroProgressCircle(
                                  title: "Proteínas",
                                  emoji: "💪",
                                  percentage: proteinPercentage,
                                  progressColor: Colors.blue,
                                ),
                                MacroProgressCircle(
                                  title: "Carbs",
                                  emoji: "🍞",
                                  percentage:
                                      carbsPercentage, // Aún con valor fijo
                                  progressColor: Colors.orange,
                                ),
                                MacroProgressCircle(
                                  title: "Grasas",
                                  emoji: "🥑",
                                  percentage:
                                      fatPercentage, // Aún con valor fijo
                                  progressColor: Colors.yellow.shade700,
                                ),
                              ],
                            ),

                            // Ya no tenemos las filas de texto aquí abajo.
                          ],
                        ),
                      ),
                    ),
                  ExpansionTile(
                    key: ValueKey('history_${_selectedDate.toIso8601String()}'),
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ), // Sin padding vertical
                    dense: true, // Hace el tile más compacto
                    visualDensity:
                        VisualDensity.compact, // Reduce aún más la altura
                    leading: const Icon(
                      Icons.history,
                      size: 18,
                    ), // Icono más pequeño
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _previousDay,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_getDateLabel()} (${_history.length} registros)',
                            style: const TextStyle(
                              fontSize: 13,
                            ), // Texto más pequeño
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _nextDay,
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          key: ValueKey(
                            'list_${_history.length}_${_history.hashCode}',
                          ),
                          shrinkWrap: true,
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final entry = _history[index];
                            return ListTile(
                              leading: Text(
                                entry.food.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                entry.isSupplement
                                    ? "${entry.food.name} - ${entry.supplementDose}" // 👈 Para suplementos: mostrar dosis
                                    : "${entry.food.fullName} - ${entry.grams.toStringAsFixed(1)} g", // Para alimentos: gramos
                              ),
                              subtitle: Text(
                                entry.isSupplement
                                    ? "Suplemento" // 👈 Para suplementos: texto simple
                                    : "${(entry.food.calories * entry.grams / 100).toStringAsFixed(0)} kcal", // Para alimentos: calorías
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'info':
                                      _showNutritionInfo(
                                        entry,
                                      ); // 👈 Nueva función
                                      break;
                                    case 'edit':
                                      _editEntry(entry); // 👈 Nueva función
                                      break;
                                    case 'delete':
                                      _deleteEntry(entry); // 👈 Nueva función
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'info',
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline),
                                        SizedBox(width: 8),
                                        Text('Ver información'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Editar cantidad'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Eliminar',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            // Buscador
            Container(
              margin: const EdgeInsets.all(12),
              padding: EdgeInsets.all(_isSearchFocused ? 12 : 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Focus(
                onFocusChange: (hasFocus) {
                  setState(() {
                    _isSearchFocused = hasFocus;
                  });
                },
                child: TextField(
                  focusNode: _searchFocusNode,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: _isSearchFocused ? 22 : 16),
                  decoration: InputDecoration(
                    hintText: 'BUSCAR ALIMENTO...',
                    hintStyle: TextStyle(
                      fontSize: _isSearchFocused ? 22 : 16,
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: _isSearchFocused ? 24 : 20,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: _isSearchFocused ? 24 : 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Tablet 2K en portrait (ancho > 768px)
    if (width >= 768) {
      return 5; // 5 columnas para tablets
    }

    // Tablet mediana (ancho entre 600-768px)
    if (width >= 600) {
      return 4; // 4 columnas para tablets medianas
    }

    // Mobile (ancho < 600px)
    return 3; // 3 columnas para móviles
  }
}
