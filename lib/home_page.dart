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
  // final _simulator = ScaleSimulator();
  double _weight = 0.0;

List<FoodEntry> _history = [];

  @override
  void initState() {
    super.initState();
   //simulator.start();
   //simulator.stream.listen((w) {
   // setState(() {
   //   _weight = w;
   // });
   // });
  }

  @override
  void dispose() {
    //_simulator.dispose();
	_weightController.close();
    super.dispose();
  }

  Future<void> _openFoodBottomSheet(Food food) async {
    // en producción, reemplazá por el estado real del BLE
    final bool isScaleConnected = true; // o false si no hay conexión
    final double currentWeight = _weight; // del simulador o BLE real

final grams = await showModalBottomSheet<double?>(
  context: context,
  builder: (ctx) => FoodAmountSheet(
    food: food,
    isScaleConnected: true,
    weightStream: _weightController.stream,
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

          // 📦 Panel de balanza
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
                  Text(
                    "${_weight.toStringAsFixed(1)} g",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${(_weight * 7).toStringAsFixed(0)} kcal",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 📦 Grid de alimentos
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
            // 📜 historial
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
          // 📦 Buscador
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
                hintText: "🔎 Buscar alimento...",
                border: InputBorder.none,
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
