import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  double _fontSize = 1;
  bool _highContrast = false;
  bool _largeButtons = true;
  bool _reducedAnimations = false;
  bool _textToSpeech = false;

  @override
  Widget build(BuildContext context) {
    final previewSize = 15 + (_fontSize * 3.5);
    return DetailPage(
      title: 'Accessibility',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            color: _highContrast ? AppColors.primaryText : AppColors.lightGreen,
            borderColor: _highContrast
                ? AppColors.primaryText
                : AppColors.lightGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: AppTextStyles.label.copyWith(
                    color: _highContrast
                        ? Colors.white70
                        : AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'EverCare is designed to be easy to read.',
                  style: TextStyle(
                    fontSize: previewSize,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: _highContrast ? Colors.white : AppColors.primaryText,
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
                  'Adjust the preview text size',
                  style: AppTextStyles.bodyMuted,
                ),
                Row(
                  children: [
                    const Text('A', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 0,
                        max: 2,
                        divisions: 2,
                        label: [
                          'Default',
                          'Large',
                          'Extra large',
                        ][_fontSize.round()],
                        onChanged: (value) => setState(() => _fontSize = value),
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
                  title: const Text('High contrast mode'),
                  subtitle: const Text('Increase contrast in the preview'),
                  value: _highContrast,
                  onChanged: (value) => setState(() => _highContrast = value),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Large button mode'),
                  subtitle: const Text('Prefer larger touch targets'),
                  value: _largeButtons,
                  onChanged: (value) => setState(() => _largeButtons = value),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduced animations'),
                  subtitle: const Text('Prefer less visual motion'),
                  value: _reducedAnimations,
                  onChanged: (value) =>
                      setState(() => _reducedAnimations = value),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Text-to-speech preference'),
                  subtitle: const Text('Visual preference only'),
                  value: _textToSpeech,
                  onChanged: (value) => setState(() => _textToSpeech = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Preferences update this screen only and are not saved.',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}
