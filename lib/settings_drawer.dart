import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/calorie_calculator.dart';
// import '../services/google_fit_service.dart';

class SettingsDrawer extends StatefulWidget {
  final UserProfile? profile;
  final Function(UserProfile)? onProfileUpdated; // 👈 NUEVO
  final VoidCallback? onHistoryChanged; // 👈 NUEVO
  final Function(String)? onSortOrderChanged; // 👈 Agregar esto
  final Function()? onRemindersChanged; // Agregar esto

  const SettingsDrawer({
    super.key,
    this.profile,
    this.onProfileUpdated, // 👈 NUEVO
    this.onHistoryChanged, // 👈 NUEVO
    this.onSortOrderChanged, // 👈 Agregar esto
    this.onRemindersChanged, // Agregar esto
  });

  @override
  // ignore: library_private_types_in_public_api
  _SettingsDrawerState createState() => _SettingsDrawerState();
}

// ignore: library_private_types_in_public_api
class _SettingsDrawerState extends State<SettingsDrawer> {
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
  String _sortOrder = 'alfabetico'; // 'alfabetico' o 'mas_usados'
  bool _googleFitEnabled = false;

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
      _b12Checked =
          prefs.getBool('b12_enabled') ?? true; // Por defecto activado
      _linoChecked = prefs.getBool('lino_enabled') ?? true;
      _legumbresChecked = prefs.getBool('legumbres_enabled') ?? true;
    });
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('b12_enabled', _b12Checked);
    await prefs.setBool('lino_enabled', _linoChecked);
    await prefs.setBool('legumbres_enabled', _legumbresChecked);

    // Notificar al home_page que se actualizaron los recordatorios
    if (widget.onRemindersChanged != null) {
      widget.onRemindersChanged!();
    }
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

    await DatabaseService.instance.saveUserProfile(profile);

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

    await DatabaseService.instance.saveUserProfile(updatedProfile);

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
    final maintenanceCalories = CalorieCalculator.calculateRecommendedCalories(
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
    
    await DatabaseService.instance.saveUserProfile(updatedProfile);
    if (widget.onProfileUpdated != null) {
      widget.onProfileUpdated!(updatedProfile);
    }
    
    if (widget.onHistoryChanged != null) {  // ← Agregar esto
    widget.onHistoryChanged!();           // ← y esto
    }
    setState(() {});
  }
}

  // Diálogo de confirmación para borrar datos
  // Diálogo de confirmación para borrar datos
  void _showDeleteConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Borrado'),
          content: const Text(
            '¿Estás seguro de que quieres borrar todo el historial de hoy? Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Borrar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    // Si el usuario confirmó, borramos el historial
    if (confirmed == true) {
      await DatabaseService.instance.clearTodayHistory();

      if (widget.onHistoryChanged != null) {
        widget.onHistoryChanged!();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Historial de hoy borrado'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(); // Cierra el drawer
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
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sort, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _sortOrder,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'alfabetico',
                              child: Text(
                                'Orden: Alfabético',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'mas_usados',
                              child: Text(
                                'Orden: Más usados',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value != null) {
                              print('Cambió a: $value'); // 👈 Agregar esto
                              setState(() => _sortOrder = value);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString('sort_order', value);
                              if (widget.onSortOrderChanged != null) {
                                print('Llamando callback'); // 👈 Y esto
                                widget.onSortOrderChanged!(value);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Objetivo de peso'),
                  subtitle: Text(_getGoalText()),
                  onTap: _showGoalDialog,
                ),
          ExpansionTile(
            initiallyExpanded: true,
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
          // Botón para borrar los datos
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Borrar Datos',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _showDeleteConfirmationDialog,
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
        ],
      ),
    );
  }
}
