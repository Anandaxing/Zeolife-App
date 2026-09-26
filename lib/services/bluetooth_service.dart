import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  static const int baudRate = 9600;
  static const String defaultHc05Address = '5A:81:D6:FA:ED:D2';
  static const List<String> hc05FallbackAddresses = [
    defaultHc05Address,
    '00:15:FF:00:00:00',
    '98:D3:31:F5:5D:9A',
    '00:18:E4:00:00:00',
  ];

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

    // 2. Resolve MAC Address
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

    try {
      List<BluetoothDevice> paired = await _bluetooth.getBondedDevices();
      debugPrint('Paired devices: ${paired.length}');

      for (final d in paired) {
        debugPrint('  ${d.name} - ${d.address} [${d.isBonded}]');
      }

      if (paired.isEmpty) {
        if (targetAddress == null || targetAddress.isEmpty) {
          targetAddress = defaultHc05Address;
        }
      } else if (targetAddress != null && targetAddress.isNotEmpty) {
        final exactMatch = paired.where(
          (d) => d.address.toUpperCase() == targetAddress!.toUpperCase(),
        );
        if (exactMatch.isNotEmpty) {
          targetAddress = exactMatch.first.address;
        } else {
          final nameMatch = paired.where(
            (d) => (d.name?.toUpperCase().contains('HC-05') ?? false) ||
                   (d.name?.toUpperCase().contains('HC-06') ?? false) ||
                   (d.name?.toUpperCase().contains('BT') ?? false),
          );

          if (nameMatch.isNotEmpty) {
            targetAddress = nameMatch.first.address;
            debugPrint('Found device by name: ${nameMatch.first.name} at $targetAddress');
          } else {
            targetAddress = paired.first.address;
            debugPrint('No matching name. Using first paired device: ${paired.first.name} at $targetAddress');
          }
        }
      } else {
        final nameMatch = paired.where(
          (d) => (d.name?.toUpperCase().contains('HC-05') ?? false) ||
                 (d.name?.toUpperCase().contains('HC-06') ?? false) ||
                 (d.name?.toUpperCase().contains('BT') ?? false),
        );

        if (nameMatch.isNotEmpty) {
          targetAddress = nameMatch.first.address;
          debugPrint('Found device by name: ${nameMatch.first.name} at $targetAddress');
        } else {
          targetAddress = paired.first.address;
          debugPrint('No matching name. Using first paired device: ${paired.first.name} at $targetAddress');
        }
      }
    } catch (e) {
      debugPrint('Could not list paired devices: $e');
      if (targetAddress == null || targetAddress.isEmpty) {
        targetAddress = defaultHc05Address;
      }
    }

    if (targetAddress == null || targetAddress.isEmpty) {
      throw StateError(
        'No paired Bluetooth devices were found. Pair your HC-05 module or provide a valid MAC address.',
      );
    }

    // 3. Connect (flutter_bluetooth_serial automatically uses Reflection fallback!)
    final candidateAddresses = <String>{
      if (targetAddress != null && targetAddress.isNotEmpty) targetAddress,
      ...hc05FallbackAddresses,
    }.toList();

    Object? lastError;
    for (final candidate in candidateAddresses) {
      debugPrint('Connecting to $candidate using flutter_bluetooth_serial...');
      await _cleanupConnection();

      try {
        _connection = await BluetoothConnection.toAddress(candidate);
        debugPrint('Connected successfully to $candidate');

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
        lastError = e;
        debugPrint('Connection failed for $candidate: $e');
        await _cleanupConnection();
      }
    }

    throw Exception(
      'Connection failed: $lastError. Pair your HC-05 in Android Settings or pass the exact MAC address.',
    );
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