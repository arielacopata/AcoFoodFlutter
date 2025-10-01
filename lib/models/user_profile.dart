// lib/models/user_profile.dart

class UserProfile {
  final int id;
  final String? name;
  final String? email;
  final DateTime? dob;
  final String? gender;
  final double? weight;
  final double? height;
  final String? lifestyle;
  final String? exerciseLevel;
  final int? expenditure;
  final int? carbs; // <-- AÑADIDO
  final int? protein; // <-- AÑADIDO
  final int? fat; // <-- AÑADIDO

  UserProfile({
    this.id = 1,
    this.name,
    this.email,
    this.dob,
    this.gender,
    this.weight,
    this.height,
    this.lifestyle,
    this.exerciseLevel,
    this.expenditure,
    this.carbs, // <-- AÑADIDO
    this.protein, // <-- AÑADIDO
    this.fat, // <-- AÑADIDO
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'weight': weight,
      'height': height,
      'lifestyle': lifestyle,
      'exerciseLevel': exerciseLevel,
      'expenditure': expenditure,
      'carbs': carbs, // <-- AÑADIDO
      'protein': protein, // <-- AÑADIDO
      'fat': fat, // <-- AÑADIDO
    };
  }

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      dob: map['dob'] != null ? DateTime.parse(map['dob']) : null,
      gender: map['gender'],
      weight: map['weight'],
      height: map['height'],
      lifestyle: map['lifestyle'],
      exerciseLevel: map['exerciseLevel'],
      expenditure: map['expenditure'],
      carbs: map['carbs'], // <-- AÑADIDO
      protein: map['protein'], // <-- AÑADIDO
      fat: map['fat'], // <-- AÑADIDO
    );
  }
}
