import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'home_page.dart';
import 'services/food_repository.dart'; // <-- 1. Importa el repositorio
import 'services/database_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart'; 

void main() async {
  // <-- 2. Conviértelo en async
  // Asegúrate de que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('es', null);
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
  UserProfile? profile;
  // final PreferencesService _prefsService = PreferencesService();
  final bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // CAMBIO: Carga desde DatabaseService (SQLite)
  Future<void> _loadProfile() async {
    try {
      final loaded = await DatabaseService.instance.getUserProfile();

      if (loaded == null) {
        final defaultProfile = UserProfile(id: 1, name: "Default");
        await DatabaseService.instance.saveUserProfile(defaultProfile);

        setState(() {
          profile = defaultProfile;
        });

        print("DEBUG: Perfil por defecto creado");
      } else {
        setState(() {
          profile = loaded;
        });

        print("DEBUG: Perfil cargado: ${loaded.name}");
      }
    } catch (e, st) {
      print("ERROR en _loadProfile: $e");
      print(st);
      setState(() {
        profile = UserProfile(id: 1, name: "Error");
      });
    }
  }

  // CAMBIO: Guarda en DatabaseService (SQLite)
  Future<void> _saveProfile(UserProfile newProfile) async {
    await DatabaseService.instance.saveUserProfile(newProfile);
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
    // Mientras 'profile' es null, podrías mostrar una pantalla de carga
    if (profile == null) {
  return const MaterialApp(
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [Locale('es', 'ES')],
    locale: Locale('es', 'ES'),
    home: Scaffold(body: Center(child: CircularProgressIndicator())),
    debugShowCheckedModeBanner: false,
  );
}
return MaterialApp(
  title: "AcoFood",
  debugShowCheckedModeBanner: false,
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: _themeMode,
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('es', 'ES')],
  locale: const Locale('es', 'ES'),
  home: HomePage(
    profile: profile!,
    onUpdateProfile: _saveProfile,
    onToggleTheme: _toggleTheme,
  ),
);
  }
}
