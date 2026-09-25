import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

class BluetoothService {
  static const String defaultHc05Address = '5A:81:D6:FA:ED:D2';
  static const int baudRate = 38400;

  /// Maximum number of connection attempts before giving up.
  static const int _maxRetries = 3;

  static final FlutterClassicBluetooth _bluetooth = FlutterClassicBluetooth();
  static BtcConnection? _connection;
  static final StreamController<String> _dataController =
      StreamController<String>.broadcast();

  static Stream<String> get dataStream => _dataController.stream;
  static bool get isConnected => _connection != null && _connection!.isConnected;

  static String commandForPower(bool isOn) => isOn ? '1' : '0';

  static Uint8List powerCommandBytes(bool isOn) =>
      Uint8List.fromList(commandForPower(isOn).codeUnits);

  static Future<void> connectToDevice([String? address]) async {
    // ── 1. Permissions ──────────────────────────────────────────────
    final permStatus = await _bluetooth.checkPermissions(
      permissions: {BtcPermission.connect, BtcPermission.scan},
    );
    if (permStatus == BtcPermissionStatus.denied) {
      await _bluetooth.requestPermissions(
        permissions: {BtcPermission.connect, BtcPermission.scan},
      );
    } else if (permStatus == BtcPermissionStatus.permanentlyDenied) {
      await _bluetooth.openAppSettings();
      throw StateError('Bluetooth permission permanently denied. Please grant it in app settings.');
    }

    // ── 2. Adapter state ────────────────────────────────────────────
    final enabled = await _bluetooth.isEnabled();
    if (!enabled) {
      final caps = await _bluetooth.getPlatformCapabilities();
      if (caps.canEnableBluetooth) {
        await _bluetooth.enableBluetooth();
      } else {
        throw StateError('Bluetooth is off. Please enable it in system settings.');
      }
    }

    // ── 3. Resolve MAC address ──────────────────────────────────────
    String targetAddress = (address ?? defaultHc05Address).trim();

    try {
      final paired = await _bluetooth.getPairedDevices();
      debugPrint('Paired devices: ${paired.length}');
      for (final d in paired) {
        debugPrint('  ${d.displayName} - ${d.address} [${d.bondState.name}]');
      }

      // Try exact MAC match first
      final exactMatch = paired.where(
        (d) => d.address.toUpperCase() == targetAddress.toUpperCase(),
      );

      if (exactMatch.isNotEmpty) {
        targetAddress = exactMatch.first.address;
        debugPrint('Found exact MAC match: $targetAddress');
      } else {
        // Fall back to name-based match
        final nameMatch = paired.where(
          (d) => d.displayName.toUpperCase().contains('HC-05') ||
                 d.displayName.toUpperCase().contains('HC-06'),
        );
        if (nameMatch.isNotEmpty) {
          targetAddress = nameMatch.first.address;
          debugPrint('Found HC-05 by name: ${nameMatch.first.displayName} at $targetAddress');
        } else {
          debugPrint('No HC-05 found in paired devices, using address: $targetAddress');
        }
      }
    } catch (e) {
      debugPrint('Could not list paired devices: $e');
    }

    if (targetAddress.isEmpty || targetAddress == '00:00:00:00:00:00') {
      throw const FormatException(
        'No valid Bluetooth address. Please pair HC-05 in system Bluetooth settings first.',
      );
    }

    // ── 4. Connect with retry ───────────────────────────────────────
    // HC-05 modules are notorious for failing the first RFCOMM attempt on
    // Android.  The native BluetoothSocket.connect() fails with "read ret: -1"
    // when the SDP cache is stale or the first socket creation races with a
    // cancelDiscovery call.  Retrying (with a short delay and alternating
    // secure/insecure) almost always succeeds.

    // Make sure any previous stale connection is torn down first.
    await _cleanupConnection();

    Object? lastError;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      // Alternate: first try insecure (works for most HC-05 clones),
      // then secure, then insecure again.
      final secure = attempt.isEven;
      debugPrint(
        'Connection attempt $attempt/$_maxRetries to $targetAddress '
        '(secure=$secure) ...',
      );

      try {
        _connection = await _bluetooth.connect(
          address: targetAddress,
          secure: secure,
          timeout: const Duration(seconds: 15),
        );
        debugPrint('Connected on attempt $attempt! id=${_connection!.id}');

        // ── 5. Listen for incoming data ─────────────────────────────
        _connection!.input.lines().listen(
          (line) {
            debugPrint('BT RX: $line');
            _dataController.add(line);
          },
          onDone: () {
            debugPrint('BT connection closed by remote');
            _connection = null;
          },
          onError: (e) {
            debugPrint('BT input error: $e');
          },
        );

        return; // ← success, stop retrying
      } catch (e) {
        lastError = e;
        debugPrint('Attempt $attempt failed: $e');

        // Clean up the failed socket before retrying
        await _cleanupConnection();

        if (attempt < _maxRetries) {
          // Wait a moment before retrying — gives the BT stack time to
          // release the socket.
          await Future<void>.delayed(const Duration(milliseconds: 800));
        }
      }
    }

    // All attempts exhausted
    debugPrint('All $_maxRetries connection attempts failed.');
    throw lastError!;
  }

  /// Silently close any existing connection.
  static Future<void> _cleanupConnection() async {
    try {
      await _connection?.close();
    } catch (_) {
      // Ignore errors during cleanup
    }
    _connection = null;
  }

  static Future<void> sendData(String data) async {
    if (_connection != null && _connection!.isConnected) {
      await _connection!.output.writeString(data);
    }
  }

  static Future<void> sendPowerCommand(bool isOn) async {
    if (!isConnected) return;
    await _connection!.output.writeString(commandForPower(isOn));
    debugPrint('BT TX: ${commandForPower(isOn)}');
  }

  static Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  static void dispose() {
    _connection?.close();
    _connection = null;
    _dataController.close();
  }
}