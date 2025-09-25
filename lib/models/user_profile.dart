class UserProfile {
  String name;
  double weight;
  double height;
  int carbs;
  int protein;
  int fat;

  UserProfile({
    this.name = "",
    this.weight = 0,
    this.height = 0,
    this.carbs = 50,
    this.protein = 20,
    this.fat = 30,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "weight": weight,
    "height": height,
    "carbs": carbs,
    "protein": protein,
    "fat": fat,
  };

  factory UserProfile.fromPrefs(Map<String, Object?> prefs) {
    return UserProfile(
      name: prefs["name"] as String? ?? "",
      weight: (prefs["weight"] as double?) ?? 0,
      height: (prefs["height"] as double?) ?? 0,
      carbs: prefs["carbs"] as int? ?? 50,
      protein: prefs["protein"] as int? ?? 20,
      fat: prefs["fat"] as int? ?? 30,
    );
  }
}
