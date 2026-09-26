import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeolife_app/models/zeo_machine_state.dart';
import 'package:zeolife_app/services/bluetooth_service.dart';

void main() {
  group('BluetoothService command encoding', () {
    test('returns ASCII 1 for power on and 0 for power off', () {
      expect(BluetoothService.commandForPower(true), '1');
      expect(BluetoothService.commandForPower(false), '0');
    });

    test('normalizes a bare MAC address into the expected colon-separated format', () {
      expect(
        BluetoothService.normalizeAddress('5A81D6FAEDD2'),
        '5A:81:D6:FA:ED:D2',
      );
    });

    test('uses the default HC-05 address when no paired device is available', () {
      final resolved = BluetoothService.resolveTargetAddress(
        null,
        const <BluetoothDevice>[],
      );

      expect(resolved, BluetoothService.defaultHc05Address);
    });

    test('provides default HC-05 MAC address', () {
      expect(BluetoothService.defaultHc05Address, '5A:81:D6:FA:ED:D2');
    });
  });

  group('ZeoMachineState default values', () {
    test('default state for power button is inactive (false)', () {
      const state = ZeoMachineState();
      expect(state.isPowerOn, isFalse);
      expect(state.isConnected, isFalse);
    });
  });
}
