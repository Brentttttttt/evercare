import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.sectionTitle),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: AppTextStyles.bodyMuted),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded, size: 17),
              ],
            ),
          ),
      ],
    );
  }
}
