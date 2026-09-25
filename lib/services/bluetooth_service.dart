import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  static BtcConnection? _connection;
  static final StreamController<String> _dataController =
      StreamController<String>.broadcast();

  static Stream<String> get dataStream => _dataController.stream;
  static bool get isConnected => _connection != null && _connection!.isConnected;

  static Future<void> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();

    final blocked = statuses.entries.where((entry) {
      final status = entry.value;
      return status.isDenied || status.isPermanentlyDenied || status.isRestricted;
    }).isNotEmpty;

    if (blocked) {
      throw StateError(
        'Bluetooth permissions are required before connecting to the HC-05 module.',
      );
    }
  }

  static String commandForPower(bool isOn) => isOn ? '1' : '0';

  static Uint8List powerCommandBytes(bool isOn) =>
      Uint8List.fromList(commandForPower(isOn).codeUnits);

  static Future<void> connectToDevice(String address) async {
    final sanitizedAddress = address.trim();
    if (sanitizedAddress.isEmpty) {
      throw const FormatException('Bluetooth MAC address is required.');
    }

    try {
      await requestPermissions();
      final bluetooth = FlutterClassicBluetooth();
      _connection = await bluetooth.connect(address: sanitizedAddress);
      _connection?.input.listen(
        (bytes) {
          final received = String.fromCharCodes(bytes);
          _dataController.add(received);
        },
        onDone: () => _connection = null,
      );
    } catch (e) {
      _connection = null;
      rethrow;
    }
  }

  static void sendData(String data) {
    _connection?.output.add(Uint8List.fromList(data.codeUnits));
  }

  static void sendPowerCommand(bool isOn) {
    if (!isConnected) {
      return;
    }
    _connection?.output.add(powerCommandBytes(isOn));
  }

  static void disconnect() {
    _connection?.close();
    _connection = null;
  }

  static void dispose() {
    disconnect();
    _dataController.close();
  }
}