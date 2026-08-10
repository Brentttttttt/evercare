import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_page.dart';

class MedicationCard extends StatelessWidget {
  const MedicationCard({
    required this.medication,
    required this.onTap,
    super.key,
  });

  final Medication medication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = medication.isActive;
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: active ? AppColors.lightGreen : const Color(0xFFFFF4E1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.medication_rounded,
              color: active ? AppColors.primaryGreen : AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.name, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(medication.dosage, style: AppTextStyles.body),
                const SizedBox(height: 4),
                Text(medication.purpose, style: AppTextStyles.bodyMuted),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      label: medication.scheduleLabel,
                      icon: Icons.schedule_rounded,
                    ),
                    _Pill(
                      label: medication.statusLabel,
                      icon: active
                          ? Icons.check_circle
                          : Icons.pause_circle_outline_rounded,
                      positive: active,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 13),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, this.positive = false});

  final String label;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: positive ? AppColors.lightGreen : AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: positive ? AppColors.darkGreen : AppColors.secondaryText,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: positive ? AppColors.darkGreen : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
