import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
    await device.connect(
      timeout: const Duration(seconds: 10),
      autoConnect: false,
    );

    setState(() => _connectedDevice = device);
    widget.onConnectionChanged(true); // Notificar conexión

    final services = await device.discoverServices();
    for (var service in services) {
      for (var char in service.characteristics) {
        if (char.properties.notify) {
          await char.setNotifyValue(true);
          char.onValueReceived.listen((value) {
            if (value.length >= 5) {
              int raw = (value[3] << 8) | value[4];
              double grams = raw / 10.0;
              widget.onWeightChanged(grams);
            }
          });
        }
      }
    }
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
                r.device.name.isNotEmpty
                    ? r.device.name
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
                onPressed: () async {
                  await _connectedDevice!.disconnect();
                  setState(() => _connectedDevice = null);
                  widget.onConnectionChanged(false); // Notificar desconexión
                },
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
    try {
      _connectedDevice?.disconnect();
    } catch (e) {
      debugPrint("Error al desconectar: $e");
    }
    super.dispose();
  }
}
