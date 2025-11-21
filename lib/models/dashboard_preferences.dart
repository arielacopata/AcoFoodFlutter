class DashboardPreferences {
  // Secciones a mostrar en el dashboard
  final bool showMacrosCard;
  final bool showCaloriesChart;
  final bool showMacrosPercentChart;
  final bool showTopFoods;
  final bool showHabitsCompletion;
  final bool showNutrientsAnalysis; // Nueva sección
  final bool showSuggestedFoods;

  // Opciones de cálculo
  final bool includeFastingInAverages; // Incluir días de ayuno en promedios

  // Secciones a incluir en el PDF
  final bool exportMacrosCard;
  final bool exportMacrosPercentChart;
  final bool exportDailyData;
  final bool exportTopFoods;
  final bool exportHabitsCompletion;
  final bool exportNutrientsAnalysis; // Nueva sección
  // Opciones de exportación (layout)
  final String reportStyle; // 'minimal' | 'classic'
  final bool tableZebra; // zebra en tablas
  final String habitsPageMode; // '30days' | 'always' | 'never'
  final String pageFormat; // 'a4' | 'letter'
  // Formato de análisis de nutrientes en exportación
  final String nutrientsExportMode; // 'daily' | 'avg_bars'

  const DashboardPreferences({
    // Por defecto, mostrar todo
    this.showMacrosCard = true,
    this.showCaloriesChart = true,
    this.showMacrosPercentChart = true,
    this.showTopFoods = true,
    this.showHabitsCompletion = true,
    this.showNutrientsAnalysis = true,
    this.showSuggestedFoods = false,
    // Opciones de cálculo
    this.includeFastingInAverages = false,
    // Por defecto, exportar todo
    this.exportMacrosCard = true,
    this.exportMacrosPercentChart = true,
    this.exportDailyData = true,
    this.exportTopFoods = true,
    this.exportHabitsCompletion = true,
    this.exportNutrientsAnalysis = true,
    this.reportStyle = 'minimal',
    this.tableZebra = false,
    this.habitsPageMode = '30days',
    this.pageFormat = 'a4',
    this.nutrientsExportMode = 'daily',
  });

  // Convertir a JSON para guardar en SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'showMacrosCard': showMacrosCard,
      'showCaloriesChart': showCaloriesChart,
      'showMacrosPercentChart': showMacrosPercentChart,
      'showTopFoods': showTopFoods,
      'showHabitsCompletion': showHabitsCompletion,
      'showNutrientsAnalysis': showNutrientsAnalysis,
      'exportMacrosCard': exportMacrosCard,
      'exportMacrosPercentChart': exportMacrosPercentChart,
      'exportDailyData': exportDailyData,
      'exportTopFoods': exportTopFoods,
      'exportHabitsCompletion': exportHabitsCompletion,
      'exportNutrientsAnalysis': exportNutrientsAnalysis,
      'reportStyle': reportStyle,
      'tableZebra': tableZebra,
      'habitsPageMode': habitsPageMode,
      'pageFormat': pageFormat,
      'nutrientsExportMode': nutrientsExportMode,
      'showSuggestedFoods': showSuggestedFoods,
      'includeFastingInAverages': includeFastingInAverages,
    };
  }

  // Crear desde JSON
  factory DashboardPreferences.fromJson(Map<String, dynamic> json) {
    return DashboardPreferences(
      showMacrosCard: json['showMacrosCard'] ?? true,
      showCaloriesChart: json['showCaloriesChart'] ?? true,
      showMacrosPercentChart: json['showMacrosPercentChart'] ?? true,
      showTopFoods: json['showTopFoods'] ?? true,
      showHabitsCompletion: json['showHabitsCompletion'] ?? true,
      showNutrientsAnalysis: json['showNutrientsAnalysis'] ?? true,
      exportMacrosCard: json['exportMacrosCard'] ?? true,
      exportMacrosPercentChart: json['exportMacrosPercentChart'] ?? true,
      exportDailyData: json['exportDailyData'] ?? true,
      exportTopFoods: json['exportTopFoods'] ?? true,
      exportHabitsCompletion: json['exportHabitsCompletion'] ?? true,
      exportNutrientsAnalysis: json['exportNutrientsAnalysis'] ?? true,
      reportStyle: json['reportStyle'] ?? 'minimal',
      tableZebra: json['tableZebra'] ?? false,
      habitsPageMode: json['habitsPageMode'] ?? '30days',
      pageFormat: json['pageFormat'] ?? 'a4',
      nutrientsExportMode: json['nutrientsExportMode'] ?? 'daily',
      showSuggestedFoods: json['showSuggestedFoods'] ?? false,
      includeFastingInAverages: json['includeFastingInAverages'] ?? false,
    );
  }

  // Crear una copia con cambios
  DashboardPreferences copyWith({
    bool? showMacrosCard,
    bool? showCaloriesChart,
    bool? showMacrosPercentChart,
    bool? showTopFoods,
    bool? showHabitsCompletion,
    bool? showNutrientsAnalysis,
    bool? exportMacrosCard,
    bool? exportMacrosPercentChart,
    bool? exportDailyData,
    bool? exportTopFoods,
    bool? exportHabitsCompletion,
    bool? exportNutrientsAnalysis,
    String? reportStyle,
    bool? tableZebra,
    String? habitsPageMode,
    String? pageFormat,
    String? nutrientsExportMode,
    bool? showSuggestedFoods,
    bool? includeFastingInAverages,
  }) {
    return DashboardPreferences(
      showMacrosCard: showMacrosCard ?? this.showMacrosCard,
      showCaloriesChart: showCaloriesChart ?? this.showCaloriesChart,
      showMacrosPercentChart:
          showMacrosPercentChart ?? this.showMacrosPercentChart,
      showTopFoods: showTopFoods ?? this.showTopFoods,
      showHabitsCompletion: showHabitsCompletion ?? this.showHabitsCompletion,
      showNutrientsAnalysis:
          showNutrientsAnalysis ?? this.showNutrientsAnalysis,
      exportMacrosCard: exportMacrosCard ?? this.exportMacrosCard,
      exportMacrosPercentChart:
          exportMacrosPercentChart ?? this.exportMacrosPercentChart,
      exportDailyData: exportDailyData ?? this.exportDailyData,
      exportTopFoods: exportTopFoods ?? this.exportTopFoods,
      exportHabitsCompletion:
          exportHabitsCompletion ?? this.exportHabitsCompletion,
      exportNutrientsAnalysis:
          exportNutrientsAnalysis ?? this.exportNutrientsAnalysis,
      reportStyle: reportStyle ?? this.reportStyle,
      tableZebra: tableZebra ?? this.tableZebra,
      habitsPageMode: habitsPageMode ?? this.habitsPageMode,
      pageFormat: pageFormat ?? this.pageFormat,
      nutrientsExportMode: nutrientsExportMode ?? this.nutrientsExportMode,
      showSuggestedFoods: showSuggestedFoods ?? this.showSuggestedFoods,
      includeFastingInAverages:
          includeFastingInAverages ?? this.includeFastingInAverages,
    );
  }
}
