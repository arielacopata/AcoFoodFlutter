import 'package:flutter/material.dart';
import '../models/food.dart';

class FoodAmountSheet extends StatefulWidget {
  final Food food;
  final bool isScaleConnected;
  final Stream<double>? weightStream;

  const FoodAmountSheet({
    super.key,
    required this.food,
    required this.isScaleConnected,
    this.weightStream,
  });

  @override
  State<FoodAmountSheet> createState() => _FoodAmountSheetState();
}

class _FoodAmountSheetState extends State<FoodAmountSheet> {
  final List<int> _presets = const [10, 20, 50, 100, 200];
  int? _selectedPreset;
  final TextEditingController _customCtrl = TextEditingController();
  String? _error;

  double? _amountFromInputs() {
    if (_selectedPreset != null) return _selectedPreset!.toDouble();
    final txt = _customCtrl.text.trim().replaceAll(",", ".");
    if (txt.isEmpty) return null;
    final v = double.tryParse(txt);
    return (v != null && v > 0) ? v : null;
  }

  void _trySubmitCustom() {
    final v = _amountFromInputs();
    setState(
      () => _error = (v == null) ? "Ingrese una cantidad válida (> 0)" : null,
    );
    if (v != null) Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets;
    //    final weightText = "${widget.currentWeight.toStringAsFixed(1)} g";

    return Padding(
      padding: EdgeInsets.only(bottom: padding.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      "${widget.food.emoji}  ${widget.food.fullName ?? widget.food.name}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Presets
                const Text(
                  "Cantidad rápida",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center, // 👈 importante
                    children: _presets.map((p) {
                      final selected = _selectedPreset == p;
                      return ChoiceChip(
                        label: Text("$p g"),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            Navigator.pop(context, p.toDouble());
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Custom
                const Text(
                  "Cantidad personalizada",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Ej: 37.5",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) {
                    setState(() {
                      _selectedPreset = null;
                      _error = null;
                    });
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),

                // Balanza (solo si hay conexión)
                if (widget.isScaleConnected && widget.weightStream != null) ...[
                  const Divider(),
                  Center(
                    child: StreamBuilder<double>(
                      stream: widget.weightStream,
                      builder: (context, snapshot) {
                        final grams = snapshot.data ?? 0.0;
                        return Column(
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Text(
                                "${grams.toStringAsFixed(1)} g",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (widget
                                .isScaleConnected) // 👈 acá sí va el if directo
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.scale),
                                  label: Text(
                                    "Usar peso (${grams.toStringAsFixed(1)} g)",
                                  ),
                                  onPressed: (grams > 0)
                                      ? () => Navigator.pop(context, grams)
                                      : null,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    child: const Text("Usar cantidad"),
                    onPressed: () {
                      final v = _amountFromInputs();
                      setState(
                        () => _error = (v == null)
                            ? "Seleccione un preset o ingrese una cantidad válida"
                            : null,
                      );
                      if (v != null) Navigator.pop(context, v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
