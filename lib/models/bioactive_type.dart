// lib/models/bioactive_type.dart

enum BioactiveType {
  // Polifenoles
  totalPolyphenols,
  totalFlavonoids,
  quercetin,
  kaempferol,
  catechins,
  resveratrol,

  // Ácidos Fenólicos
  ferulicAcid,
  caffeicAcid,
  ellagicAcid,

  // Lignanos & Isoflavonas
  totalLignans,
  sdg,
  totalIsoflavones,
  genistein,

  // Antinutrientes
  phyticAcid,
  lectins,
  tannins,
  oxalates,

  // Marcadores
  orac,
  nitrates,
  glucosinolates,

  // Especiales
  sulforaphane,
  glucoraphanin,
  indoles,
  melatonin,
  gammaTocopherol,
  phytosterols;

  // Getter de Metadata
  BioactiveMeta get meta {
    switch (this) {
      case BioactiveType.sulforaphane:
        return const BioactiveMeta(
          name: "Sulforafano",
          unit: "mg",
          description: "Inductor maestro de las defensas antioxidantes (Nrf2).",
        );
      case BioactiveType.ellagicAcid:
        return const BioactiveMeta(
          name: "Ácido Elágico",
          unit: "mg",
          description: "Antioxidante potente asociado a la salud celular.",
        );
      case BioactiveType.melatonin:
        return const BioactiveMeta(
          name: "Melatonina Veg.",
          unit: "mcg",
          description: "Hormona del sueño y antioxidante mitocondrial.",
        );
      case BioactiveType.orac:
        return const BioactiveMeta(
          name: "Capacidad ORAC",
          unit: "µmol TE",
          description: "Medida de la potencia antioxidante total.",
        );
      // ... Agrega el resto aquí ...
      default:
        // Fallback genérico para evitar errores si falta alguno
        return BioactiveMeta(name: name, unit: "mg", description: "");
    }
  }
}

class BioactiveMeta {
  final String name;
  final String unit;
  final String description;

  const BioactiveMeta({
    required this.name,
    required this.unit,
    required this.description,
  });
}
