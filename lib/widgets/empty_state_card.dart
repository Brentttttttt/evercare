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
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 10),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 27, color: AppColors.darkGreen),
                ),
                const SizedBox(height: 17),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 19),
                  if (actionIcon == null)
                    OutlinedButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: onAction,
                      icon: Icon(actionIcon, size: 19),
                      label: Text(actionLabel!),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
