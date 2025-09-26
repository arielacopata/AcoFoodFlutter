import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothManager extends StatefulWidget {
  final void Function(double grams) onWeightChanged;
  final ValueChanged<bool>? onConnectionChanged;

  const BluetoothManager({
    super.key,
    required this.onWeightChanged,
    this.onConnectionChanged,
  });

  @override
  State<BluetoothManager> createState() => _BluetoothManagerState();
}

class _BluetoothManagerState extends State<BluetoothManager> {
  BluetoothDevice? _connectedDevice;
  List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final List<StreamSubscription<List<int>>> _valueSubscriptions = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  Future<void> _startScan() async {
    await _checkPermissions();
    setState(() {
      _scanResults = [];
      _isScanning = true;
    });

    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() => _scanResults = results);
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar la búsqueda: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();

      if (!mounted) return;

      setState(() {
        _connectedDevice = device;
        _scanResults = [];
        _isScanning = false;
      });

      widget.onConnectionChanged?.call(true);

      final services = await device.discoverServices();
      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.notify) {
            await char.setNotifyValue(true);
            final subscription = char.onValueReceived.listen((value) {
              if (value.length >= 5) {
                final raw = (value[3] << 8) | value[4];
                final grams = raw / 10.0;
                widget.onWeightChanged(grams);
              }
            });
            _valueSubscriptions.add(subscription);
          }
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo conectar: $error')),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    for (final subscription in _valueSubscriptions) {
      await subscription.cancel();
    }
    _valueSubscriptions.clear();

    try {
      await _connectedDevice?.disconnect();
    } catch (error) {
      debugPrint('Error al desconectar: $error');
    }

    if (!mounted) return;

    setState(() {
      _connectedDevice = null;
      _scanResults = [];
    });
    widget.onConnectionChanged?.call(false);
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    for (final subscription in _valueSubscriptions) {
      subscription.cancel();
    }
    _connectedDevice?.disconnect();
    widget.onConnectionChanged?.call(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_connectedDevice == null) ...[
          Row(
            children: [
              FilledButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: const Icon(Icons.bluetooth_searching),
                label: Text(_isScanning ? 'Buscando...' : 'Buscar balanza'),
              ),
              if (_isScanning) ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_scanResults.isEmpty && !_isScanning)
            Text(
              'Tocá "Buscar balanza" para descubrir dispositivos cercanos.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ..._scanResults.map(
            (result) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.scale_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                    result.device.name.isNotEmpty
                        ? result.device.name
                        : 'Balanza sin nombre',
                  ),
                  subtitle: Text(
                    '${result.device.remoteId} · RSSI: ${result.rssi}',
                  ),
                  trailing: FilledButton.tonalIcon(
                    icon: const Icon(Icons.link),
                    label: const Text('Conectar'),
                    onPressed: () => _connectToDevice(result.device),
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          Card(
            color: colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(
                Icons.check_circle,
                color: colorScheme.onPrimaryContainer,
              ),
              title: Text(
                _connectedDevice!.name.isNotEmpty
                    ? _connectedDevice!.name
                    : _connectedDevice!.remoteId.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Conexión activa',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _disconnect,
            icon: const Icon(Icons.link_off),
            label: const Text('Desconectar'),
          ),
        ],
      ],
    );
  }
