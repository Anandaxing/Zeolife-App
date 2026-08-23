// lib/bluetooth_service.dart
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'dart:async';

class BluetoothService {
  static BluetoothConnection? _connection;
  static final StreamController<String> _dataController =
      StreamController<String>.broadcast();

  static Stream<String> get dataStream => _dataController.stream;
  static bool get isConnected => _connection != null && _connection!.isConnected;

  static Future<void> connectToDevice(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      _connection!.input.listen(
        (bytes) {
          String received = String.fromCharCodes(bytes);
          _dataController.add(received);
        },
        onDone: () => _connection = null,
      );
    } catch (e) {
      _connection = null;
      rethrow;
    }
  }

  static void sendData(String data) => _connection?.output.add(data.codeUnits);

  static void disconnect() {
    _connection?.close();
    _connection = null;
  }

  static void dispose() {
    disconnect();
    _dataController.close();
  }
}