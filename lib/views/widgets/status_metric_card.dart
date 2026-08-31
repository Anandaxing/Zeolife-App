import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class StatusMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? dotColor;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;

  const StatusMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.dotColor,
    this.icon,
    this.iconColor,
    this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x16000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (dotColor != null) ...[
                      Container(width: 16, height: 16, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                      const SizedBox(width: 14),
                    ],
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, color: AppColors.charcoal, fontWeight: FontWeight.w800),
                      ),
                    ),
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
