import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const display = TextStyle(
    fontSize: 32,
    height: 1.08,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColors.foreground,
  );

  static const pageTitle = TextStyle(
    fontSize: 27,
    height: 1.14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.55,
    color: AppColors.foreground,
  );

  static const sectionTitle = TextStyle(
    fontSize: 20,
    height: 1.22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    color: AppColors.foreground,
  );

  static const cardTitle = TextStyle(
    fontSize: 17,
    height: 1.28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    color: AppColors.foreground,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
  );

  static const bodyMuted = TextStyle(
    fontSize: 15,
    height: 1.42,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
  );

  static const label = TextStyle(
    fontSize: 13,
    height: 1.32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05,
    color: AppColors.mutedForeground,
  );

  static const small = TextStyle(
    fontSize: 12,
    height: 1.34,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
  );

  static const eyebrow = TextStyle(
    fontSize: 11,
    height: 1.28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.7,
    color: AppColors.mutedForeground,
  );

  static const metric = TextStyle(
    fontSize: 34,
    height: 1.02,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.9,
    color: AppColors.foreground,
  );
}
