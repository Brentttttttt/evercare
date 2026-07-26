import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_page.dart';

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(icon, size: 48, color: AppColors.primaryGreen),
              const SizedBox(height: 14),
              Text(title, style: AppTextStyles.cardTitle),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
