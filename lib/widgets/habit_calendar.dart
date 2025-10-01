import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/database_service.dart';

class HabitCalendar extends StatefulWidget {
  final Habit habit;

  const HabitCalendar({super.key, required this.habit});

  @override
  State<HabitCalendar> createState() => _HabitCalendarState();
}

class _HabitCalendarState extends State<HabitCalendar> {
  Map<DateTime, bool> _completionMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    Map<DateTime, bool> map = {};

    for (int i = 0; i < 30; i++) {
      final date = thirtyDaysAgo.add(Duration(days: i));
      final logs = await DatabaseService.instance.getHabitLogsByDate(
        widget.habit.id!,
        date,
      );
      map[DateTime(date.year, date.month, date.day)] = logs.isNotEmpty;
    }

    setState(() {
      _completionMap = map;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final days = _completionMap.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimos 30 días',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: days.map((date) {
            final completed = _completionMap[date] ?? false;
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: completed ? Colors.green.shade400 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 10,
                    color: completed ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
