import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class BluetoothManager extends StatefulWidget {
  final void Function(double grams) onWeightChanged;
  final void Function(bool isConnected) onConnectionChanged;

  const BluetoothManager({
    super.key,
    required this.onWeightChanged,
    required this.onConnectionChanged,
  });

  @override
  State<BluetoothManager> createState() => _BluetoothManagerState();
}

class _BluetoothManagerState extends State<BluetoothManager> {
  BluetoothDevice? _connectedDevice;
  final List<ScanResult> _scanResults = [];
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

@override
void initState() {
  super.initState();
  _initializeBluetooth();
}

Future<void> _initializeBluetooth() async {
  // 1. Verificar si Bluetooth está soportado
  if (await FlutterBluePlus.isSupported == false) {
    debugPrint('Bluetooth no está soportado en este dispositivo');
    return;
  }

  // 2. Pedir permisos
  await _checkPermissions();

  // 3. Verificar si Bluetooth está encendido
  final adapterState = await FlutterBluePlus.adapterState.first;
  if (adapterState != BluetoothAdapterState.on) {
    debugPrint('Bluetooth está apagado, solicitando que se encienda');
    try {
      // En Android, esto abrirá el diálogo del sistema para encender Bluetooth
      await FlutterBluePlus.turnOn();
    } catch (e) {
      debugPrint('Error al intentar encender Bluetooth: $e');
      return;
    }
  }

  // 4. Esperar un poco para que el sistema procese los permisos
  await Future.delayed(const Duration(milliseconds: 500));

  // 5. Iniciar scan solo si mounted
  if (mounted) {
    _startScan();
  }
}

Future<void> _checkPermissions() async {
  // Pedir todos los permisos juntos en un solo request
  await [
    Permission.location,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
  ].request();
}

  void _startScan() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        final name = result.device.platformName.toLowerCase();
        if (name.contains('macroscale') && _connectedDevice == null) {
          FlutterBluePlus.stopScan();
          _connectToDevice(result.device);
          break;
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      setState(() => _connectedDevice = device);
      widget.onConnectionChanged(true);

      // ⭐ AGREGAR: Escuchar cambios en el estado de conexión
      _connectionStateSubscription = device.connectionState.listen((
        BluetoothConnectionState state,
      ) {
        debugPrint('Estado de conexión: $state');

        if (state == BluetoothConnectionState.disconnected) {
          // La balanza se desconectó (apagada o fuera de rango)
          debugPrint('Balanza desconectada automáticamente');
          _handleDisconnection();
        }
      });

      final services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.notify) {
            await char.setNotifyValue(true);
            char.onValueReceived.listen((value) {
              if (value.length >= 6) {
                int raw = (value[3] << 8) | value[4];
                double grams = raw / 10.0;

                // byte[5]: 2 = positivo, 3 = negativo
                if (value[5] == 3) {
                  grams = -grams;
                }

                widget.onWeightChanged(grams);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error al conectar: $e");
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    if (mounted) {
      setState(() {
        _connectedDevice = null;
      });
      widget.onConnectionChanged(false);

      // Cancelar suscripción al estado de conexión
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;
    }
  }

  Future<void> _manualDisconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      debugPrint("Error al desconectar manualmente: $e");
    }
    _handleDisconnection();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_connectedDevice == null) ...[
          ElevatedButton(onPressed: _startScan, child: const Text("Conectar")),
          ..._scanResults.map(
            (r) => ListTile(
              title: Text(
                r.device.platformName.isNotEmpty
                    ? r.device.platformName
                    : r.device.remoteId.toString(),
              ),
              subtitle: Text("RSSI: ${r.rssi}"),
              trailing: ElevatedButton(
                onPressed: () => _connectToDevice(r.device),
                child: const Text("Conectar"),
              ),
            ),
          ),
        ] else ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _connectedDevice!.platformName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _manualDisconnect,
                child: const Text("Desconectar"),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _connectionStateSubscription?.cancel();
    try {
      _connectedDevice?.disconnect();
    } catch (e) {
      debugPrint("Error al desconectar en dispose: $e");
    }
    super.dispose();
  }
}
