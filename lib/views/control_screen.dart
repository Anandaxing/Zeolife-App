import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../controllers/machine_controller.dart';
import '../models/zeo_machine_state.dart';
import 'widgets/connection_header_card.dart';
import 'widgets/floating_power_controller.dart';
import 'widgets/status_metric_card.dart';
import 'widgets/fan_stat_card.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HC-05 Remote Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.lime),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final MachineController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ZeoMachineController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<ZeoMachineState>(
        stream: _controller.stateStream,
        initialData: _controller.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _controller.currentState;

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final contentWidth = width > 650 ? 620.0 : width - 48;
              final horizontalPadding = (width - contentWidth) / 2;

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      80,
                      horizontalPadding,
                      0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ConnectionHeaderCard(
                            isConnected: state.isConnected,
                            onTap: () async {
                              if (state.isConnected) return;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Connecting to HC-05...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                              try {
                                await _controller.connectToDevice();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Connected to HC-05!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to connect: $e'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          // Core Metrics Grid
                          GridView.count(
                            padding: EdgeInsets.zero,
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 2.1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              StatusMetricCard(
                                label: 'POWER STATUS',
                                value: state.isPowerOn ? 'ON' : 'OFF',
                                dotColor: AppColors.lightGreen,
                              ),
                              StatusMetricCard(
                                label: 'TEMPERATURE',
                                value: '${state.primaryHeater.temperatureCelsius.toStringAsFixed(0)} °C',
                                icon: Icons.thermostat_outlined,
                                iconColor: AppColors.blue,
                                iconBackground: AppColors.iconBackgroundBlue,
                              ),
                              StatusMetricCard(
                                label: 'CURRENT PROCESS',
                                value: state.isPowerOn ? state.currentProcess : 'IDLE',
                                dotColor: AppColors.coral,
                              ),
                              StatusMetricCard(
                                label: 'TEMPERATURE',
                                value: '${state.primaryHeater.temperatureFahrenheit.toStringAsFixed(0)} °F',
                                icon: Icons.thermostat_outlined,
                                iconColor: AppColors.blue,
                                iconBackground: AppColors.iconBackgroundBlue,
                              ),
                              StatusMetricCard(
                                label: 'NEXT PROCESS',
                                value: state.nextProcess,
                                dotColor: AppColors.blue,
                              ),
                              StatusMetricCard(
                                label: 'NEXT CYCLE IN',
                                value: state.nextCycleIn,
                                icon: Icons.access_time_rounded,
                                iconColor: AppColors.blue,
                                iconBackground: AppColors.iconBackgroundBlue,
                              ),
                            ],
                          ),
                          // Fan Statistics Grid
                          GridView.builder(
                            padding: const EdgeInsets.only(top: 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.3,
                            ),
                            itemCount: state.coolingFans.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final fan = state.coolingFans[index];
                              return FanStatCard(
                                title: 'FAN ${index + 1} STATS',
                                isOperational: fan.isOperational,
                                rpm: fan.rpm,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FloatingPowerController(
                      isPoweredOn: state.isPowerOn,
                      onPressed: () {
                        if (!state.isConnected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Not connected! Tap the HC-05 card at the top to connect first.'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        _controller.toggleMainPower();
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
