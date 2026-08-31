import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class FanStatCard extends StatelessWidget {
  final String title;
  final bool isOperational;
  final int rpm;

  const FanStatCard({
    super.key,
    required this.title,
    required this.isOperational,
    required this.rpm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x16000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.iconBackgroundBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cyclone, size: 20, color: AppColors.blue),
              ),
              const SizedBox(width: 8),
              Text(
                isOperational ? 'ON' : 'OFF',
                style: const TextStyle(fontSize: 16, color: AppColors.charcoal, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isOperational ? AppColors.lightGreen : AppColors.coral,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.iconBackgroundBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.speed, size: 20, color: AppColors.blue),
              ),
              const SizedBox(width: 8),
              const Text(
                'RPM ',
                style: TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w400),
              ),
              Flexible(
                child: Text(
                  '$rpm',
                  style: const TextStyle(fontSize: 16, color: AppColors.charcoal, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
