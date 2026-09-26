import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  static const int baudRate = 9600;
  static const String defaultHc05Address = '5A:81:D6:FA:ED:D2';

  static final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  static BluetoothConnection? _connection;
  static final StreamController<String> _dataController =
      StreamController<String>.broadcast();

  static Stream<String> get dataStream => _dataController.stream;
  static bool get isConnected => _connection != null && _connection!.isConnected;

  static String commandForPower(bool isOn) => isOn ? '1' : '0';

  static Future<List<BluetoothDevice>> getBondedDevices() async {
    return _bluetooth.getBondedDevices();
  }

  static Uint8List powerCommandBytes(bool isOn) =>
      Uint8List.fromList(utf8.encode(commandForPower(isOn)));

  static Future<void> connectToDevice([String? address]) async {
    // 1. Check if Bluetooth is enabled
    bool? isEnabled = await _bluetooth.isEnabled;
    if (isEnabled == null || !isEnabled) {
      await _bluetooth.requestEnable();
    }

    // 2. Resolve the exact paired device. This matches the working terminal app behavior:
    //    connect only to the exact device that Android knows about, not a guessed fallback.
    String? targetAddress = address?.trim();
    if (targetAddress != null && targetAddress.isNotEmpty) {
      targetAddress = targetAddress.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toUpperCase();
      if (targetAddress.length == 12) {
        final formatted = StringBuffer();
        for (var i = 0; i < targetAddress.length; i++) {
          if (i > 0 && i % 2 == 0) {
            formatted.write(':');
          }
          formatted.write(targetAddress[i]);
        }
        targetAddress = formatted.toString();
      }
    }

    final List<BluetoothDevice> paired = await _bluetooth.getBondedDevices();
    debugPrint('Paired devices: ${paired.length}');
    for (final device in paired) {
      debugPrint('  ${device.name} - ${device.address} [${device.isBonded}]');
    }

    if (targetAddress == null || targetAddress.isEmpty) {
      final match = paired.firstWhere(
        (device) =>
            (device.name?.toUpperCase().contains('HC-05') ?? false) ||
            (device.name?.toUpperCase().contains('HC-06') ?? false) ||
            (device.name?.toUpperCase().contains('BT') ?? false),
        orElse: () => paired.isNotEmpty ? paired.first : BluetoothDevice(
            name: 'UNKNOWN',
            address: defaultHc05Address,
            type: BluetoothDeviceType.classic,
            isConnected: false,
            bondState: BluetoothBondState.bonded,
          ),
      );
      targetAddress = match.address;
      debugPrint('Using paired device by name: ${match.name} at $targetAddress');
    } else {
      final exactMatch = paired.where(
        (device) => device.address.toUpperCase() == targetAddress!.toUpperCase(),
      );
      if (exactMatch.isNotEmpty) {
        targetAddress = exactMatch.first.address;
        debugPrint('Matched exact paired device: ${exactMatch.first.name} at $targetAddress');
      }
    }

    if (targetAddress == null || targetAddress.isEmpty) {
      throw StateError(
        'No paired HC-05 device was found. Pair the module in Android Bluetooth settings and retry.',
      );
    }

    // 3. Connect only to the exact device address. Do not try a sequence of guessed MACs.
    debugPrint('Connecting to $targetAddress using flutter_bluetooth_serial...');
    await _cleanupConnection();

    try {
      _connection = await BluetoothConnection.toAddress(targetAddress);
      debugPrint('Connected successfully to $targetAddress');

      _connection!.input!.listen((Uint8List data) {
        final stringData = ascii.decode(data);
        debugPrint('BT RX: $stringData');
        _dataController.add(stringData);
      }).onDone(() {
        debugPrint('Disconnected by remote');
        _connection = null;
      });
      return;
    } catch (e) {
      debugPrint('Connection failed for $targetAddress: $e');
      await _cleanupConnection();
      throw Exception(
        'Connection failed: $e. The HC-05 is not accepting the serial RFCOMM socket from this app.',
      );
    }
  }

  static Future<void> _cleanupConnection() async {
    try {
      await _connection?.close();
      await _connection?.finish();
    } catch (_) {}
    _connection = null;
  }

  static Future<void> sendData(String data) async {
    if (isConnected) {
      _connection!.output.add(Uint8List.fromList(utf8.encode(data)));
      await _connection!.output.allSent;
    }
  }

  static Future<void> sendPowerCommand(bool isOn) async {
    if (!isConnected) return;
    final cmd = commandForPower(isOn);
    _connection!.output.add(Uint8List.fromList(utf8.encode(cmd)));
    await _connection!.output.allSent;
    debugPrint('BT TX: $cmd');
  }

  static Future<void> disconnect() async {
    await _cleanupConnection();
  }

  static void dispose() {
    _cleanupConnection();
    _dataController.close();
  }
}