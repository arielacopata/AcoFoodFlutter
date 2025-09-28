class Food {
  final int? id;
  final String emoji;
  final String name;
  final String? fullName;

  Food({this.id, required this.emoji, required this.name, this.fullName});

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map["id"],
      emoji: map["emoji"] ?? "🍽️",
      name: map["name"] ?? "",
      fullName: map["fullName"],
    );
  }
}
