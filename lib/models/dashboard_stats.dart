class DashboardStats {
  final DateTime startDate;
  final DateTime endDate;
  final double avgCalories;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;
  final List<DailyData> dailyData;
  final List<TopFood> topFoods;
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
    required this.habitCompletion,
  });
}

class DailyData {
  final DateTime date;
  final double calories;
  final double protein;   // Agregar
  final double carbs;     // Agregar
  final double fat;       // Agregar
  
  DailyData({
    required this.date,
    required this.calories,
    required this.protein,  // Agregar
    required this.carbs,    // Agregar
    required this.fat,      // Agregar
  });
}

class TopFood {
  final String name;
  final String emoji;
  final int timesConsumed;
  final double totalGrams;
  
  TopFood({
    required this.name,
    required this.emoji,
    required this.timesConsumed,
    required this.totalGrams,
  });
}