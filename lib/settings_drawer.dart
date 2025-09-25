import 'package:flutter/material.dart';
import 'models/user_profile.dart';

class SettingsDrawer extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onUpdateProfile;

  const SettingsDrawer({
    super.key,
    required this.profile,
    required this.onUpdateProfile,
  });

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  int _carbs = 50;
  int _protein = 20;
  int _fat = 30;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _weightController = TextEditingController(
      text: widget.profile.weight.toString(),
    );
    _heightController = TextEditingController(
      text: widget.profile.height.toString(),
    );
    _carbs = widget.profile.carbs;
    _protein = widget.profile.protein;
    _fat = widget.profile.fat;
  }

  void _saveProfile() {
    final updated = UserProfile(
      name: _nameController.text,
      weight: double.tryParse(_weightController.text) ?? 0,
      height: double.tryParse(_heightController.text) ?? 0,
      carbs: _carbs,
      protein: _protein,
      fat: _fat,
    );
    widget.onUpdateProfile(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final total = _carbs + _protein + _fat;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Text(
              "Configuración",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            title: const Text("Nombre"),
            subtitle: TextField(controller: _nameController),
          ),
          ListTile(
            title: const Text("Peso (kg)"),
            subtitle: TextField(controller: _weightController),
          ),
          ListTile(
            title: const Text("Altura (cm)"),
            subtitle: TextField(controller: _heightController),
          ),
          ExpansionTile(
            title: const Text("Metas de Macros"),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total: $total%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: total == 100 ? Colors.green : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSlider("Carbohidratos", _carbs, (v) {
                      setState(() => _carbs = v);
                    }),
                    _buildSlider("Proteínas", _protein, (v) {
                      setState(() => _protein = v);
                    }),
                    _buildSlider("Grasas", _fat, (v) {
                      setState(() => _fat = v);
                    }),
                    if (total != 100)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "⚠️ Asegúrese antes de proceder que la suma de macros es 100%",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          ListTile(
            title: Text(
              "Guardar Perfil y Metas",
              style: TextStyle(
                color: total == 100 ? Colors.black : Colors.grey,
              ),
            ),
            onTap: total == 100 ? _saveProfile : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label ($value%)"),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: "$value%",
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
