import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  static const int baudRate = 9600;
  static const String defaultHc05Address = '5A:81:D6:FA:ED:D2';

  static final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  static BluetoothConnection? _connection;
  static final StreamController<String> _dataController =
      StreamController<String>.broadcast();

  static Stream<String> get dataStream => _dataController.stream;
  static bool get isConnected => _connection!= null && _connection!.isConnected;

  static String commandForPower(bool isOn) => isOn? '1' : '0';

  static Future<void> _ensurePermissions() async {
    // Di Android 15, jangan minta bluetooth via permission_handler, biar system yang handle
    // Kita cuma minta lokasi aja
    final locStatus = await Permission.locationWhenInUse.request();
    if (locStatus.isPermanentlyDenied) {
      await openAppSettings();
      throw Exception('Aktifkan Izin Lokasi di Settings');
    }
    if (locStatus.isDenied) {
      throw Exception('Izin Lokasi wajib di-Allow');
    }
    // Bluetooth CONNECT akan otomatis diminta Android pas getBondedDevices dipanggil
  }
  
  static Future<List<BluetoothDevice>> getBondedDevices() async {
    await _ensurePermissions();
    return _bluetooth.getBondedDevices();
  }

  static Uint8List powerCommandBytes(bool isOn) =>
      Uint8List.fromList(utf8.encode(commandForPower(isOn)));

  static String normalizeAddress(String? rawAddress) {
    final sanitized = (rawAddress?? '').trim().replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toUpperCase();
    if (sanitized.isEmpty) return '';
    if (sanitized.length == 12) {
      final formatted = StringBuffer();
      for (var i = 0; i < sanitized.length; i++) {
        if (i > 0 && i % 2 == 0) formatted.write(':');
        formatted.write(sanitized[i]);
      }
      return formatted.toString();
    }
    return sanitized;
  }

  static String resolveTargetAddress(String? requestedAddress, List<BluetoothDevice> pairedDevices) {
    final normalizedRequest = normalizeAddress(requestedAddress);
    if (normalizedRequest.isNotEmpty) {
      final exactMatch = pairedDevices.where((device) => device.address.toUpperCase() == normalizedRequest);
      if (exactMatch.isNotEmpty) return exactMatch.first.address;
    }
    if (pairedDevices.isEmpty) return defaultHc05Address;
    final match = pairedDevices.firstWhere(
      (device) => (device.name?.toUpperCase().contains('HC-05')?? false) || (device.name?.toUpperCase().contains('HC-06')?? false),
      orElse: () => pairedDevices.first,
    );
    return match.address;
  }

  static Future<void> connectToDevice([String? address]) async {
    await _ensurePermissions();

    bool? isEnabled = await _bluetooth.isEnabled;
    if (isEnabled == null ||!isEnabled) {
      await _bluetooth.requestEnable();
    }

    final List<BluetoothDevice> paired = await _bluetooth.getBondedDevices();
    final targetAddress = resolveTargetAddress(address, paired);
    if (targetAddress.isEmpty) {
      throw StateError('No paired HC-05 found. Pair dulu di Settings Bluetooth HP.');
    }

    await _cleanupConnection();
    try {
      _connection = await BluetoothConnection.toAddress(targetAddress);
      _connection!.input!.listen((Uint8List data) {
        _dataController.add(ascii.decode(data));
      }).onDone(() {
        _connection = null;
      });
      return;
    } catch (e) {
      await _cleanupConnection();
      throw Exception('Connection failed: $e');
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
  }

  static Future<void> disconnect() async {
    await _cleanupConnection();
  }

  static void dispose() {
    _cleanupConnection();
    _dataController.close();
  }
}