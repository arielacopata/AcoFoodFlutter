import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class PreferencesService {
  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      name: prefs.getString("name"),
      weight: prefs.getDouble("weight"),
      height: prefs.getDouble("height"),
      // Ahora leemos los nuevos valores, con un valor por defecto si no existen
      carbs: prefs.getInt("carbs") ?? 50, // <-- CORREGIDO
      protein: prefs.getInt("protein") ?? 30, // <-- CORREGIDO
      fat: prefs.getInt("fat") ?? 20, // <-- CORREGIDO
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    // Usamos '??' para dar un valor por defecto si el campo es null
    await prefs.setString("name", profile.name ?? ''); // <-- CORREGIDO
    await prefs.setDouble("weight", profile.weight ?? 0.0); // <-- CORREGIDO
    await prefs.setDouble("height", profile.height ?? 0.0); // <-- CORREGIDO
    await prefs.setInt("carbs", profile.carbs ?? 50); // <-- CORREGIDO
    await prefs.setInt("protein", profile.protein ?? 30); // <-- CORREGIDO
    await prefs.setInt("fat", profile.fat ?? 20); // <-- CORREGIDO
  }
}
