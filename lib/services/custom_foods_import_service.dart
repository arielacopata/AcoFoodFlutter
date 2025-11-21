// lib/services/custom_foods_import_service.dart

import 'dart:convert';
import '../models/food.dart';
import 'storage_factory.dart';

class ImportNotifier {
  static String? pendingAlert;
  static bool showPillinAlert = false;
}



class CustomFoodsImportService {
  /// Valida y importa alimentos desde un JSON
  /// Si isDeveloper = true y el JSON incluye 'id', actualiza el alimento existente
  /// Si isDeveloper = false o no hay 'id', crea un nuevo alimento
  static Future<ImportResult> importFromJson(String jsonString) async {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);

      List<Food> validFoods = [];
      List<String> errors = [];

      for (int i = 0; i < jsonList.length; i++) {
        try {
          final foodJson = jsonList[i] as Map<String, dynamic>;
          final food = _parseFoodFromJson(foodJson);
          validFoods.add(food);
        } catch (e) {
          errors.add('Error en alimento ${i + 1}: $e');
        }
      }

      // Insertar/actualizar alimentos válidos en la base de datos
      int insertedCount = 0;
      for (var food in validFoods) {
        try {
          // Modo normal: insertar nuevo alimento
          await StorageFactory.instance.insertCustomFood(food);

          insertedCount++;
        } catch (e) {
          errors.add('Error al insertar ${food.name}: $e');
        }
      }

