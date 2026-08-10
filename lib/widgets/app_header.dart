import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text_styles.dart';
import 'app_glass_surface.dart';

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
    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.pageTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(subtitle!, style: AppTextStyles.bodyMuted),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
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
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: .68),
            width: .7,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: .2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppGlassSurface(
        borderRadius: BorderRadius.zero,
        blurSigma: 22,
        tint: Colors.white.withValues(alpha: .89),
        borderColor: Colors.transparent,
        boxShadow: const [],
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 12, 8),
            child: Row(
              children: [
                if (showBack) ...[
                  _HeaderIconButton(
                    tooltip: 'Back',
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 5),
                ],
                const _EverCareBrandLockup(
                  markSize: 39,
                  textSize: 16,
                  showWordmark: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle.copyWith(
                            fontSize: 17,
                            letterSpacing: -.25,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 1),
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
                ),
                if (showNotifications)
                  _HeaderIconButton(
                    tooltip: 'Notifications',
                    icon: Icons.notifications_none_rounded,
                    onPressed: onNotifications,
                  ),
                ...actions,
              ],
            ),
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
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: .24),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: onPressed != null,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size.square(44),
          foregroundColor: AppColors.primaryText,
          backgroundColor: Colors.white.withValues(alpha: .62),
          disabledBackgroundColor: AppColors.surfaceMuted,
          shape: const CircleBorder(),
        ),
        icon: Icon(icon, size: 21),
      ),
    );
  }
}
