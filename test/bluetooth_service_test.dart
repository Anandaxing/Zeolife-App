import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zeolife_app/services/bluetooth_service.dart';

void main() {
  group('BluetoothService command encoding', () {
    test('returns ASCII 1 for power on and 0 for power off', () {
      expect(BluetoothService.commandForPower(true), '1');
      expect(BluetoothService.commandForPower(false), '0');
    });

    test('encodes command bytes as ASCII values', () {
      expect(BluetoothService.powerCommandBytes(true), Uint8List.fromList([49]));
      expect(BluetoothService.powerCommandBytes(false), Uint8List.fromList([48]));
    });
  });
}
