class Supplement {
  final int? id;
  final String emoji;
  final String name;
  final String type; // 'b12', 'vitamin_d', 'omega3'

  Supplement({
    this.id,
    required this.emoji,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emoji': emoji,
      'name': name,
      'type': type,
    };
  }

  factory Supplement.fromMap(Map<String, dynamic> map) {
    return Supplement(
      id: map['id'],
      emoji: map['emoji'],
      name: map['name'],
      type: map['type'],
    );
  }
}