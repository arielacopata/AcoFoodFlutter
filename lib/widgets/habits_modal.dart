import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/storage_factory.dart';
import 'habit_calendar.dart';
import '../screens/habit_info_screen.dart';

class HabitsModal extends StatefulWidget {
  final VoidCallback? onSettingsTap;

  const HabitsModal({super.key, this.onSettingsTap});

  @override
  State<HabitsModal> createState() => _HabitsModalState();
}

class _HabitsModalState extends State<HabitsModal> {
  List<Habit> _habits = [];
  Map<int, int> _streaks = {};
  Map<int, bool> _completedToday = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await StorageFactory.instance.getEnabledHabits();
    final today = DateTime.now();

    Map<int, int> streaks = {};
    Map<int, bool> completed = {};

    for (final habit in habits) {
      streaks[habit.id!] = await StorageFactory.instance.calculateStreak(
        habit.id!,
      );
      final logs = await StorageFactory.instance.getHabitLogsByDate(
        habit.id!,
        today,
      );
      completed[habit.id!] = logs.isNotEmpty;
    }

    setState(() {
      _habits = habits;
      _streaks = streaks;
      _completedToday = completed;
      _loading = false;
    });
  }

  void _showHabitOptions(Habit habit) {
    if (habit.options == null || habit.options!.isEmpty) {
      _completeHabit(habit.id!, null);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        String? selectedDetail;
        int? calories;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${habit.emoji} ${habit.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_streaks[habit.id!]! > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Llevas ${_streaks[habit.id!]} días consecutivos',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  HabitCalendar(habit: habit),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: habit.options!.map((option) {
                      return ActionChip(
                        label: Text(option),
                        backgroundColor: selectedDetail == option
                            ? Colors.blue.shade100
                            : null,
                        onPressed: () {
                          setModalState(() => selectedDetail = option);
                        },
                      );
                    }).toList(),
                  ),

                  // Input de calorías solo para Ejercicio
                  if (habit.name == 'Ejercicio') ...[
                    const SizedBox(height: 16),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Calorías gastadas (opcional)',
                        border: OutlineInputBorder(),
                        suffixText: 'kcal',
                      ),
                      onChanged: (value) {
                        calories = int.tryParse(value);
                      },
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedDetail == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              _completeHabit(
                                habit.id!,
                                selectedDetail,
                                calories: calories,
                              );
                            },
                      child: const Text('Completar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeHabit(
    int habitId,
    String? detail, {
    int? calories,
  }) async {
    await StorageFactory.instance.logHabit(habitId, detail ?? '');

    // Si hay calorías, actualizar expenditure del perfil
    // Si hay calorías, actualizar expenditure del perfil
    if (calories != null && calories > 0) {
      await StorageFactory.instance.updateExpenditureForToday(calories);
    }

    await _loadHabits();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hábito completado'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
                'Tareas Saludables',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HabitInfoScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      if (widget.onSettingsTap != null) {
                        widget.onSettingsTap!();
                      }
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
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                final habit = _habits[index];
                final streak = _streaks[habit.id!] ?? 0;
                final completed = _completedToday[habit.id!] ?? false;

                return ListTile(
                  leading: Text(
                    habit.emoji ?? '',
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(habit.name),
                  subtitle: streak > 0
                      ? Text(
                          '$streak días consecutivos',
                          style: TextStyle(color: Colors.green.shade700),
                        )
                      : null,
                  trailing: completed
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                  onTap: completed ? null : () => _showHabitOptions(habit),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
