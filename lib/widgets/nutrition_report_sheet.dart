// En: lib/widgets/nutrition_report_sheet.dart

import 'package:flutter/material.dart';
import '../models/nutrition_report.dart';
import '../data/nutrient_goals.dart';
import 'nutrient_progress_row.dart';

class NutritionReportSheet extends StatelessWidget {
  final NutritionReport report;
  final double totalCaloriesGoal;
  final double proteinGoalGrams;
  final double carbsGoalGrams;
  final double fatGoalGrams;
  final double userWeight;

  const NutritionReportSheet({
    super.key,
    required this.report,
    required this.totalCaloriesGoal,
    required this.proteinGoalGrams,
    required this.carbsGoalGrams,
    required this.fatGoalGrams,
    this.userWeight = 70.0, // Default 70kg
  });

  static const List<String> nutrientOrder = [
    'calories',
    'proteins',
    'totalFats',
    'carbohydrates',
    'fiber',
    'omega3',
    'omega6',
    'vitaminA',
    'vitaminB1',
    'vitaminB2',
    'vitaminB3',
    'vitaminB6',
    'vitaminB9',
    'vitaminC',
    'vitaminE',
    'vitaminK',
    'vitaminB4',
    'vitaminB5',
    'vitaminB7',
    'vitaminB12',
    'vitaminD',
    'calcium',
    'iron',
    'magnesium',
    'phosphorus',
    'potassium',
    'sodium',
    'zinc',
    'copper',
    'manganese',
    'selenium',
    'iodine',
    'histidine',
    'isoleucine',
    'leucine',
    'lysine',
    'methionine',
    'phenylalanine',
    'threonine',
    'tryptophan',
    'valine',
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                "Reporte Nutricional",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: nutrientOrder.length,
                  itemBuilder: (context, index) {
                    final nutrientKey = nutrientOrder[index];
                    final row = _buildNutrientRow(nutrientKey);
                    return row ?? const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildNutrientRow(String nutrientKey) {
    final value = _getNutrientValue(nutrientKey);

    if (value <= 0 && !['omega3', 'omega6'].contains(nutrientKey)) {
      return null;
    }

    Map<String, dynamic>? goalData;

    if (nutrientKey == 'calories') {
      goalData = {'value': totalCaloriesGoal, 'unit': 'kcal', 'type': 'Meta'};
    } else if (nutrientKey == 'proteins') {
      goalData = {'value': proteinGoalGrams, 'unit': 'g', 'type': 'Meta'};
    } else if (nutrientKey == 'carbohydrates') {
      goalData = {'value': carbsGoalGrams, 'unit': 'g', 'type': 'Meta'};
    } else if (nutrientKey == 'totalFats') {
      goalData = {'value': fatGoalGrams, 'unit': 'g', 'type': 'Meta'};
    } else {
      goalData = nutrientGoals[nutrientKey];

      // Convertir aminoácidos de mg/kg/day a gramos totales
      if (goalData != null && goalData['unit'] == 'mg/kg/day') {
        final mgPerKg = goalData['value'] as double;
        final totalMg = mgPerKg * userWeight;
        final totalGrams = totalMg / 1000; // convertir mg a g

        goalData = {'value': totalGrams, 'unit': 'g', 'type': goalData['type']};
      }
    }

    if (goalData == null) return null;

    const nutrientNameMapping = {
      'calories': "Calorías",
      'proteins': "Proteínas",
      'carbohydrates': "Carbohidratos",
      'totalFats': "Grasas Totales",
      'fiber': "Fibra",
      'saturatedFats': "Grasas Saturadas",
      'omega3': "Omega-3",
      'omega6': "Omega-6",
      'calcium': "Calcio",
      'iron': "Hierro",
      'magnesium': "Magnesio",
      'phosphorus': "Fósforo",
      'potassium': "Potasio",
      'sodium': "Sodio",
      'zinc': "Zinc",
      'copper': "Cobre",
      'manganese': "Manganeso",
      'selenium': "Selenio",
      'vitaminA': "Vitamina A",
      'vitaminC': "Vitamina C",
      'vitaminE': "Vitamina E",
      'vitaminK': "Vitamina K",
      'vitaminB1': "Vitamina B1 (Tiamina)",
      'vitaminB2': "Vitamina B2 (Riboflavina)",
      'vitaminB3': "Vitamina B3 (Niacina)",
      'vitaminB4': "Vitamina B4 (Colina)",
      'vitaminB5': "Vitamina B5 (Ác. Pantoténico)",
      'vitaminB6': "Vitamina B6",
      'vitaminB7': "Vitamina B7 (Biotina)",
      'vitaminB9': "Vitamina B9 (Folato)",
      'vitaminB12': "Vitamina B12",
      'vitaminD': "Vitamina D",
      'iodine': "Yodo",
      'histidine': "Histidina",
      'isoleucine': "Isoleucina",
      'leucine': "Leucina",
      'lysine': "Lisina",
      'methionine': "Metionina",
      'phenylalanine': "Fenilalanina",
      'threonine': "Treonina",
      'tryptophan': "Triptófano",
      'valine': "Valina",
    };

    // Agregar divisor antes del primer aminoácido
    if (nutrientKey == 'histidine') {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(thickness: 2),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Aminoácidos Esenciales',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          NutrientProgressRow(
            name: nutrientNameMapping[nutrientKey] ?? "Desconocido",
            value: value,
            goal: goalData['value'],
            unit: goalData['unit'],
            type: goalData['type'],
          ),
        ],
      );
    }
    return NutrientProgressRow(
      name: nutrientNameMapping[nutrientKey] ?? "Desconocido",
      value: value,
      goal: goalData['value'],
      unit: goalData['unit'],
      type: goalData['type'],
    );
  }

  double _getNutrientValue(String key) {
    switch (key) {
      case 'calories':
        return report.calories;
      case 'proteins':
        return report.proteins;
      case 'carbohydrates':
        return report.carbohydrates;
      case 'totalFats':
        return report.totalFats;
      case 'fiber':
        return report.fiber;
      case 'saturatedFats':
        return report.saturatedFats;
      case 'omega3':
        return report.omega3;
      case 'omega6':
        return report.omega6;
      case 'calcium':
        return report.calcium;
      case 'iron':
        return report.iron;
      case 'magnesium':
        return report.magnesium;
      case 'phosphorus':
        return report.phosphorus;
      case 'potassium':
        return report.potassium;
      case 'sodium':
        return report.sodium;
      case 'zinc':
        return report.zinc;
      case 'copper':
        return report.copper;
      case 'manganese':
        return report.manganese;
      case 'selenium':
        return report.selenium;
      case 'vitaminA':
        return report.vitaminA;
      case 'vitaminC':
        return report.vitaminC;
      case 'vitaminE':
        return report.vitaminE;
      case 'vitaminK':
        return report.vitaminK;
      case 'vitaminB1':
        return report.vitaminB1;
      case 'vitaminB2':
        return report.vitaminB2;
      case 'vitaminB3':
        return report.vitaminB3;
      case 'vitaminB4':
        return report.vitaminB4;
      case 'vitaminB5':
        return report.vitaminB5;
      case 'vitaminB6':
        return report.vitaminB6;
      case 'vitaminB7':
        return report.vitaminB7;
      case 'vitaminB9':
        return report.vitaminB9;
      case 'vitaminB12':
        return report.vitaminB12;
      case 'vitaminD':
        return report.vitaminD;
      case 'iodine':
        return report.iodine;
      case 'histidine':
        return report.histidine;
      case 'isoleucine':
        return report.isoleucine;
      case 'leucine':
        return report.leucine;
      case 'lysine':
        return report.lysine;
      case 'methionine':
        return report.methionine;
      case 'phenylalanine':
        return report.phenylalanine;
      case 'threonine':
        return report.threonine;
      case 'tryptophan':
        return report.tryptophan;
      case 'valine':
        return report.valine;
      default:
        return 0.0;
    }
  }
}
