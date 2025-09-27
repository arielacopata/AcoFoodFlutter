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

final StreamController<double> _weightController = StreamController.broadcast();

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
    final grams = await showModalBottomSheet<double?>(
      context: context,
      builder: (ctx) => FoodAmountSheet(
        food: food,
        isScaleConnected: true,
        weightStream: _weightController.stream.map((w) => (w - _tareWeight).abs()),
      ),
    );

    if (grams != null && grams > 0) {
      setState(() {
        _history.add(FoodEntry(food: food, grams: grams));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFoods = foods.where((food) {
      final query = _searchQuery.toLowerCase();
      return food.name.toLowerCase().contains(query) ||
          (food.fullName?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
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
          BluetoothManager(
            onWeightChanged: (grams) {
              setState(() => _weight = grams);
              _weightController.add(grams);
            },
          ),

          // Panel de balanza con TARA
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Balanza MACROSCALE",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  
                  // Peso bruto (gris si hay tara activa)
                  if (_tareWeight > 0)
                    Text(
                      "Bruto: ${_weight.toStringAsFixed(1)} g",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  
                  // Peso neto (principal)
                  Text(
                    "${_netWeight.toStringAsFixed(1)} g",
                    style: TextStyle(
                      fontSize: _tareWeight > 0 ? 32 : 32,
                      fontWeight: FontWeight.bold,
                      color: _tareWeight > 0 ? Colors.green : null,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  Text(
                    "${(_netWeight * 7).toStringAsFixed(0)} kcal",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Botones de tara
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _weight > 0 ? _setTare : null,
                        icon: const Icon(Icons.exposure_zero, size: 18),
                        label: Text(_tareWeight > 0 
                            ? 'TARA (${_tareWeight.toStringAsFixed(0)}g)' 
                            : 'TARA'),
                      ),
                      if (_tareWeight > 0) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _resetTare,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reset'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
              itemCount: filteredFoods.length,
              itemBuilder: (context, index) {
                final food = filteredFoods[index];
                return InkWell(
                  onTap: () => _openFoodBottomSheet(food),
                  child: Card(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            food.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
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
              },
            ),
          ),
          
          // Historial
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final entry = _history[index];
                return ListTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: Text("${entry.food.name} - ${entry.grams.toStringAsFixed(1)} g"),
                  subtitle: Text(entry.timestamp.toLocal().toString()),
                );
              },
            ),
          ),
          
          // Buscador
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Buscar alimento...",
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
