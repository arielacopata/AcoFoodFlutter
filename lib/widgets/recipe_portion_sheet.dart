// lib/widgets/recipe_portion_sheet.dart

import 'package:flutter/material.dart';
import '../models/recipe.dart';

class RecipePortionSheet extends StatefulWidget {
  final Recipe recipe;
  final List<RecipeIngredient> ingredients;

  const RecipePortionSheet({
    super.key,
    required this.recipe,
    required this.ingredients,
  });

  @override
  State<RecipePortionSheet> createState() => _RecipePortionSheetState();
}

class _RecipePortionSheetState extends State<RecipePortionSheet> {
  final List<double> _presetPortions = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0];
  double? _selectedPortion;
  final TextEditingController _customController = TextEditingController();
  String? _error;

  double? _getPortionValue() {
    if (_selectedPortion != null) return _selectedPortion;

    final text = _customController.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;

    final value = double.tryParse(text);
    return (value != null && value > 0) ? value : null;
  }

  void _trySubmit() {
    final portion = _getPortionValue();
    setState(() {
      _error = (portion == null) ? "Ingrese una cantidad válida (> 0)" : null;
    });

    if (portion != null) {
      Navigator.pop(context, portion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: padding.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      "${widget.recipe.emoji ?? '🍽️'}  ${widget.recipe.name}",
                      style: const TextStyle(
                        fontSize: 20,
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

                // Info de ingredientes
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1 porción contiene:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...widget.ingredients.map(
                        (ing) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${ing.grams.toStringAsFixed(0)}g de ${ing.food.name}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Título de porciones
                const Text(
                  '¿Cuántas porciones comiste?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 12),

                // Botones de porciones predefinidas
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presetPortions.map((portion) {
                    final isSelected = _selectedPortion == portion;
                    return ChoiceChip(
                      label: Text(
                        portion == 1.0 ? '1' : portion.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPortion = selected ? portion : null;
                          _customController.clear();
                          _error = null;
                        });
                      },
                      selectedColor: Colors.blue,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Campo custom
                const Text(
                  'O ingrese cantidad personalizada:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _customController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ej: 1.5',
                    suffixText: 'porciones',
                    errorText: _error,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedPortion = null;
                      _error = null;
                    });
                  },
                  onSubmitted: (_) => _trySubmit(),
                ),

                const SizedBox(height: 20),

                // Preview de lo que se va a registrar
                if (_getPortionValue() != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Se registrará:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...widget.ingredients.map((ing) {
                          final adjustedGrams = ing.grams * _getPortionValue()!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• ${adjustedGrams.toStringAsFixed(1)}g de ${ing.food.name}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botón de confirmar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _trySubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Registrar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }
}
