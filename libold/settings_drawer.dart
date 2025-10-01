import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import 'package:url_launcher/url_launcher.dart';


class SettingsDrawer extends StatefulWidget {
  final UserProfile? profile;
  final Function(UserProfile)? onProfileUpdated; // 👈 NUEVO
  final VoidCallback? onHistoryChanged; // 👈 NUEVO

  const SettingsDrawer({
    super.key,
    this.profile,
    this.onProfileUpdated, // 👈 NUEVO
    this.onHistoryChanged, // 👈 NUEVO
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
      _carbsPercentage = widget.profile!.carbs ?? 70;
      _proteinPercentage = widget.profile!.protein ?? 20;
      _fatPercentage = widget.profile!.fat ?? 10;

      // Lógica para el dropdown dependiente
      if (_selectedLifestyle != null) {
        _currentExerciseOptions = _exerciseLevels[_selectedLifestyle!] ?? [];
        _selectedExerciseLevel = widget.profile!.exerciseLevel;
      }
    }
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
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Configuración',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          // Usamos ExpansionTile para replicar el <details> de HTML
          ExpansionTile(
            title: const Text('Perfil de Usuario'),
            initiallyExpanded: true,
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
                      value: _selectedGender,
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
                      value: _selectedLifestyle,
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
                        value: _selectedExerciseLevel,
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
            leading: const Icon(Icons.info_outline),
            title: const Text('Información'),
            onTap: () async {
              final url = Uri.parse("https://arielacopata.github.io/acofood/balance.v2.1.html");
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                throw "No se pudo abrir $url";
              }
            },
          ), 
        ],
      ),
    );
  }
}
