import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'services/preferences_service.dart';
import 'home_page.dart';
import 'services/food_repository.dart'; // <-- 1. Importa el repositorio

void main() async {
  // <-- 2. Conviértelo en async
  // Asegúrate de que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // <-- 3. Carga los alimentos antes de correr la app
  await FoodRepository().loadFoods();

  runApp(const AcoFoodApp());
}

class AcoFoodApp extends StatefulWidget {
  const AcoFoodApp({super.key});

  @override
  State<AcoFoodApp> createState() => _AcoFoodAppState();
}

class _AcoFoodAppState extends State<AcoFoodApp> {
  ThemeMode _themeMode = ThemeMode.light;
  UserProfile profile = UserProfile();
  final PreferencesService _prefsService = PreferencesService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final loaded = await _prefsService.loadProfile();
    setState(() {
      profile = loaded;
    });
  }

  Future<void> _saveProfile(UserProfile newProfile) async {
    await _prefsService.saveProfile(newProfile);
    setState(() {
      profile = newProfile;
    });
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AcoFood",
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: HomePage(
        profile: profile,
        onUpdateProfile: _saveProfile,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
