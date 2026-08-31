import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class FloatingPowerController extends StatelessWidget {
  final bool isPoweredOn;
  final VoidCallback onPressed;

  const FloatingPowerController({
    super.key,
    required this.isPoweredOn,
    required this.onPressed,
  });

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
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(48)),
                border: Border.all(color: AppColors.dockBorder),
                boxShadow: const [
                  BoxShadow(color: Color(0x12000000), blurRadius: 5, offset: Offset(0, -2)),
                ],
              ),
            ),
          ),
          Material(
            color: AppColors.white,
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
                  decoration: BoxDecoration(
                    color: isPoweredOn ? AppColors.coral : AppColors.inactivePower,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.power_settings_new_rounded, color: AppColors.white, size: 64),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
