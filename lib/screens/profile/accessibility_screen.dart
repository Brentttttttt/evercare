import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/accessibility_settings_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/accessibility_settings_scope.dart';
import '../../widgets/app_page.dart';
import '../../widgets/section_header.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  EverCareTextSize _fallbackTextSize = EverCareTextSize.standard;
  bool _fallbackReduceMotion = false;

  void _setTextSize(
    AccessibilitySettingsController? settings,
    EverCareTextSize textSize,
  ) {
    if (settings != null) {
      unawaited(settings.setTextSize(textSize));
      return;
    }
    setState(() => _fallbackTextSize = textSize);
  }

  void _setReduceMotion(
    AccessibilitySettingsController? settings,
    bool reduceMotion,
  ) {
    if (settings != null) {
      unawaited(settings.setReduceMotion(reduceMotion));
      return;
    }
    setState(() => _fallbackReduceMotion = reduceMotion);
  }

  @override
  Widget build(BuildContext context) {
    final settings = EverCareAccessibilityScope.maybeWatch(context);
    final textSize = settings?.textSize ?? _fallbackTextSize;
    final reduceMotion = settings?.reduceMotion ?? _fallbackReduceMotion;
    final deviceReducedMotion =
        MediaQuery.disableAnimationsOf(context) && !reduceMotion;
    final previewSize = settings == null ? 18 * textSize.multiplier : 18.0;

    return DetailPage(
      title: 'Accessibility',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCard(
            color: AppColors.muted,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.visibility_outlined, color: AppColors.darkGreen),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings apply across EverCare',
                        style: AppTextStyles.cardTitle,
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Text size and motion preferences are saved on this device and used throughout the app.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Text size preview'),
          const SizedBox(height: 10),
          AppCard(
            color: AppColors.lightGreen,
            borderColor: AppColors.lightGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'EverCare is designed to be easy to read.',
                  style: TextStyle(
                    fontSize: previewSize,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Font size', style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                const Text(
                  'Choose a comfortable size for EverCare.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('A', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Slider(
                        value: textSize.index.toDouble(),
                        min: 0,
                        max: 2,
                        divisions: 2,
                        label: textSize.label,
                        onChanged: (value) => _setTextSize(
                          settings,
                          EverCareTextSize.values[value.round()],
                        ),
                      ),
                    ),
                    const Text(
                      'A',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduce motion'),
                  subtitle: Text(
                    deviceReducedMotion
                        ? 'Your device setting is currently reducing motion too.'
                        : 'Limit movement and transitions throughout EverCare.',
                  ),
                  value: reduceMotion,
                  onChanged: (value) => _setReduceMotion(settings, value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Display contrast'),
          const SizedBox(height: 10),
          const AppCard(
            color: AppColors.muted,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.contrast_outlined, color: AppColors.darkGreen),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use your device contrast setting',
                        style: AppTextStyles.cardTitle,
                      ),
                      SizedBox(height: 3),
                      Text(
                        'EverCare follows your device display and accessibility settings. To increase contrast or enable high-contrast text, open Accessibility in your device Settings.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
