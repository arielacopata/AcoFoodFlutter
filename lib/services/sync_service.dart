import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/habit.dart';
import '../models/user_preferences.dart';
import 'database_service.dart';
import 'firestore_storage_service.dart';
import 'auth_service.dart';
import '../models/recipe.dart';

enum SyncStatus { notSynced, syncing, synced, error }

enum SyncStrategy {
  push, // Local → Cloud
  pull, // Cloud → Local
  merge, // Combinar ambos
}

class SyncService {
  final AuthService _authService = AuthService();
  final DatabaseService _localDb = DatabaseService.instance;
  late FirestoreStorageService _cloudDb;

  SyncStatus _status = SyncStatus.notSynced;
  String? _errorMessage;

  SyncStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isSynced => _status == SyncStatus.synced;

  // Inicializar Firestore storage
  void initialize() {
    if (_authService.currentUser != null) {
      _cloudDb = FirestoreStorageService();
    }
  }

  // Verificar si hay datos locales
  Future<bool> _localHasData() async {
    try {
      final entries = await _localDb.getAllEntries();
      return entries.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Verificar si hay datos en la nube
  Future<bool> _cloudHasData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('data')
          .doc('entries')
          .collection('history')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Determinar estrategia de sincronización
  Future<SyncStrategy?> _determineSyncStrategy() async {
    final localHasData = await _localHasData();
    final cloudHasData = await _cloudHasData();

    if (!localHasData && !cloudHasData) {
      return null; // Nada que sincronizar
    }

    if (localHasData && !cloudHasData) {
      return SyncStrategy.push; // Solo local → subir
    }

    if (!localHasData && cloudHasData) {
      return SyncStrategy.pull; // Solo cloud → bajar
    }

    // Ambos tienen datos → necesita decisión del usuario
    return SyncStrategy.merge;
  }

  // Sincronización principal
  Future<void> sync({SyncStrategy? forcedStrategy}) async {
    if (!_authService.isSignedIn) {
      throw Exception('Usuario no autenticado');
    }

    _status = SyncStatus.syncing;
    _errorMessage = null;

    try {
      initialize();

      final strategy = forcedStrategy ?? await _determineSyncStrategy();

      if (strategy == null) {
        _status = SyncStatus.synced;
        return; // Nada que hacer
      }

      switch (strategy) {
        case SyncStrategy.push:
          await _pushToCloud();
          break;
        case SyncStrategy.pull:
          await _pullFromCloud();
          break;
        case SyncStrategy.merge:
          // Este caso debe manejarse en la UI (mostrar diálogo)
          throw Exception('MERGE_REQUIRED');
      }

      _status = SyncStatus.synced;
    } catch (e) {
      _status = SyncStatus.error;
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // PUSH: Local → Cloud
  Future<void> _pushToCloud() async {
    print('📤 Iniciando PUSH: Local → Cloud');

    // 0. Limpiar datos antiguos en Firestore 👈 NUEVO
    print('🗑️ Limpiando datos antiguos en Firestore...');
    await _cloudDb.clearAllData();
    print('✅ Firestore limpio');

    // 1. Subir perfil
    print('⬆️ Subiendo perfil...');
    final profile = await _localDb.getUserProfile();
    if (profile != null) {
      await _cloudDb.saveUserProfile(profile);
    }
    print('✅ Perfil subido');

    // 2. Subir historial de comidas (CON BATCH REAL)
    print('⬆️ Subiendo entradas...');
    final entries = await _localDb.getAllEntries();
    print('   Total entradas: ${entries.length}');

    await _cloudDb.createEntriesBatch(entries); // 👈 Método batch de Firestore
    print('✅ Entradas subidas');

    // 3. Subir logs de hábitos (CON BATCH REAL)
    print('⬆️ Subiendo logs de hábitos...');
    final habitLogs = await _localDb.getAllHabitLogs();
    print('   Total logs: ${habitLogs.length}');

    await _cloudDb.createHabitLogsBatch(
      habitLogs,
    ); // 👈 Método batch de Firestore
    print('✅ Logs subidos');

    // 4. Subir recetas
    print('⬆️ Subiendo recetas...');
    final recipes = await _localDb.getAllRecipes();
    print('   Total recetas: ${recipes.length}');

    if (recipes.isNotEmpty) {
      // Preparar mapa de recetas con sus ingredientes
      final recipesWithIngredients = <Recipe, List<RecipeIngredient>>{};

      for (final recipe in recipes) {
        final ingredients = await _localDb.getRecipeIngredients(recipe.id!);
        recipesWithIngredients[recipe] = ingredients;
      }

      await _cloudDb.createRecipesBatch(recipesWithIngredients);
    }

    print('✅ Recetas subidas');

    // 5. Subir preferencias
    print('⬆️ Subiendo preferencias...');
    final prefs = await SharedPreferences.getInstance();
    final preferences = UserPreferences(
      b12Checked: prefs.getBool('b12_enabled') ?? true,
      linoChecked: prefs.getBool('lino_enabled') ?? true,
      legumbresChecked: prefs.getBool('legumbres_enabled') ?? true,
      yodoChecked: prefs.getBool('yodo_enabled') ?? true,
      sortOrder: prefs.getString('sort_order') ?? 'alfabetico',
      enabledHabitIds: [],
    );
    await _cloudDb.savePreferences(preferences);
    print('✅ Preferencias subidas');

    print('✅ PUSH completado');
  }

  // PULL: Cloud → Local
  Future<void> _pullFromCloud() async {
    print('📥 Iniciando PULL: Cloud → Local');

    // 1. Bajar perfil
    final profile = await _cloudDb.getUserProfile();
    if (profile != null) {
      await _localDb.saveUserProfile(profile);
    }

    // 2. Bajar historial de comidas (sin duplicar)
    print('⬇️ Bajando entradas...');
    final cloudEntries = await _cloudDb.getAllEntries();
    print('   Total entradas en Firestore: ${cloudEntries.length}');

    // Obtener entradas locales existentes
    final localEntries = await _localDb.getAllEntries();

    // Crear un Set de identificadores únicos (foodId + timestamp + grams)
    final existingEntries = <String>{};
    for (final entry in localEntries) {
      final key =
          '${entry.food.id}_${entry.timestamp.toIso8601String()}_${entry.grams}';
      existingEntries.add(key);
    }

    // Solo insertar entradas que NO existen localmente
    int newEntriesCount = 0;
    for (final entry in cloudEntries) {
      final key =
          '${entry.food.id}_${entry.timestamp.toIso8601String()}_${entry.grams}';

      if (!existingEntries.contains(key)) {
        await _localDb.createEntry(entry);
        newEntriesCount++;
      }
    }

    print('   Nuevas entradas agregadas: $newEntriesCount');
    print('   Duplicadas omitidas: ${cloudEntries.length - newEntriesCount}');
    print('✅ Entradas bajadas');
    // 3. Bajar logs de hábitos (sin duplicar)
    print('⬇️ Bajando logs de hábitos...');
    final cloudLogs = await _cloudDb.getAllHabitLogs();
    print('   Total logs en Firestore: ${cloudLogs.length}');

    // Obtener logs locales existentes
    final localLogs = await _localDb.getAllHabitLogs();

    // Crear un Set de identificadores únicos (habitId + date)
    final existingLogs = <String>{};
    for (final log in localLogs) {
      final key = '${log.habitId}_${log.date.toIso8601String().split('T')[0]}';
      existingLogs.add(key);
    }

    // Solo insertar logs que NO existen localmente
    int newLogsCount = 0;
    for (final log in cloudLogs) {
      final key = '${log.habitId}_${log.date.toIso8601String().split('T')[0]}';

      if (!existingLogs.contains(key)) {
        await _localDb.logHabit(
          log.habitId,
          log.detail ?? '',
          date: log.date,
          timestamp: log.timestamp,
        );
        newLogsCount++;
      }
    }

    print('   Nuevos logs agregados: $newLogsCount');
    print('   Duplicados omitidos: ${cloudLogs.length - newLogsCount}');
    print('✅ Logs de hábitos bajados');
    print('✅ Logs de hábitos bajados');

    // 4. Bajar recetas (sin duplicar)
    print('⬇️ Bajando recetas...');
    final cloudRecipes = await _cloudDb.getAllRecipes();
    print('   Total recetas en Firestore: ${cloudRecipes.length}');

    if (cloudRecipes.isNotEmpty) {
      final localRecipes = await _localDb.getAllRecipes();
      final existingNames = localRecipes.map((r) => r.name).toSet();

      int newRecipesCount = 0;
      for (final cloudRecipe in cloudRecipes) {
        if (!existingNames.contains(cloudRecipe.name)) {
          // Obtener ingredientes de Firestore
          final cloudIngredients = await _cloudDb.getRecipeIngredients(
            cloudRecipe.id!,
          );

          // Guardar receta con ingredientes en SQLite
          await _localDb.saveRecipe(cloudRecipe, cloudIngredients);

          newRecipesCount++;
        }
      }

      print('   Nuevas recetas agregadas: $newRecipesCount');
      print('   Duplicadas omitidas: ${cloudRecipes.length - newRecipesCount}');
    }
    print('✅ Recetas bajadas');

    // 5. Bajar preferencias
    print('⬇️ Bajando preferencias...');
    final preferences = await _cloudDb.getPreferences();
    if (preferences != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('b12_enabled', preferences.b12Checked); // 👈 _enabled
      await prefs.setBool(
        'lino_enabled',
        preferences.linoChecked,
      ); // 👈 _enabled
      await prefs.setBool(
        'legumbres_enabled',
        preferences.legumbresChecked,
      ); // 👈 _enabled
      await prefs.setBool(
        'yodo_enabled',
        preferences.yodoChecked,
      ); // 👈 _enabled
      await prefs.setString('sort_order', preferences.sortOrder);
    }
    print('✅ Preferencias bajadas');

    // Marcar suplementos como completados basándose en el historial
    print('🔖 Marcando suplementos completados...');
    await _markCompletedSupplements();
    print('✅ Suplementos marcados');

    print('✅ PULL completado');
  }

  Future<void> _markCompletedSupplements() async {
    final prefs = await SharedPreferences.getInstance();
    final localEntries = await _localDb.getAllEntries();

    // Agrupar entradas por fecha
    final entriesByDate = <String, List<FoodEntry>>{};
    for (final entry in localEntries) {
      final dateKey = entry.timestamp.toIso8601String().split(
        'T',
      )[0]; // 👈 timestamp
      entriesByDate.putIfAbsent(dateKey, () => []).add(entry);
    }

    // Marcar suplementos completados para cada día
    for (final dateKey in entriesByDate.keys) {
      final dayEntries = entriesByDate[dateKey]!;

      // B12 (id: 9001)
      if (dayEntries.any((e) => e.food.id == 9001)) {
        // 👈 food.id
        await prefs.setBool('b12_completed_$dateKey', true);
      }

      // Yodo (id: 9004)
      if (dayEntries.any((e) => e.food.id == 9004)) {
        // 👈 food.id
        await prefs.setBool('yodo_completed_$dateKey', true);
      }
    }
  }

  // Merge: Combinar datos locales y cloud (estrategia: mantener ambos)
  Future<void> mergeData() async {
    print('🔄 Iniciando MERGE');

    // Estrategia simple: subir todo lo local que no exista en cloud
    // (requiere comparación por timestamp o ID único)

    // Por ahora, usamos PUSH para no perder datos locales
    await _pushToCloud();

    print('✅ MERGE completado');
  }

  // Desconectar sincronización
  Future<void> disconnect() async {
    await _authService.signOut();
    _status = SyncStatus.notSynced;
  }
}
