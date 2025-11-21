// lib/screens/custom_foods_import_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/custom_foods_import_service.dart';
import '../services/food_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class CustomFoodsImportScreen extends StatefulWidget {
  const CustomFoodsImportScreen({super.key});

  @override
  State<CustomFoodsImportScreen> createState() =>
      _CustomFoodsImportScreenState();
}

class _CustomFoodsImportScreenState extends State<CustomFoodsImportScreen> {
  bool _importing = false;
  ImportResult? _lastResult;

  Future<void> _importFromFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return;

    setState(() {
      _importing = true;
      _lastResult = null;
    });

    String jsonContent;

    if (kIsWeb) {
      // En web, usar bytes
      final bytes = result.files.first.bytes;
      if (bytes == null) {
        throw Exception('No se pudo leer el archivo');
      }
      jsonContent = String.fromCharCodes(bytes);
    } else {
      // En móvil, usar path
      final file = File(result.files.first.path!);
      jsonContent = await file.readAsString();
    }

    final importResult = await CustomFoodsImportService.importFromJson(
      jsonContent,
    );

    setState(() {
      _lastResult = importResult;
      _importing = false;
    });

    if (importResult.isSuccess) {
      await FoodRepository().loadFoods(forceReload: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${importResult.successCount} alimentos importados exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }


print('❌ Antes de CATCH:');
  // 🚨 Si el flag está activo, mostrar el popup
  if (ImportNotifier.showPillinAlert && mounted) {
    ImportNotifier.showPillinAlert = false; // limpiar el flag

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text(
                '¡A pillín!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: const Text(
            'Ese alimento es muy malo, y más para el que va en el plato.\n\n'
            'No deberías agregar alimentos animales.\n\n '
            'AcoFood es una app vegana 🌱',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

} catch (e) {
  final errorMessage = e.toString();
 

  // ⚙️ Estado de error normal
  setState(() {
    _importing = false;
    _lastResult = ImportResult(
      totalProcessed: 0,
      successCount: 0,
      errors: ['Error: $errorMessage'],
    );
  });
}

}


  void _showExampleJson() {
    final example = CustomFoodsImportService.getExampleJson();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Formato JSON de Ejemplo'),
        content: SingleChildScrollView(
          child: SelectableText(
            example,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: example));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ejemplo copiado al portapapeles'),
                ),
              );
            },
            child: const Text('COPIAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alimentos Personalizados')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Importar Alimentos Personalizados',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Puedes importar tus propios alimentos desde un archivo JSON. '
              'Los alimentos deben estar en formato JSON con todos los nutrientes.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _importing ? null : _importFromFile,
              icon: _importing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                _importing ? 'Importando...' : 'Seleccionar Archivo JSON',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _showExampleJson,
              icon: const Icon(Icons.help_outline),
              label: const Text('Ver Formato de Ejemplo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            if (_lastResult != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              _buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _lastResult!;
    final isSuccess = result.successCount > 0;

    return Card(
      color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isSuccess ? 'Importación Exitosa' : 'Error en Importación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSuccess
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Total procesados: ${result.totalProcessed}'),
            Text(
              'Importados exitosamente: ${result.successCount}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            if (result.hasErrors) ...[
              const SizedBox(height: 12),
              const Text(
                'Errores:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              ...result.errors.map(
                (error) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '• $error',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
