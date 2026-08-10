import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text_styles.dart';
import 'app_header.dart';

const pagePadding = EdgeInsets.fromLTRB(20, 20, 20, 36);

/// Extra scroll clearance for pages shown behind the floating main navigation.
const mainPagePadding = EdgeInsets.fromLTRB(20, 20, 20, 128);

const _cardRadius = 20.0;

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
      backgroundColor: AppColors.background,
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
      borderRadius: BorderRadius.circular(_cardRadius),
      side: borderColor == null
          ? BorderSide(
              color: AppColors.border.withValues(alpha: .38),
              width: .6,
            )
          : BorderSide(color: borderColor!),
    );
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: .38),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                borderRadius: BorderRadius.circular(_cardRadius),
                splashColor: AppColors.primaryGreen.withValues(alpha: .055),
                highlightColor: AppColors.primaryGreen.withValues(alpha: .025),
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
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: AppColors.darkGreen),
            ),
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
