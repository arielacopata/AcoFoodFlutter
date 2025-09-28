import 'package:acofoodflutter/models/food.dart';
import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'data/foods.dart';
import 'services/database_service.dart';

import 'dart:async';
import 'models/food_entry.dart';
import 'models/food_group.dart';
import 'data/food_groups.dart';
import 'models/nutrition_report.dart';

import 'services/food_repository.dart';
import 'services/nutrition_calculator.dart';
import 'services/scale_simulator.dart';

import 'settings_drawer.dart';
import 'widgets/bluetooth_manager.dart';
import 'widgets/food_amount_sheet.dart';
import '../widgets/macro_progress_circle.dart';
import '../widgets/nutrition_report_sheet.dart';

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
  final FocusNode _searchFocusNode = FocusNode(); // <-- Agrega esto
  // Peso neto (siempre positivo para tu caso de uso)
  double get _netWeight => (_weight - _tareWeight).abs();

  List<FoodEntry> _history = [];
  List<FoodGroupDisplay> _displayGroups = [];

  final FoodRepository _foodRepo = FoodRepository();
  final NutritionCalculator _calculator = NutritionCalculator();
  NutritionReport? _currentReport;

  @override
  void initState() {
    super.initState();
    _buildDisplayGroups();
    _loadHistory();
    // 1. AÑADE un "oyente" al foco del buscador
    _searchFocusNode.addListener(_onSearchFocusChange);
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

  Future<void> _loadHistory() async {
    final entries = await DatabaseService.instance.getTodayEntries();
    setState(() {
      _history = entries;
    });
    _recalculateTotals(); // Recalculamos al cargar
  }

  // 2. SIMPLIFICA este método.
  void _buildDisplayGroups() {
    final allFoods = _foodRepo.getAllFoods();
    // Ahora solo llama a la función externa, pasándole los datos correctos.
    setState(() {
      _displayGroups = getFoodGroups(allFoods);
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

  void _setTare() {
    setState(() {
      _tareWeight = _weight;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tara establecida: ${_weight.toStringAsFixed(1)}g'),
        duration: const Duration(seconds: 2),
      ),
    );
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
      print("Historial vacío, reporte reseteado.");
      return;
    }

    // Llamamos a nuestro calculador
    final report = await _calculator.calculateDailyTotals(_history);

    setState(() {
      _currentReport = report;
    });

    // Imprimimos en la consola para verificar que todo funciona
    print("--- REPORTE ACTUALIZADO ---");
    print("Calorías: ${report.calories.toStringAsFixed(2)}");
    print("Proteínas: ${report.proteins.toStringAsFixed(2)} g");
    print("Carbs: ${report.carbohydrates.toStringAsFixed(2)} g");
    print("Grasas: ${report.totalFats.toStringAsFixed(2)} g");
    print("-------------------------");
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
      ),
    );

    if (grams != null && grams > 0) {
      final fullFood = _foodRepo.getFoodById(food.id!);
      if (fullFood != null) {
        final newEntry = FoodEntry(food: fullFood, grams: grams);

        // Guarda en la base de datos
        await DatabaseService.instance.createEntry(newEntry);

        // Recarga el historial desde la base de datos para tener todo sincronizado
        _loadHistory();
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
      // (Asegúrate de tener food_groups.dart importado para que esto funcione)
      displayItems = _displayGroups;
    } else {
      // 4. SI HAY BÚSQUEDA: mostramos una lista plana de alimentos filtrados.
      displayItems = allFoods.where((food) {
        final query = _searchQuery.toLowerCase();
        return food.name.toLowerCase().contains(query) ||
            (food.fullName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    // --- LÓGICA DE CÁLCULO DE METAS ---
    // (La ponemos aquí mismo para tener todo a mano)

    // 1. Calorías objetivo (ejemplo: 2000 kcal, luego lo haremos configurable)
    const double totalCaloriesGoal = 2000;

    // 2. Calculamos los gramos objetivo para cada macro
    final double proteinGoalGrams =
        (totalCaloriesGoal * (widget.profile.protein / 100)) / 4;
    final double carbsGoalGrams =
        (totalCaloriesGoal * (widget.profile.carbs / 100)) / 4;
    final double fatGoalGrams =
        (totalCaloriesGoal * (widget.profile.fat / 100)) / 9;

    // 3. Calculamos el porcentaje de progreso (0.0 a 1.0)
    // Añadimos una comprobación para evitar dividir por cero si la meta es 0
    final double proteinPercentage = proteinGoalGrams > 0
        ? _currentReport!.proteins / proteinGoalGrams
        : 0.0;
    final double carbsPercentage = carbsGoalGrams > 0
        ? _currentReport!.carbohydrates / carbsGoalGrams
        : 0.0;
    final double fatPercentage = fatGoalGrams > 0
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
          title: const Text("AcoFood"),
          actions: [
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: widget.onToggleTheme,
            ),
          ],
        ),
        drawer: SettingsDrawer(
          profile: widget.profile,
          onUpdateProfile: widget.onUpdateProfile,
        ),
        body: Column(
          children: [
            // Panel de balanza colapsable
            Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header siempre visible
                  InkWell(
                    onTap: () =>
                        setState(() => _scaleExpanded = !_scaleExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          if (!_isScaleConnected) // Solo mostrar cuando NO estÃ¡ conectada
                            const Text(
                              'Balanza',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                          // Botón TARA/RESET
                          if (_tareWeight == 0)
                            OutlinedButton.icon(
                              onPressed: _weight > 0 ? _setTare : null,
                              icon: const Icon(Icons.exposure_zero, size: 18),
                              label: const Text('TARA'),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: _resetTare,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('RESET'),
                                ),
                              ],
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            _scaleExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Contenido expandible
                  if (_scaleExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Peso bruto (si hay tara)
                          if (_tareWeight > 0)
                            Text(
                              "Bruto: ${_weight.toStringAsFixed(1)} g",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),

                          // Peso neto
                          Text(
                            "${_netWeight.toStringAsFixed(1)} g",
                            style: TextStyle(
                              fontSize: 48,
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
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                // 5. ¡AQUÍ USAMOS LA VARIABLE!
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
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
                    );
                  } else if (item is Food) {
                    // Si el item es un Alimento (de la búsqueda), lo mostramos individualmente
                    return InkWell(
                      onTap: () => _openFoodBottomSheet(item),
                      child: Card(
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
                    );
                  }
                  return const SizedBox.shrink(); // Fallback por si acaso
                },
              ),
            ),

            if (!_isSearchFocused)
              // Historial colapsable
              Column(
                children: [
                  // El historial que ya tenías

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
                                Text(
                                  "Totales del Día",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    // Si hay un reporte, mostramos el modal
                                    if (_currentReport != null) {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled:
                                            true, // Importante para que no lo tape el teclado
                                        backgroundColor: Colors
                                            .transparent, // Hacemos el fondo transparente
                                        builder: (context) =>
                                            NutritionReportSheet(
                                              report: _currentReport!,
                                            ),
                                      );
                                    }
                                  },
                                  child: const Text("Reporte"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

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
                    initiallyExpanded: false,
                    leading: const Icon(Icons.history),
                    title: Text('Historial (${_history.length} registros)'),
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final entry = _history[index];
                            return ListTile(
                              leading: Text(
                                entry.food.emoji,
                              ), // Usamos el emoji
                              title: Text(
                                "${entry.food.name} - ${entry.grams.toStringAsFixed(1)} g",
                              ),
                              subtitle: Text(
                                "${entry.food.calories.toStringAsFixed(0)} kcal (por 100g)",
                              ),
                              trailing: const Icon(Icons.more_vert),
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
}
