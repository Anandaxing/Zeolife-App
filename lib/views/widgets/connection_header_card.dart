import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class ConnectionHeaderCard extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onTap;

  const ConnectionHeaderCard({
    super.key,
    required this.isConnected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.headerBorder),
            boxShadow: const [
              BoxShadow(color: Color(0x18000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
            child: const Icon(Icons.bluetooth, size: 32, color: AppColors.darkGray),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'HC–05',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.darkGray),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.badgeBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isConnected ? AppColors.lightGreen : AppColors.inactivePower,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? 'CONNECTED' : 'DISCONNECTED',
                  style: const TextStyle(fontSize: 8, color: AppColors.darkGray, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }
}
