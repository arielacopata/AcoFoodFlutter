import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';

class ImportService {
  static Future<bool> importFromJson(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      
      // Validar versión
      final version = data['version'] as String?;
      if (version != '1.0') {
        print('Versión de backup no compatible: $version');
        return false;
      }
      
      final db = await DatabaseService.instance.database;
      
      // 1. Restaurar perfil
      if (data['profile'] != null) {
        final profileData = data['profile'] as Map<String, dynamic>;
        final profile = UserProfile.fromMap(profileData);
        await DatabaseService.instance.saveUserProfile(profile);
      }
      
      // 2. Limpiar y restaurar historial
      await db.delete('history');
      final history = data['history'] as List<dynamic>?;
      if (history != null) {
        for (final entry in history) {
          await db.insert('history', entry as Map<String, dynamic>);
        }
      }
      
      // 3. Limpiar y restaurar logs de hábitos
      await db.delete('habit_logs');
      final habitLogs = data['habitLogs'] as List<dynamic>?;
      if (habitLogs != null) {
        for (final log in habitLogs) {
          await db.insert('habit_logs', log as Map<String, dynamic>);
        }
      }
      
      // 4. Restaurar contadores de uso
      await db.delete('food_usage');
      final foodUsage = data['foodUsage'] as List<dynamic>?;
      if (foodUsage != null) {
        for (final usage in foodUsage) {
          await db.insert('food_usage', usage as Map<String, dynamic>);
        }
      }
      
      // 5. Restaurar preferencias
      final prefs = await SharedPreferences.getInstance();
      final preferences = data['preferences'] as Map<String, dynamic>?;
      if (preferences != null) {
        if (preferences['sort_order'] != null) {
          await prefs.setString('sort_order', preferences['sort_order']);
        }
        if (preferences['theme_mode'] != null) {
          await prefs.setString('theme_mode', preferences['theme_mode']);
        }
        if (preferences['b12_enabled'] != null) {
          await prefs.setBool('b12_enabled', preferences['b12_enabled']);
        }
        if (preferences['lino_enabled'] != null) {
          await prefs.setBool('lino_enabled', preferences['lino_enabled']);
        }
        if (preferences['legumbres_enabled'] != null) {
          await prefs.setBool('legumbres_enabled', preferences['legumbres_enabled']);
        }
      }
      
      return true;
    } catch (e) {
      print('Error importando backup: $e');
      return false;
    }
  }
}