import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const display = TextStyle(
    fontSize: 32,
    height: 1.08,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.1,
    color: AppColors.primaryText,
  );

  static const pageTitle = TextStyle(
    fontSize: 25,
    height: 1.14,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.65,
    color: AppColors.primaryText,
  );

  static const sectionTitle = TextStyle(
    fontSize: 19,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.primaryText,
  );

  static const cardTitle = TextStyle(
    fontSize: 16,
    height: 1.24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.15,
    color: AppColors.primaryText,
  );

  static const body = TextStyle(
    fontSize: 14.5,
    height: 1.42,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
  );

  static const bodyMuted = TextStyle(
    fontSize: 13.5,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  static const label = TextStyle(
    fontSize: 12,
    height: 1.22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.secondaryText,
  );

  static const small = TextStyle(
    fontSize: 11.5,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.secondaryText,
  );

  static const eyebrow = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.05,
    color: AppColors.secondaryText,
  );

  static const metric = TextStyle(
    fontSize: 31,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    color: AppColors.primaryText,
  );
}
