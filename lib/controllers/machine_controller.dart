import 'dart:async';
import '../models/zeo_machine_state.dart';
import 'bluetooth_controller.dart';

abstract class MachineController {
  Stream<ZeoMachineState> get stateStream;
  ZeoMachineState get currentState;

  Future<void> toggleMainPower();
  Future<void> connectToDevice([String? macAddress]);
  void dispose();
}

class ZeoMachineController implements MachineController {
  ZeoMachineState _state = const ZeoMachineState();
  final StreamController<ZeoMachineState> _stateController = StreamController<ZeoMachineState>.broadcast();
  final BluetoothController _bluetoothController = BluetoothController();
  StreamSubscription<String>? _bluetoothSubscription;

  ZeoMachineController() {
    _bluetoothSubscription = _bluetoothController.dataStream.listen(_onTelemetryReceived);
  }

  @override
  Stream<ZeoMachineState> get stateStream => _stateController.stream;

  @override
  ZeoMachineState get currentState => _state;

  void _updateState(ZeoMachineState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  void _onTelemetryReceived(String data) {
    if (data.startsWith('TEMP:')) {
      final double? temp = double.tryParse(data.substring(5).trim());
      if (temp != null) {
        _updateState(_state.copyWith(
          primaryHeater: _state.primaryHeater.copyWith(temperatureCelsius: temp),
        ));
      }
    } else if (data.startsWith('FAN:')) {
      final parts = data.split(':');
      if (parts.length == 4) {
        final int? index = int.tryParse(parts[1]);
        if (index != null && index >= 1 && index <= 4) {
          final bool isOperational = parts[2] == 'ON';
          final int rpm = int.tryParse(parts[3]) ?? 0;
          
          final updatedFans = List<FanModule>.from(_state.coolingFans);
          updatedFans[index - 1] = FanModule(
            id: 'FAN_$index',
            isOperational: isOperational,
            rpm: rpm,
          );
          _updateState(_state.copyWith(coolingFans: updatedFans));
        }
      }
    } else if (data.startsWith('PROCESS:')) {
      _updateState(_state.copyWith(currentProcess: data.substring(8).trim()));
    } else if (data.startsWith('NEXT:')) {
      _updateState(_state.copyWith(nextProcess: data.substring(5).trim()));
    } else if (data.startsWith('CYCLE:')) {
      _updateState(_state.copyWith(nextCycleIn: data.substring(6).trim()));
    }
  }

  @override
  Future<void> toggleMainPower() async {
    final nextState = !_state.isPowerOn;
    _updateState(_state.copyWith(isPowerOn: nextState));
    await _bluetoothController.sendPowerCommand(nextState);
  }

  @override
  Future<void> connectToDevice([String? macAddress]) async {
    try {
      await _bluetoothController.connectToDevice(macAddress);
      _updateState(_state.copyWith(isConnected: true));
      await _bluetoothController.sendData('GET_STATUS');
    } catch (_) {
      _updateState(_state.copyWith(isConnected: false));
      rethrow;
    }
  }

  @override
  void dispose() {
    _bluetoothSubscription?.cancel();
    _bluetoothController.dispose();
    _stateController.close();
  }
}
