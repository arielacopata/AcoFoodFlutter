class Food {
  final String emoji;
  final String name;
  final String? fullName;

  Food({required this.emoji, required this.name, this.fullName});

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      emoji: map["emoji"] ?? "🍽️",
      name: map["name"] ?? "",
      fullName: map["fullName"],
    );
  }
}
