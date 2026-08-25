import 'package:flutter/material.dart';

import '../models/blood_pressure_assessment.dart';
import '../theme/app_colors.dart';

export 'evercare_ai_mascot.dart';

const bpLevelVisualKey = ValueKey<String>('bp-level-visual');

/// Returns the bundled hero artwork for one blood-pressure measurement range.
///
/// Keep this switch exhaustive so a newly introduced category cannot silently
/// inherit artwork that communicates a different result.
String bloodPressureHeroAssetFor(BloodPressureCategory category) =>
    switch (category) {
      BloodPressureCategory.lowerThanUsual =>
        'assets/health/bp_levels/bp_lower_hero.webp',
      BloodPressureCategory.normal =>
        'assets/health/bp_levels/bp_normal_hero.webp',
      BloodPressureCategory.elevated =>
        'assets/health/bp_levels/bp_elevated_hero.webp',
      BloodPressureCategory.hypertensionStage1 =>
        'assets/health/bp_levels/bp_stage1_hero.webp',
      BloodPressureCategory.hypertensionStage2 =>
        'assets/health/bp_levels/bp_stage2_hero.webp',
      BloodPressureCategory.severeHypertension =>
        'assets/health/bp_levels/bp_severe_hero.webp',
    };

/// Category-aware artwork for the main blood-pressure result card.
///
/// The image is deliberately decorative because the adjacent status and range
/// text remain the accessible source of truth. This prevents artwork, facial
/// expression, or color from becoming the only way a result is communicated.
class BpLevelVisual extends StatelessWidget {
  const BpLevelVisual({
    required this.category,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.centerRight,
    this.cacheWidth = 1200,
    this.errorBuilder,
  });

  final BloodPressureCategory category;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final int? cacheWidth;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      bloodPressureHeroAssetFor(category),
      key: bpLevelVisualKey,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      errorBuilder: errorBuilder ?? _buildHeroFallback,
    );
  }

  Widget _buildHeroFallback(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: const ColoredBox(
        color: AppColors.accent,
        child: Center(
          child: Icon(
            Icons.monitor_heart_outlined,
            color: AppColors.primaryGreen,
            size: 42,
          ),
        ),
      ),
    );
  }
}
