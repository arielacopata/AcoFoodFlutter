import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'home_page.dart';
import 'services/food_repository.dart'; // <-- 1. Importa el repositorio
import 'services/storage_factory.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'services/firestore_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 AGREGAR ESTAS 3 LÍNEAS
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('es', null);
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
    if (!kIsWeb) {
      _loadProfile(); // Solo móvil
    }
  }

  Widget _buildSplash() {
    return Center(
      // ← AGREGAR ESTE CENTER
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elementos decorativos (aguacate + tomate + brócoli)
          Image.asset(
            'assets/icons/splash_elements.png',
            width: 250,
            height: 250,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 32),

          const Text(
            'AcoFood',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D4B32),
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Seguimiento Nutricional Inteligente',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF2D4B32).withOpacity(0.8),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
        ],
      ),
    );
  }

  // CAMBIO: Carga desde DatabaseService (SQLite)
  Future<void> _loadProfile() async {
    try {
      // TEMPORAL: Para ver el splash
      await Future.delayed(const Duration(seconds: 3));
      final loaded = await StorageFactory.instance.getUserProfile();

      if (loaded == null) {
        final defaultProfile = UserProfile(id: 1, name: "Default");
        await StorageFactory.instance.saveUserProfile(defaultProfile);

        setState(() {
          profile = defaultProfile;
        });
      } else {
        setState(() {
          profile = loaded;
        });
      }
    } catch (e, st) {
      print(st);
      setState(() {
        profile = UserProfile(id: 1, name: "Error");
      });
    }
  }

  // CAMBIO: Guarda en DatabaseService (SQLite)
  Future<void> _saveProfile(UserProfile newProfile) async {
    await StorageFactory.instance.saveUserProfile(newProfile);
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
    // Solo en móvil esperar a que cargue profile
    if (!kIsWeb && profile == null) {
      return MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('es', 'ES')],
        locale: Locale('es', 'ES'),
        home: Scaffold(
          backgroundColor: const Color(0xFFF0F8F3),
          body: _buildSplash(), // ← ACÁ USA EL SPLASH PERSONALIZADO
        ),
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
      home: kIsWeb ? _buildWebHome() : _buildMobileHome(),
    );
  }

  Future<UserProfile?> _initializeWebData() async {
    // Inicializar hábitos por defecto si no existen
    await initializeDefaultHabits();

    // Cargar perfil
    return await StorageFactory.instance.getUserProfile();
  }

  Future<void> initializeDefaultHabits() async {
    final storage = StorageFactory.instance as FirestoreStorageService;
    final existing = await storage.getAllHabits();

    if (existing.isNotEmpty) return; // Ya hay hábitos

    // Crear hábitos usando el método que agregamos en Firestore
    await storage
        .initializeDefaultHabits(); // 👈 Este método lo vamos a hacer público
  }

  Widget _buildWebHome() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Usuario autenticado, cargar perfil de Firestore
          return FutureBuilder<UserProfile?>(
            future:
                _initializeWebData(), // 👈 Cambiar a un método que haga todo
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Usar perfil de Firestore o crear uno nuevo
              final firebaseProfile =
                  profileSnapshot.data ?? UserProfile(id: 1, name: "Usuario");

              return HomePage(
                profile: firebaseProfile,
                onUpdateProfile: _saveProfile,
                onToggleTheme: _toggleTheme,
              );
            },
          );
        }

        return const LoginScreen();
      },
    );
  }

  Widget _buildMobileHome() {
    // En móvil va directo a la app
    return HomePage(
      profile: profile!,
      onUpdateProfile: _saveProfile,
      onToggleTheme: _toggleTheme,
    );
  }
}