      return ImportResult(
        totalProcessed: jsonList.length,
        successCount: insertedCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        totalProcessed: 0,
        successCount: 0,
        errors: ['Error al leer el archivo JSON: $e'],
      );
    }
  }

  /// Parsea un alimento desde JSON
  static Food _parseFoodFromJson(Map<String, dynamic> json) {
    // Validar campos requeridos
    if (!json.containsKey('name') ||
        json['name'] == null ||
        json['name'].toString().isEmpty) {
      throw Exception('El campo "name" es requerido');
    }

    // 🚫 VALIDACIÓN DE ALIMENTOS DE ORIGEN ANIMAL
    final name = json['name'].toString().toLowerCase();
    final fullName = (json['fullName']?.toString() ?? '').toLowerCase();

    // Lista de palabras prohibidas
    final prohibitedWords = [
      'carne',
      'embutido',
      'morcilla',
      'fiambre',
      'grasa animal',
      'sebo',
      'grasa vacuna',
      'caldo de carne',
      'caldo de pollo',
      'extracto de carne',
      'gel de pescado',
      'fish oil',
      'cod liver',
      'anchovy',
      'oyster',
      'clam',
      'shrimp',
      'tuna',
      'salmon oil',
      'clara de huevo',
      'yema',
      'ovoproducto',
      'albumina',
      'ovomucina',
      'ovoglobulina',
      'egg white',
      'egg yolk',
      'albumin',
      'asado',
      'pollo',
      'res',
      'cerdo',
      'puerco',
      'pescado',
      'atún',
      'salmón',
      'huevo',
      'huevos',
      'leche',
      'suero de leche',
      'lactosuero',
      'leche descremada',
      'leche entera',
      'leche en polvo',
      'caseinato',
      'casein',
      'lactoglobulina',
      'lactoferrina',
      'whey protein',
      'milk powder',
      'dairy',
      'buttermilk',
      'propóleo',
      'polen',
      'royal jelly',
      'jalea real',
      'carmin',
      'cochinilla',
      'carmínico',
      'shellac',
      'goma laca',
      'isenglass',
      'cola de pescado',
      'pepsina',
      'renina',
      'cuajo',
      'lipasa animal',
      'tripsina',
      'gelificante animal',
      'colágeno',
      'colageno',
      'elastina',
      'queratina',
      'keratin',
      'collagen',
      'manteca',
      'grasa de cerdo',
      'aceite de pescado',
      'aceite de bacalao',
      'tallow',
      'lard',
      'queso',
      'yogur',
      'yogurt',
      'mantequilla',
      'crema',
      'jamón',
      'salchicha',
      'chorizo',
      'tocino',
      'bacon',
      'panceta',
      'vaca',
      'ternera',
      'cordero',
      'pavo',
      'pato',
      'conejo',
      'venado',
      'mariscos',
      'camarón',
      'langosta',
      'cangrejo',
      'almeja',
      'mejillón',
      'pulpo',
      'calamar',
      'anchoa',
      'sardina',
      'trucha',
      'bacalao',
      'miel',
      'gelatina',
      'suero',
      'caseína',
      'lactosa',
      'whey',
      'animal',
      'meat',
      'chicken',
      'beef',
      'pork',
      'fish',
      'egg',
      'milk',
      'cheese',
      'butter',
      'cream',
      'honey',
      'gelatin',
    ];

    // Verificar si contiene alguna palabra prohibida
for (final word in prohibitedWords) {
  if (name.contains(word) || fullName.contains(word)) {
    ImportNotifier.showPillinAlert = true; // ⚠️ Marcar el flag global
     print('⚠️ FLAG ACTIVADO - palabra: $word'); // 👈 Debug
    throw Exception(
      'No recomendado\n\n'
      'NO APROBAMOS LA IMPORTACIÓN DE ESTE TIPO DE ALIMENTOS '
      'POR RAZONES DE SALUD, SOSTENIBILIDAD Y RESPETO HACIA LOS ANIMALES, '
      'INCLUYENDO A LOS QUE ALGUNAS PERSONAS CONSIDERAN ALIMENTO.',
    );
  }
}


    return Food(
      // Campos básicos
      emoji: json['emoji']?.toString() ?? '🍽️',
      name: json['name'].toString(),
      fullName: json['fullName']?.toString(),

      // Macronutrientes
      calories: _parseDouble(json['calories']),
      proteins: _parseDouble(json['proteins']),
      carbohydrates: _parseDouble(json['carbohydrates']),
      fiber: _parseDouble(json['fiber']),
      totalSugars: _parseDouble(json['totalSugars']),
      totalFats: _parseDouble(json['totalFats']),
      saturatedFats: _parseDouble(json['saturatedFats']),

      // Ácidos grasos
      omega3: _parseDouble(json['omega3']),
      omega6: _parseDouble(json['omega6']),
      omega9: _parseDouble(json['omega9']),

      // Minerales
      calcium: _parseDouble(json['calcium']),
      iron: _parseDouble(json['iron']),
      magnesium: _parseDouble(json['magnesium']),
      phosphorus: _parseDouble(json['phosphorus']),
      potassium: _parseDouble(json['potassium']),
      sodium: _parseDouble(json['sodium']),
      zinc: _parseDouble(json['zinc']),
      copper: _parseDouble(json['copper']),
      manganese: _parseDouble(json['manganese']),
      selenium: _parseDouble(json['selenium']),
      iodine: _parseDouble(json['iodine']),
      molybdenum: _parseDouble(json['molybdenum']),
      chromium: _parseDouble(json['chromium']),
      fluorine: _parseDouble(json['fluorine']),

      // Vitaminas
      vitaminA: _parseDouble(json['vitaminA']),
      vitaminC: _parseDouble(json['vitaminC']),
      vitaminD: _parseDouble(json['vitaminD']),
      vitaminE: _parseDouble(json['vitaminE']),
      vitaminK: _parseDouble(json['vitaminK']),
      vitaminB1: _parseDouble(json['vitaminB1']),
      vitaminB2: _parseDouble(json['vitaminB2']),
      vitaminB3: _parseDouble(json['vitaminB3']),
      vitaminB4: _parseDouble(json['vitaminB4']),
      vitaminB5: _parseDouble(json['vitaminB5']),
      vitaminB6: _parseDouble(json['vitaminB6']),
      vitaminB7: _parseDouble(json['vitaminB7']),
      vitaminB9: _parseDouble(json['vitaminB9']),
      vitaminB12: _parseDouble(json['vitaminB12']),

      // Aminoácidos
      histidine: _parseDouble(json['histidine']),
      isoleucine: _parseDouble(json['isoleucine']),
      leucine: _parseDouble(json['leucine']),
      lysine: _parseDouble(json['lysine']),
      methionine: _parseDouble(json['methionine']),
      phenylalanine: _parseDouble(json['phenylalanine']),
      threonine: _parseDouble(json['threonine']),
      tryptophan: _parseDouble(json['tryptophan']),
      valine: _parseDouble(json['valine']),
      alanine: _parseDouble(json['alanine']),
      arginine: _parseDouble(json['arginine']),
      asparticAcid: _parseDouble(json['asparticAcid']),
      glutamicAcid: _parseDouble(json['glutamicAcid']),
      glycine: _parseDouble(json['glycine']),
      proline: _parseDouble(json['proline']),
      serine: _parseDouble(json['serine']),
      tyrosine: _parseDouble(json['tyrosine']),
      cysteine: _parseDouble(json['cysteine']),
      glutamine: _parseDouble(json['glutamine']),
      asparagine: _parseDouble(json['asparagine']),
    );
  }

  /// Convierte un valor a int de forma segura
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Convierte un valor a double de forma segura
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Genera un JSON de ejemplo para que el usuario sepa el formato
  static String getExampleJson() {
    return '''[
  {
    "name": "Mi Alimento Custom",
    "fullName": "Nombre completo del alimento (opcional)",
    "emoji": "🍽️",
    "calories": 100,
    "proteins": 5.0,
    "carbohydrates": 15.0,
    "fiber": 2.0,
    "totalSugars": 5.0,
    "totalFats": 3.0,
    "saturatedFats": 1.0,
    "omega3": 0.5,
    "omega6": 0.2,
    "omega9": 0.3,
    "calcium": 50,
    "iron": 2.0,
    "magnesium": 30,
    "phosphorus": 40,
    "potassium": 200,
    "sodium": 100,
    "zinc": 1.0,
    "copper": 0.1,
    "manganese": 0.2,
    "selenium": 5,
    "iodine": 10,
    "molybdenum": 5,
    "chromium": 2,
    "fluorine": 1,
    "vitaminA": 100,
    "vitaminC": 20,
    "vitaminD": 5,
    "vitaminE": 2,
    "vitaminK": 10,
    "vitaminB1": 0.1,
    "vitaminB2": 0.1,
    "vitaminB3": 1.0,
    "vitaminB4": 10,
    "vitaminB5": 0.5,
    "vitaminB6": 0.2,
    "vitaminB7": 5,
    "vitaminB9": 20,
    "vitaminB12": 1,
    "histidine": 0.1,
    "isoleucine": 0.2,
    "leucine": 0.3,
    "lysine": 0.2,
    "methionine": 0.1,
    "phenylalanine": 0.2,
    "threonine": 0.2,
    "tryptophan": 0.05,
    "valine": 0.2,
    "alanine": 0.15,
    "arginine": 0.25,
    "asparticAcid": 0.3,
    "glutamicAcid": 0.5,
    "glycine": 0.2,
    "proline": 0.2,
    "serine": 0.15,
    "tyrosine": 0.1,
    "cysteine": 0.08,
    "glutamine": 0.4,
    "asparagine": 0.12
  }
]''';
  }
}

class ImportResult {
  final int totalProcessed;
  final int successCount;
  final List<String> errors;

  ImportResult({
    required this.totalProcessed,
    required this.successCount,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => successCount > 0;
}
