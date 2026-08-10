import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A lightweight translucent material for navigation and floating controls.
///
/// Keep this surface out of regular content cards. The opaque fallback color
/// maintains contrast on Android devices where the blurred backdrop is quiet.
class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    required this.child,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.padding = EdgeInsets.zero,
    this.blurSigma = 18,
    this.tint,
    this.borderColor,
    this.boxShadow,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final Color? tint;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final effectiveTint = tint ?? Colors.white.withValues(alpha: .66);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: .12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: effectiveTint,
              borderRadius: borderRadius,
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: .48),
                width: .7,
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
