import 'dart:async';

import '../services/bluetooth_service.dart';

class BluetoothController {
  final StreamController<String> _dataController = StreamController<String>.broadcast();
  StreamSubscription<String>? _subscription;

  Stream<String> get bluetoothDataStream => BluetoothService.dataStream;

  BluetoothController() {
    _subscription = BluetoothService.dataStream.listen((data) {
      _dataController.add(data);
    });
  }

  Stream<String> get dataStream => _dataController.stream;

  Future<void> refreshPairedDevices() async {
    await BluetoothService.getBondedDevices();
  }

  Future<void> connectToDevice([String? address]) async {
    await BluetoothService.connectToDevice(address);
  }

  Future<void> disconnect() async {
    await BluetoothService.disconnect();
  }

  Future<void> sendData(String data) async {
    await BluetoothService.sendData(data);
  }

  Future<void> sendPowerCommand(bool isOn) async {
    await BluetoothService.sendPowerCommand(isOn);
  }

  void dispose() {
    _subscription?.cancel();
    _dataController.close();
  }
}
