import 'dart:async';

import 'package:acofood2/models/food.dart';
import 'package:flutter/material.dart';

import 'data/foods.dart';
import 'models/food_entry.dart';
import 'models/user_profile.dart';
import 'settings_drawer.dart';
import 'widgets/bluetooth_manager.dart';
import 'widgets/food_amount_sheet.dart';

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
  final TextEditingController _searchController = TextEditingController();
  late final StreamController<double> _weightController;
  String _searchQuery = "";
  double _weight = 0.0;
  bool _isScaleConnected = false;
  final List<FoodEntry> _history = [];

  @override
  void initState() {
    super.initState();
    // _simulator.start();
    // _simulator.stream.listen((w) {
    //   setState(() {
    //     _weight = w;
    //   });
    // });
    _weightController = StreamController<double>.broadcast();
  }

  @override
  void dispose() {
    //_simulator.dispose();
    _searchController.dispose();
    _weightController.close();
    super.dispose();
  }

  Future<void> _openFoodBottomSheet(Food food) async {
    final grams = await showModalBottomSheet<double?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FoodAmountSheet(
        food: food,
        isScaleConnected: _isScaleConnected,
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

    final materialLocalizations = MaterialLocalizations.of(context);
    final alwaysUse24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("AcoFood"),
            Text(
              "Tu asistente diario de macros",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Cambiar tema',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      drawer: SettingsDrawer(
        profile: widget.profile,
        onUpdateProfile: widget.onUpdateProfile,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth >= 1200;
          final isMedium = constraints.maxWidth >= 800;
          final crossAxisCount = isLarge
              ? 5
              : isMedium
                  ? 4
                  : constraints.maxWidth >= 600
                      ? 3
                      : 2;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScaleOverviewCard(
                        weight: _weight,
                        isConnected: _isScaleConnected,
                        onWeightChanged: (grams) {
                          setState(() => _weight = grams);
                          _weightController.add(grams);
                        },
                        onConnectionChanged: (isConnected) {
                          setState(() => _isScaleConnected = isConnected);
                        },
                      ),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search),
                              border: InputBorder.none,
                              hintText: 'Buscar alimento o marca...',
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
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Cat¨¢logo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              if (filteredFoods.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No encontramos alimentos para "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.builder(
                    itemCount: filteredFoods.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isLarge
                          ? 1.1
                          : isMedium
                              ? 1
                              : 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final food = filteredFoods[index];
                      return _FoodCard(
                        food: food,
                        onTap: () => _openFoodBottomSheet(food),
                      );
                    },
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Historial reciente',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              if (_history.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Todav¨ªa no registraste comidas. Usa el cat¨¢logo para agregar tu primera entrada.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    final localDate = entry.timestamp.toLocal();
                    final dateLabel = materialLocalizations.formatShortDate(localDate);
                    final timeLabel = materialLocalizations.formatTimeOfDay(
                      TimeOfDay.fromDateTime(localDate),
                      alwaysUse24HourFormat: alwaysUse24HourFormat,
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text(entry.food.emoji),
                          ),
                          title: Text(
                            '${entry.food.name} ¡¤ ${entry.grams.toStringAsFixed(1)} g',
                          ),
                          subtitle: Text('$dateLabel ¡¤ $timeLabel'),
                        ),
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;

  const _FoodCard({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                food.emoji,
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                food.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (food.fullName != null) ...[
                const SizedBox(height: 4),
                Text(
                  food.fullName!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScaleOverviewCard extends StatelessWidget {
  final double weight;
  final bool isConnected;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<bool> onConnectionChanged;

  const _ScaleOverviewCard({
    required this.weight,
    required this.isConnected,
    required this.onWeightChanged,
    required this.onConnectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final calories = (weight * 7).clamp(0, double.infinity);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.scale_rounded,
                    size: 30,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balanza MacroScale',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isConnected
                            ? 'Listo para capturar tu pr¨®xima porci¨®n'
                            : 'Conect¨¢ tu balanza para registrar lecturas en vivo',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${weight.toStringAsFixed(1)} g',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${calories.toStringAsFixed(0)} kcal aprox.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            BluetoothManager(
              onWeightChanged: onWeightChanged,
              onConnectionChanged: onConnectionChanged,
            ),
          ],
        ),
      ),
    );
  }
}