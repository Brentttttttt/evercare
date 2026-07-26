import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text_styles.dart';
import 'app_header.dart';

const pagePadding = EdgeInsets.fromLTRB(20, 18, 20, 32);

class DetailPage extends StatelessWidget {
  const DetailPage({
    required this.title,
    required this.child,
    super.key,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          EverCareHeader(
            title: title,
            showBack: true,
            actions: actions ?? const [],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(padding: pagePadding, child: child),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(19),
    this.color,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: borderColor ?? AppColors.border),
    );
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: color ?? AppColors.card,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                splashColor: AppColors.primaryGreen.withValues(alpha: .08),
                highlightColor: AppColors.primaryGreen.withValues(alpha: .035),
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
    return onTap == null ? card : PressScale(child: card);
  }
}

class LabeledValue extends StatelessWidget {
  const LabeledValue({
    required this.label,
    required this.value,
    super.key,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: AppColors.primaryGreen),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label),
                const SizedBox(height: 3),
                Text(value, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showMockDialog(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'Got it',
  IconData icon = Icons.info_outline_rounded,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(icon, color: AppColors.primaryGreen, size: 34),
      title: Text(title),
      content: Text(message),
      actions: [
        PressScale(
          child: FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(actionLabel),
          ),
        ),
      ],
    ),
  );
}
