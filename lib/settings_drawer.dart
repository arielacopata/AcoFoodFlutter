import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_factory.dart';
import '../models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/calorie_calculator.dart';
import '../models/recipe.dart';
import '../screens/custom_foods_import_screen.dart';
import '../widgets/recipe_portion_sheet.dart';
import '../models/food_entry.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/food_repository.dart';

// import '../services/google_fit_service.dart';

class SettingsDrawer extends StatefulWidget {
  final UserProfile? profile;
  final Function(UserProfile)? onProfileUpdated;
  final VoidCallback? onHistoryChanged;
  final Function(String)? onSortOrderChanged;
  final Function()? onRemindersChanged;
  final VoidCallback onOpenImportExport;
  final VoidCallback? onRecipeUsed;
  final TextEditingController searchController;
  final VoidCallback onClearSearch;

  const SettingsDrawer({
    super.key,
    required this.searchController,
    required this.onClearSearch,
    this.profile,
    this.onProfileUpdated,
    this.onHistoryChanged,
    this.onSortOrderChanged,
    this.onRemindersChanged,
    required this.onOpenImportExport,
    this.onRecipeUsed,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SettingsDrawerState createState() => _SettingsDrawerState();
}

// ignore: library_private_types_in_public_api
class _SettingsDrawerState extends State<SettingsDrawer> {
  int _secretTapCount = 0;
  bool _secretMenuEnabled = false;
  double _suggestionThreshold = 85.0; // Umbral de sugerencias

  // Controladores para los campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _expenditureController = TextEditingController();
  // Variables para las metas de macros
  int _carbsPercentage = 70;
  int _proteinPercentage = 20;
  int _fatPercentage = 10;
  bool _b12Checked = false;
  bool _linoChecked = false;
  bool _legumbresChecked = false;
  bool _yodoChecked = true;
  String _sortOrder = 'alfabetico'; // 'alfabetico' o 'mas_usados'
  bool _googleFitEnabled = false;

  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();
  bool _isSyncing = false;

  // Variables para los seleccionables
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedLifestyle;
  String? _selectedExerciseLevel;

  // Mapa que replica tu lógica de JavaScript para los niveles de ejercicio
  final Map<String, List<String>> _exerciseLevels = {
    '1': ["1: Sedentario", "2: Bajo (1-2 días/sem)"],
    '2': [
      "2: Bajo (1-2 días/sem)",
      "3: Medio (3-4 días/sem)",
      "4: Alto (4-5 días/sem)",
    ],
    '3': ["3: Medio (3-4 días/sem)", "4: Alto (4-5 días/sem)", "5: Diario"],
    '4': ["4: Alto (4-5 días/sem)", "5: Diario", "6: Diario (Doble Turno)"],
  };

  // Lista que contendrá las opciones del segundo dropdown
  List<String> _currentExerciseOptions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestionThreshold();
    // Poblar los campos con los datos del perfil si existen
    if (widget.profile != null) {
      _nameController.text = widget.profile!.name ?? '';
      _emailController.text = widget.profile!.email ?? '';
      _weightController.text = widget.profile!.weight?.toString() ?? '';
      _heightController.text = widget.profile!.height?.toString() ?? '';
      _expenditureController.text =
          widget.profile!.expenditure?.toString() ?? '';
      _selectedDate = widget.profile!.dob;
      _selectedGender = widget.profile!.gender;
      _selectedLifestyle = widget.profile!.lifestyle;
      // Cargar metas de macros si existen
      _carbsPercentage = widget.profile!.carbs ?? 65;
      _proteinPercentage = widget.profile!.protein ?? 10;
      _fatPercentage = widget.profile!.fat ?? 25;
      //      _loadGoogleFitStatus();

      // Lógica para el dropdown dependiente
      if (_selectedLifestyle != null) {
        _currentExerciseOptions = _exerciseLevels[_selectedLifestyle!] ?? [];
        _selectedExerciseLevel = widget.profile!.exerciseLevel;
      }
    }
    _loadReminders();
    _loadSortOrder();
  }

  Future<void> _loadSortOrder() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortOrder = prefs.getString('sort_order') ?? 'alfabetico';
    });
  }

  @override
  void dispose() {
    // Limpiar los controladores
    _nameController.dispose();
    _emailController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _expenditureController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _b12Checked = prefs.getBool('b12_enabled') ?? true;
      _linoChecked = prefs.getBool('lino_enabled') ?? true;
      _legumbresChecked = prefs.getBool('legumbres_enabled') ?? true;
      _yodoChecked = prefs.getBool('yodo_enabled') ?? true;
    });
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('b12_enabled', _b12Checked);
    await prefs.setBool('lino_enabled', _linoChecked);
    await prefs.setBool('legumbres_enabled', _legumbresChecked);
    await prefs.setBool('yodo_enabled', _yodoChecked);

    // Notificar al home_page que se actualizaron los recordatorios
    if (widget.onRemindersChanged != null) {
      widget.onRemindersChanged!();
    }
  }

  Future<void> _loadSuggestionThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _suggestionThreshold = prefs.getDouble('suggestion_threshold') ?? 85.0;
    });
  }

  Future<void> _saveSuggestionThreshold(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('suggestion_threshold', value);
    setState(() {
      _suggestionThreshold = value;
    });
  }

  Future<void> _showSuggestionThresholdDialog() async {
    final options = [75.0, 85.0, 100.0, 150.0, 200.0, 300.0];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Umbral de sugerencias'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecciona el porcentaje debajo del cual se mostrarán sugerencias de alimentos:',
            ),
            const SizedBox(height: 16),
            ...options.map((value) => RadioListTile<double>(
                  title: Text('${value.toInt()}%'),
                  value: value,
                  groupValue: _suggestionThreshold,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      _saveSuggestionThreshold(newValue);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Umbral actualizado a ${newValue.toInt()}%',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // Función para mostrar el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Lógica para guardar el perfil
  void _saveProfile() async {
    final profile = UserProfile(
      id: 1,
      name: _nameController.text,
      email: _emailController.text,
      dob: _selectedDate,
      gender: _selectedGender,
      weight: double.tryParse(_weightController.text) ?? 0.0,
      height: double.tryParse(_heightController.text) ?? 0.0,
      lifestyle: _selectedLifestyle,
      exerciseLevel: _selectedExerciseLevel,
      expenditure: int.tryParse(_expenditureController.text) ?? 0,
    );

    await StorageFactory.instance.saveUserProfile(profile);

    // 👇 NUEVO: Notifica al padre
    if (widget.onProfileUpdated != null) {
      widget.onProfileUpdated!(profile);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado con éxito')),
      );
      Navigator.of(context).pop();
    }
  }

  // Lógica para guardar las metas de macros
  void _saveGoals() async {
    final updatedProfile = UserProfile(
      id: widget.profile!.id,
      name: widget.profile!.name,
      email: widget.profile!.email,
      dob: widget.profile!.dob,
      gender: widget.profile!.gender,
      weight: widget.profile!.weight,
      height: widget.profile!.height,
      lifestyle: widget.profile!.lifestyle,
      exerciseLevel: widget.profile!.exerciseLevel,
      expenditure: widget.profile!.expenditure,
      carbs: _carbsPercentage,
      protein: _proteinPercentage,
      fat: _fatPercentage,
    );

    await StorageFactory.instance.saveUserProfile(updatedProfile);

    if (widget.onProfileUpdated != null) {
      widget.onProfileUpdated!(updatedProfile);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metas guardadas con éxito')),
      );
      Navigator.of(context).pop();
    }
  }

  String _getGoalText() {
    if (widget.profile?.goalType == null) return 'No configurado';

    switch (widget.profile!.goalType) {
      case 'deficit':
        return 'Bajar peso (-500 kcal/día)';
      case 'maintain':
        return 'Mantener peso';
      case 'surplus':
        return 'Subir peso (+300 kcal/día)';
      default:
        return 'No configurado';
    }
  }

  Future<void> _showGoalDialog() async {
    final goal = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Objetivo de peso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Bajar peso'),
              subtitle: const Text('Déficit de 500 kcal/día'),
              onTap: () => Navigator.pop(context, 'deficit'),
            ),
            ListTile(
              title: const Text('Mantener peso'),
              subtitle: const Text('Sin ajuste calórico'),
              onTap: () => Navigator.pop(context, 'maintain'),
            ),
            ListTile(
              title: const Text('Subir peso'),
              subtitle: const Text('Superávit de 300 kcal/día'),
              onTap: () => Navigator.pop(context, 'surplus'),
            ),
          ],
        ),
      ),
    );

    if (goal != null && widget.profile != null) {
      final maintenanceCalories =
          CalorieCalculator.calculateRecommendedCalories(
            dob: widget.profile!.dob,
            gender: widget.profile!.gender,
            weight: widget.profile!.weight,
            height: widget.profile!.height,
            lifestyle: widget.profile!.lifestyle,
            exerciseLevel: widget.profile!.exerciseLevel,
            expenditure: widget.profile!.expenditure,
          ).toInt();

      int goalCalories = maintenanceCalories;

      switch (goal) {
        case 'deficit':
          goalCalories -= 500;
          break;
        case 'surplus':
          goalCalories += 300;
          break;
      }

      final updatedProfile = UserProfile(
        id: widget.profile!.id,
        name: widget.profile!.name,
        email: widget.profile!.email,
        dob: widget.profile!.dob,
        gender: widget.profile!.gender,
        weight: widget.profile!.weight,
        height: widget.profile!.height,
        lifestyle: widget.profile!.lifestyle,
        exerciseLevel: widget.profile!.exerciseLevel,
        expenditure: widget.profile!.expenditure,
        carbs: widget.profile!.carbs,
        protein: widget.profile!.protein,
        fat: widget.profile!.fat,
        goalType: goal,
        goalCalories: goalCalories,
      );

      await StorageFactory.instance.saveUserProfile(updatedProfile);
      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!(updatedProfile);
      }

      if (widget.onHistoryChanged != null) {
        // ← Agregar esto
        widget.onHistoryChanged!(); // ← y esto
      }
      setState(() {});
    }
  }

  void _showRecipesManager() {
    final drawerContext = context;
    Navigator.pop(context); // Cerrar drawer

    showModalBottomSheet(
      context: drawerContext,
      isScrollControlled: true,
      builder: (modalContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis Recetas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Recipe>>(
                  future: StorageFactory.instance.getAllRecipes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay recetas guardadas',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Agrega varios ingredientes y guárdalos como receta',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final recipes = snapshot.data!;

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        return Card(
                          child: ListTile(
                            leading: Text(
                              recipe.emoji ?? '🍽️',
                              style: const TextStyle(fontSize: 32),
                            ),
                            title: Text(recipe.name),
                            subtitle: Text(
                              'Creada: ${_formatDate(recipe.createdAt ?? DateTime.now())}', // 👈 Agregar ?? DateTime.now()
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  onPressed: () =>
                                      _showRecipeDetails(modalContext, recipe),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDeleteRecipe(
                                    modalContext,
                                    recipe,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () =>
                                _showRecipeDetails(modalContext, recipe),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} semanas';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showRecipeDetails(BuildContext ctx, Recipe recipe) async {
    final ingredients = await StorageFactory.instance.getRecipeIngredients(
      recipe.id!,
    );

    if (!ctx.mounted) return;

    await showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: Text('${recipe.emoji ?? "🍽️"} ${recipe.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingredientes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...ingredients.map(
              (ing) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${ing.grams.toStringAsFixed(0)}g de ${ing.food.name}',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Cerrar el diálogo primero

              // Esperar un frame para que se complete el cierre
              await Future.delayed(const Duration(milliseconds: 100));

              // Ahora sí llamar a usar la receta
              if (ctx.mounted) {
                await _useRecipe(ctx, recipe, ingredients);
              }
            },
            child: const Text('Usar receta'),
          ),
        ],
      ),
    );
  }

  Future<void> _useRecipe(
    BuildContext ctx,
    Recipe recipe,
    List<RecipeIngredient> ingredients,
  ) async {
    if (!ctx.mounted) return;

    // Mostrar el sheet para seleccionar porciones
    final portion = await showModalBottomSheet<double>(
      context: ctx,
      isScrollControlled: true,
      builder: (context) =>
          RecipePortionSheet(recipe: recipe, ingredients: ingredients),
    );

    // Si canceló, no hacer nada
    if (portion == null) return;

    if (!ctx.mounted) return;

    // Registrar cada ingrediente con la cantidad ajustada por la porción
    for (final ingredient in ingredients) {
      final adjustedGrams = ingredient.grams * portion;
      final newEntry = FoodEntry(food: ingredient.food, grams: adjustedGrams);

      await StorageFactory.instance.createEntry(newEntry);
      await StorageFactory.instance.incrementFoodUsage(ingredient.food.id!);
    }

    if (!ctx.mounted) return;

    Navigator.of(ctx).pop(); // Cerrar gestor de recetas

    if (widget.onRecipeUsed != null) {
      widget.onRecipeUsed!();
    }

    // Mostrar mensaje con info de las porciones
    final portionText = portion == 1.0
        ? '1 porción'
        : portion == portion.toInt()
        ? '${portion.toInt()} porciones'
        : '$portion porciones';

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('✅ Registrado: ${recipe.name} ($portionText)'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDeleteRecipe(BuildContext ctx, Recipe recipe) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar receta'),
        content: Text('¿Eliminar "${recipe.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageFactory.instance.deleteRecipe(recipe.id!);

      Navigator.of(ctx).pop();
      _showRecipesManager();

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Receta "${recipe.name}" eliminada')),
      );
    }
  }

  // Diálogo de confirmación para borrar datos
  void _showDeleteConfirmationDialog(
    TextEditingController searchController,
  ) async {
    bool deleteCustomFoods = false; // Estado del checkbox

    // 🔍 Verificar si existen alimentos personalizados (id >= 10000)

    final hasCustomFoods = await StorageFactory.instance.hasCustomFoods();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirmar Borrado'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Estás seguro de que querés borrar todos los registros de alimentos de hoy?',
                  ),
                  const SizedBox(height: 16),
                  // ✅ Solo mostrar si hay alimentos personalizados
                  if (hasCustomFoods)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'También borrar alimentos personalizados',
                      ),
                      subtitle: const Text(
                        'Limpia todos los alimentos importados',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: deleteCustomFoods,
                      onChanged: (value) {
                        setState(() {
                          deleteCustomFoods = value ?? false;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text(
                    'Borrar',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      await StorageFactory.instance.clearTodayHistory();

      if (deleteCustomFoods) {
        await StorageFactory.instance.deleteAllCustomFoods();
        await FoodRepository().loadFoods(forceReload: true);
      }

      if (mounted) {
        // Limpiar búsqueda y quitar foco
        searchController.clear(); // ← Usar el parámetro
        widget.onClearSearch(); // ← Llamar el callback
        FocusScope.of(context).unfocus(); // ← Quita el foco

        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteCustomFoods
                  ? '✅ Datos del día y alimentos personalizados borrados'
                  : '✅ Registros de hoy borrados',
            ),
          ),
        );
      }
    }
  }

  // Métodos de sincronización
  Future<void> _handleSync() async {
    if (!_authService.isSignedIn) {
      // No está logueado → hacer login primero
      await _handleLogin();
      return;
    }

    // Ya está logueado → sincronizar
    await _performSync();
  }

  Future<void> _handleLogin() async {
    setState(() => _isSyncing = true);

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        // Usuario canceló
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Login cancelado')));
        }
        return;
      }

      // Login exitoso → ahora sincronizar
      await _performSync();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e')));
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _performSync() async {
    setState(() => _isSyncing = true);

    try {
      // Intentar sincronización automática
      await _syncService.sync();

      if (mounted) {
        // 1️⃣ Recargar perfil desde la base de datos
        final updatedProfile = await StorageFactory.instance.getUserProfile();
        if (updatedProfile != null && widget.onProfileUpdated != null) {
          widget.onProfileUpdated!(updatedProfile);
        }

        // 2️⃣ Recargar historial de alimentos 👈 AGREGAR ESTO
        if (widget.onHistoryChanged != null) {
          widget.onHistoryChanged!();
        }
        // 3️⃣ Recargar recordatorios 👈 AGREGAR ESTO
        if (widget.onRemindersChanged != null) {
          widget.onRemindersChanged!();
        }

        // 4️⃣ Cerrar drawer
        Navigator.pop(context);

        // 5️⃣ Mostrar SnackBar (ahora sí se ve)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sincronización completada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (e.toString().contains('MERGE_REQUIRED')) {
        // Conflicto: ambos tienen datos
        await _showMergeDialog();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al sincronizar: $e')));
        }
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _showMergeDialog() async {
    final strategy = await showDialog<SyncStrategy>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Conflicto de datos'),
        content: const Text(
          'Tienes datos tanto en este dispositivo como en la nube.\n\n'
          '¿Qué deseas hacer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, SyncStrategy.push),
            child: const Text('Subir datos de este dispositivo'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, SyncStrategy.pull),
            child: const Text('Bajar datos de la nube'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (strategy != null) {
      setState(() => _isSyncing = true);
      try {
        await _syncService.sync(forcedStrategy: strategy);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sincronización completada'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _handleDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar sincronización'),
        content: const Text(
          'Tus datos locales se mantendrán, pero ya no se sincronizarán con la nube.\n\n'
          '¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _syncService.disconnect();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronización desconectada')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _secretTapCount++;
                  if (_secretTapCount >= 8) {
                    _secretTapCount = 0;
                    _secretMenuEnabled = !_secretMenuEnabled;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _secretMenuEnabled
                              ? '🔓 Menú tester activado'
                              : '🔒 Menú tester desactivado',
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: _secretMenuEnabled
                            ? Colors.green
                            : Colors.grey,
                      ),
                    );
                  }
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Configuración',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  // Selector dentro del header azul
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _sortOrder,
                      dropdownColor: Colors.blue.shade700,
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'alfabetico',
                          child: Row(
                            children: [
                              Icon(
                                Icons.sort_by_alpha,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text('Orden: Alfabético'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'mas_usados',
                          child: Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text('Orden: Más usados'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          setState(() => _sortOrder = value);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('sort_order', value);
                          if (widget.onSortOrderChanged != null) {
                            widget.onSortOrderChanged!(value);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ), // drawerheader
          const SizedBox(height: 12),
          // Usamos ExpansionTile para replicar el <details> de HTML
          ExpansionTile(
            title: const Text('Perfil de Usuario'),
            initiallyExpanded: false,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _selectedDate == null
                            ? 'Fecha de Nacimiento'
                            : 'Nacimiento: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(labelText: 'Sexo'),
                      items: const [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Masculino'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Femenino'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Peso (kg)'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Altura (cm)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLifestyle,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Estilo de Vida',
                      ),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('Sedentario')),
                        DropdownMenuItem(
                          value: '2',
                          child: Text('Sedentario + Ejercicio'),
                        ),
                        DropdownMenuItem(
                          value: '3',
                          child: Text('Activo + Ejercicio'),
                        ),
                        DropdownMenuItem(value: '4', child: Text('Atleta')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLifestyle = value;
                          _selectedExerciseLevel = null;
                          _currentExerciseOptions =
                              _exerciseLevels[value] ?? [];
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // Dropdown dependiente para Nivel de Ejercicio
                    if (_selectedLifestyle != null)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedExerciseLevel,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Nivel de Ejercicio',
                        ),
                        items: _currentExerciseOptions.map((String level) {
                          return DropdownMenuItem<String>(
                            value: level.substring(0, 1),
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedExerciseLevel = value),
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _expenditureController,
                      decoration: const InputDecoration(
                        labelText: 'Gasto calórico de ayer (kcal)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      onPressed: _saveProfile,
                      child: const Text('Guardar Perfil'),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('Metas de Macros'),
            initiallyExpanded: false,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    Text(
                      'Total: ${_carbsPercentage + _proteinPercentage + _fatPercentage}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            (_carbsPercentage +
                                    _proteinPercentage +
                                    _fatPercentage ==
                                100)
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Slider Carbohidratos
                    Row(
                      children: [
                        const Expanded(child: Text('Carbohidratos')),
                        Text(
                          '$_carbsPercentage%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _carbsPercentage.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '$_carbsPercentage%',
                      onChanged: (value) {
                        setState(() => _carbsPercentage = value.round());
                      },
                    ),
                    const SizedBox(height: 8),
                    // Slider Proteínas
                    Row(
                      children: [
                        const Expanded(child: Text('Proteínas')),
                        Text(
                          '$_proteinPercentage%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _proteinPercentage.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '$_proteinPercentage%',
                      onChanged: (value) {
                        setState(() => _proteinPercentage = value.round());
                      },
                    ),
                    const SizedBox(height: 8),
                    // Slider Grasas
                    Row(
                      children: [
                        const Expanded(child: Text('Grasas')),
                        Text(
                          '$_fatPercentage%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _fatPercentage.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '$_fatPercentage%',
                      onChanged: (value) {
                        setState(() => _fatPercentage = value.round());
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        backgroundColor:
                            (_carbsPercentage +
                                    _proteinPercentage +
                                    _fatPercentage ==
                                100)
                            ? null
                            : Colors.grey,
                      ),
                      onPressed:
                          (_carbsPercentage +
                                  _proteinPercentage +
                                  _fatPercentage ==
                              100)
                          ? _saveGoals
                          : null,
                      child: const Text('Guardar Metas'),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'OBJETIVO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Objetivo de peso'),
            subtitle: Text(_getGoalText()),
            onTap: _showGoalDialog,
          ),
          ExpansionTile(
            initiallyExpanded: false,
            leading: const Icon(Icons.notifications_active),
            title: const Text('Recordatorios Diarios'),
            children: [
              CheckboxListTile(
                title: const Text('Tomar B12'),
                value: _b12Checked,
                onChanged: (val) {
                  setState(() => _b12Checked = val ?? false);
                  _saveReminders();
                },
              ),
              CheckboxListTile(
                title: const Text('Tomar Yodo'),
                value: _yodoChecked,
                onChanged: (value) {
                  setState(() => _yodoChecked = value ?? true);
                  _saveReminders();
                },
              ),
              CheckboxListTile(
                title: const Text('Semillas de lino'),
                value: _linoChecked,
                onChanged: (val) {
                  setState(() => _linoChecked = val ?? false);
                  _saveReminders();
                },
              ),
              CheckboxListTile(
                title: const Text('Remojar legumbres'),
                value: _legumbresChecked,
                onChanged: (val) {
                  setState(() => _legumbresChecked = val ?? false);
                  _saveReminders();
                },
              ),
            ],
          ),
          const Divider(),

          // AGREGAR SECCIÓN DE RECETAS antes de "Borrar Datos":
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Recetas'),
            subtitle: const Text('Gestionar comidas guardadas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showRecipesManager,
          ),

          const Divider(),
          const Divider(),
          const Divider(),

          // SECCIÓN DE SINCRONIZACIÓN (solo móvil)
          if (!kIsWeb)
            ExpansionTile(
              leading: Icon(
                _authService.isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                color: _authService.isSignedIn ? Colors.green : Colors.grey,
              ),
              title: const Text('Sincronización'),
              subtitle: Text(
                _authService.isSignedIn
                    ? 'Sincronizado con ${_authService.userEmail}'
                    : 'No sincronizado',
                style: TextStyle(
                  color: _authService.isSignedIn ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _authService.isSignedIn
                            ? 'Tus datos están respaldados en la nube y se sincronizan automáticamente.'
                            : 'Tus datos solo están en este dispositivo. '
                                  'Sincroniza con Google para acceder desde otros dispositivos.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      if (_isSyncing)
                        const Center(child: CircularProgressIndicator())
                      else if (_authService.isSignedIn)
                        Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _performSync,
                              icon: const Icon(Icons.sync),
                              label: const Text('Sincronizar ahora'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _handleDisconnect,
                              icon: const Icon(
                                Icons.cloud_off,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Desconectar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _handleSync,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Sincronizar con Google'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 45),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

          const Divider(),
          const Divider(),
          // Botón para borrar los datos
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Borrar Datos',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showDeleteConfirmationDialog(
              widget.searchController,
            ), // ✅ Callback correcto
          ),
          const Divider(),
          if (_secretMenuEnabled)
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Alimentos Personalizados'),
              subtitle: const Text('Importar alimentos desde JSON'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomFoodsImportScreen(),
                  ),
                );
              },
            ),

          if (_secretMenuEnabled)
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Umbral de sugerencias'),
              subtitle: Text('Actual: ${_suggestionThreshold.toInt()}%'),
              onTap: () {
                _showSuggestionThresholdDialog();
              },
            ),

          if (_secretMenuEnabled) const Divider(),

          // Mantener Import/Export solo para móvil
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.import_export),
              title: const Text('Importar / Exportar'),
              subtitle: const Text('Respaldar o restaurar datos'),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenImportExport();
              },
            ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.blue),
            title: const Text(
              'Información Nutricional',
              style: TextStyle(color: Colors.blue),
            ),
            onTap: () async {
              final Uri url = Uri.parse(
                'https://arielacopata.github.io/acofood/Info.html',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'v1.4.1',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
