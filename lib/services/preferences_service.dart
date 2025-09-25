import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class PreferencesService {
  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      name: prefs.getString("name") ?? "",
      weight: prefs.getDouble("weight") ?? 0,
      height: prefs.getDouble("height") ?? 0,
      carbs: prefs.getInt("carbs") ?? 50,
      protein: prefs.getInt("protein") ?? 20,
      fat: prefs.getInt("fat") ?? 30,
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("name", profile.name);
    await prefs.setDouble("weight", profile.weight);
    await prefs.setDouble("height", profile.height);
    await prefs.setInt("carbs", profile.carbs);
    await prefs.setInt("protein", profile.protein);
    await prefs.setInt("fat", profile.fat);
  }
}
