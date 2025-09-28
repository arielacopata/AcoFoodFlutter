import 'package:acofood2/models/food.dart';
import 'package:flutter/material.dart';
import 'services/scale_simulator.dart';
import 'models/user_profile.dart';
import 'settings_drawer.dart';
import 'data/foods.dart';
import 'widgets/food_amount_sheet.dart';
import 'widgets/bluetooth_manager.dart';
import 'dart:async';
import 'models/food_entry.dart';
import 'models/food_group.dart';
import 'data/food_groups.dart';

final StreamController<double> _weightController = StreamController.broadcast();
bool _isScaleConnected = false; // Agregar esta variable

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _weightController.close();
    _searchFocusNode.dispose();
    super.dispose();
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
      setState(() {
        _history.add(FoodEntry(food: food, grams: grams));
      });
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
  final filteredGroups = _searchQuery.isEmpty
      ? foodGroups // Sin bÃºsqueda, mostrar todo normal
      : foodGroups.map((group) {
          final query = _searchQuery.toLowerCase();
          
          // Filtrar solo los items que coinciden
          final matchingItems = group.items.where((food) =>
            food.name.toLowerCase().contains(query) ||
            (food.fullName?.toLowerCase().contains(query) ?? false)
          ).toList();
          
          return FoodGroupDisplay(
            groupName: group.groupName,
            emoji: group.emoji,
            items: matchingItems,
          );
        }).where((group) => group.items.isNotEmpty).toList();
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
                  onTap: () => setState(() => _scaleExpanded = !_scaleExpanded),
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
              // Mostrar items individuales si hay búsqueda, grupos si no hay
              itemCount: _searchQuery.isEmpty 
                  ? filteredGroups.length 
                  : filteredGroups.expand((g) => g.items).length,
              itemBuilder: (context, index) {
                if (_searchQuery.isEmpty) {
                  // Modo normal: mostrar grupos
                  final group = filteredGroups[index];
                  return InkWell(
                    onTap: () {
                      if (group.hasMultiple) {
                        _showVariantDialog(group);
                      } else {
                        _openFoodBottomSheet(group.items.first);
                      }
                    },
                    child: Card(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(group.emoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 6),
                            Text(
                              group.groupName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // Modo búsqueda: mostrar items individuales
                  final allItems = filteredGroups.expand((g) => g.items).toList();
                  final food = allItems[index];
                  return InkWell(
                    onTap: () => _openFoodBottomSheet(food),
                    child: Card(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(food.emoji ?? "🍽️", style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 6),
                            Text(
                              food.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // Historial colapsable
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
                      leading: const Icon(Icons.restaurant_menu),
                      title: Text(
                        "${entry.food.name} - ${entry.grams.toStringAsFixed(1)} g",
                      ),
                      subtitle: Text(entry.timestamp.toLocal().toString()),
                    );
                  },
                ),
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
                    color: Colors.grey[400]
                  ),
                  prefixIcon: Icon(Icons.search, size: _isSearchFocused ? 24 : 20),
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