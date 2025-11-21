class DashboardStats {
  final DateTime startDate;
  final DateTime endDate;
  final double avgCalories;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;
  final List<DailyData> dailyData;
  final List<TopFood> topFoods;
  final List<TopFood> topFoodsByWeight;
  final Map<String, int> habitCompletion;

  DashboardStats({
    required this.startDate,
    required this.endDate,
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.dailyData,
    required this.topFoods,
    required this.topFoodsByWeight,
    required this.habitCompletion,
  });
}

class DailyData {
  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final Map<String, double> nutrients; // Todos los nutrientes del día
  final bool isFasting; // Flag para indicar si es un día de ayuno explícito

  DailyData({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.nutrients = const {},
    this.isFasting = false,
  });
}

class TopFood {
  final String name;
  final String fullName;
  final String emoji;
  final int timesConsumed;
  final double totalGrams;

  TopFood({
    required this.name,
    required this.fullName,
    required this.emoji,
    required this.timesConsumed,
    required this.totalGrams,
  });
}
