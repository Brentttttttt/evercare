import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.pageTitle),
              if (subtitle != null) ...[
                const SizedBox(height: 7),
                Text(subtitle!, style: AppTextStyles.bodyMuted),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class EverCareHeader extends StatelessWidget {
  const EverCareHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.showNotifications = false,
    this.onNotifications,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showNotifications;
  final VoidCallback? onNotifications;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 11),
          child: Row(
            children: [
              if (showBack) ...[
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 2),
              ],
              const _EverCareBrandLockup(
                markSize: 37,
                textSize: 16,
                showWordmark: false,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 16.5),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small,
                      ),
                    ],
                  ],
                ),
              ),
              if (showNotifications)
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: onNotifications,
                  icon: const Badge(
                    smallSize: 8,
                    child: Icon(Icons.notifications_none_rounded),
                  ),
                ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class EverCareLogo extends StatelessWidget {
  const EverCareLogo({super.key, this.size = 76, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return _EverCareBrandLockup(
      markSize: size,
      textSize: size * .42,
      showWordmark: showWordmark,
    );
  }
}

class _EverCareBrandLockup extends StatelessWidget {
  const _EverCareBrandLockup({
    required this.markSize,
    required this.textSize,
    this.showWordmark = true,
  });

  final double markSize;
  final double textSize;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(markSize * .28),
          ),
          clipBehavior: Clip.antiAlias,
          child: Transform.scale(
            scale: 1.08,
            child: Image.asset(
              'assets/logo/evercare_app_icon.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              semanticLabel: 'EverCare logo',
            ),
          ),
        ),
        if (showWordmark) ...[
          SizedBox(width: markSize * .18),
          Text(
            'EverCare',
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: textSize,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -textSize * .035,
            ),
          ),
        ],
      ],
    );
  }
}
