class CalorieCalculator {
  /// Calcula las calorías recomendadas basadas en el perfil del usuario
  /// Usa la fórmula de Mifflin-St Jeor (más precisa y moderna)
  static double calculateRecommendedCalories({
    required DateTime? dob,
    required String? gender,
    required double? weight,
    required double? height,
    required String? lifestyle,
    required String? exerciseLevel,
    int? expenditure,
  }) {
    // Si faltan datos esenciales, retornar valor por defecto
    if (dob == null || gender == null || weight == null || height == null || 
        lifestyle == null || exerciseLevel == null) {
      return 2000.0;
    }

    // Calcular edad
    final today = DateTime.now();
    int age = today.year - dob.year;
    final m = today.month - dob.month;
    if (m < 0 || (m == 0 && today.day < dob.day)) {
      age--;
    }

    // Calcular TMB usando Mifflin-St Jeor (más precisa y moderna)
    double bmr;
    if (gender == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Factores de actividad validados científicamente
    const activityFactors = [1.2, 1.375, 1.55, 1.725, 1.9, 2.2];
    final exerciseInt = int.tryParse(exerciseLevel) ?? 1;
    final activityFactor = activityFactors[exerciseInt - 1];

    // Calcular TDEE: TMB × Factor de actividad
    double tdee = bmr * activityFactor;

    // Si hay gasto adicional registrado, sumarlo
    if (expenditure != null && expenditure > 0) {
      tdee += expenditure;
    }

    return tdee;
  }

  /// Calcula los gramos objetivo de cada macronutriente
  static Map<String, double> calculateMacroGoals({
    required double totalCalories,
    required int carbsPercentage,
    required int proteinPercentage,
    required int fatPercentage,
  }) {
    return {
      'carbs': (totalCalories * (carbsPercentage / 100)) / 4,
      'protein': (totalCalories * (proteinPercentage / 100)) / 4,
      'fat': (totalCalories * (fatPercentage / 100)) / 9,
    };
  }
}