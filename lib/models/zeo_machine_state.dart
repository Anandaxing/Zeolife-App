abstract class MachineModule {
  final String id;
  final bool isOperational;

  const MachineModule({
    required this.id,
    required this.isOperational,
  });
}

class FanModule extends MachineModule {
  final int rpm;

  const FanModule({
    required super.id,
    required super.isOperational,
    required this.rpm,
  });

  FanModule copyWith({
    String? id,
    bool? isOperational,
    int? rpm,
  }) {
    return FanModule(
      id: id ?? this.id,
      isOperational: isOperational ?? this.isOperational,
      rpm: rpm ?? this.rpm,
    );
  }
}

class ThermalSensor extends MachineModule {
  final double temperatureCelsius;

  const ThermalSensor({
    required super.id,
    required super.isOperational,
    required this.temperatureCelsius,
  });

  double get temperatureFahrenheit => (temperatureCelsius * 9 / 5) + 32;

  ThermalSensor copyWith({
    String? id,
    bool? isOperational,
    double? temperatureCelsius,
  }) {
    return ThermalSensor(
      id: id ?? this.id,
      isOperational: isOperational ?? this.isOperational,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
    );
  }
}

class ZeoMachineState {
  final bool isConnected;
  final bool isPowerOn;
  final String currentProcess;
  final String nextProcess;
  final String nextCycleIn;
  final ThermalSensor primaryHeater;
  final List<FanModule> coolingFans;

  const ZeoMachineState({
    this.isConnected = false,
    this.isPowerOn = false,
    this.currentProcess = 'HEATING',
    this.nextProcess = 'COOLING',
    this.nextCycleIn = '01:10:32',
    this.primaryHeater = const ThermalSensor(
      id: 'HEATER_1',
      isOperational: true,
      temperatureCelsius: 190.0,
    ),
    this.coolingFans = const [
      FanModule(id: 'FAN_1', isOperational: true, rpm: 1500),
      FanModule(id: 'FAN_2', isOperational: false, rpm: 0),
      FanModule(id: 'FAN_3', isOperational: true, rpm: 1000),
      FanModule(id: 'FAN_4', isOperational: true, rpm: 1200),
    ],
  });

  ZeoMachineState copyWith({
    bool? isConnected,
    bool? isPowerOn,
    String? currentProcess,
    String? nextProcess,
    String? nextCycleIn,
    ThermalSensor? primaryHeater,
    List<FanModule>? coolingFans,
  }) {
    return ZeoMachineState(
      isConnected: isConnected ?? this.isConnected,
      isPowerOn: isPowerOn ?? this.isPowerOn,
      currentProcess: currentProcess ?? this.currentProcess,
      nextProcess: nextProcess ?? this.nextProcess,
      nextCycleIn: nextCycleIn ?? this.nextCycleIn,
      primaryHeater: primaryHeater ?? this.primaryHeater,
      coolingFans: coolingFans ?? this.coolingFans,
    );
  }
}
