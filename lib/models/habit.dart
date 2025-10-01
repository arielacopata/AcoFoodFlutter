import 'dart:convert';

class Habit {
  final int? id;
  final String name;
  final String? emoji;
  final String type; // 'predefined' o 'custom'
  final List<String>? options; // Chips disponibles
  final bool enabled;

  Habit({
    this.id,
    required this.name,
    this.emoji,
    required this.type,
    this.options,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'type': type,
      'options': options != null ? jsonEncode(options) : null,
      'enabled': enabled ? 1 : 0,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      emoji: map['emoji'],
      type: map['type'],
      options: map['options'] != null 
          ? List<String>.from(jsonDecode(map['options']))
          : null,
      enabled: map['enabled'] == 1,
    );
  }
}

class HabitLog {
  final int? id;
  final int habitId;
  final DateTime date;
  final String? detail;
  final DateTime timestamp;

  HabitLog({
    this.id,
    required this.habitId,
    required this.date,
    this.detail,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'date': DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0],
      'detail': detail,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'],
      habitId: map['habitId'],
      date: DateTime.parse(map['date']),
      detail: map['detail'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}