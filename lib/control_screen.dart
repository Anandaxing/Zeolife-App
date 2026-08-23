// control_page.dart
import 'package:flutter/material.dart';
  // Reuse your color palette
const Color darkerGreen = Color(0xFF063B00);
const Color darkGreen   = Color(0xFF266210);
const Color lightGreen  = Color(0xFF90B800);
const Color lime        = Color(0xFFE1E100);
const Color darkGray    = Color(0xFF333333);
const Color gainsboro   = Color(0xFFDCDCDC);
const Color white       = Color(0xFFFFFFFF);
const Color charcoal    = Color(0xFF292929);
const Color textGray    = Color(0xFF565656);
const Color coral       = Color(0xFFEB6A52);
const Color blue        = Color(0xFF5794BB);

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
        scaffoldBackgroundColor: white,
        colorScheme: ColorScheme.fromSeed(seedColor: lime),
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
  bool isPoweredOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
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
                  140,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DeviceHeader(),
                      const SizedBox(height: 34),
                      _StatusGrid(isPoweredOn: isPoweredOn),
                      const SizedBox(height: 210),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _PowerDock(
                  isPoweredOn: isPoweredOn,
                  onPressed: () => setState(() => isPoweredOn = !isPoweredOn),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _DeviceHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE4E4E4)),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: lime, shape: BoxShape.circle),
            child: const Icon(Icons.bluetooth, size: 32, color: darkGray),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'HC–05',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: darkGray),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F58E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: lightGreen, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text('CONNECTED', style: TextStyle(fontSize: 8, color: darkGray, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _StatusGrid({required bool isPoweredOn}) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.45,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatusCard(label: 'POWER STATUS', value: isPoweredOn ? 'ON' : 'OFF', dotColor: lightGreen),
        _StatusCard(label: 'TEMPERATURE', value: '190 °C', icon: Icons.thermostat_outlined, iconColor: blue, iconBackground: const Color(0xFFD5EBF2)),
        _StatusCard(label: 'CURRENT PROCESS', value: isPoweredOn ? 'HEATING' : 'IDLE', dotColor: coral),
        const SizedBox.shrink(),
        _StatusCard(label: 'NEXT PROCESS', value: 'COOLING', dotColor: blue),
        _StatusCard(label: 'NEXT CYCLE IN', value: '01:10:32', icon: Icons.access_time_rounded, iconColor: blue, iconBackground: const Color(0xFFD5EBF2)),
      ],
    );
  }

  Widget _StatusCard({String? label, String? value, Color? dotColor, IconData? icon, Color? iconColor, Color? iconBackground}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2E2E2)),
        boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label!, style: const TextStyle(fontSize: 12, color: textGray, fontWeight: FontWeight.w400)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (dotColor != null) ...[
                      Container(width: 16, height: 16, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                      const SizedBox(width: 14),
                    ],
                    Flexible(child: Text(value!, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, color: charcoal, fontWeight: FontWeight.w800))),
                  ],
                ),
              ],
            ),
          ),
          if (icon != null)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
              child: Icon(icon, size: 24, color: iconColor),
            ),
        ],
      ),
    );
  }
}

class _PowerDock extends StatelessWidget {
  const _PowerDock({required this.isPoweredOn, required this.onPressed});

  final bool isPoweredOn;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 32,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(48)),
                border: Border.all(color: const Color(0xFFE7E7E7)),
                boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 5, offset: Offset(0, -2))],
              ),
            ),
          ),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Container(
                  decoration: BoxDecoration(color: isPoweredOn ? const Color(0xFFEB6A52) : const Color(0xFF9A9A9A), shape: BoxShape.circle),
                  child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 64),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
