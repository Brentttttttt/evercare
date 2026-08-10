import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/section_header.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  double _fontSize = 1;
  bool _highContrast = false;

  @override
  Widget build(BuildContext context) {
    final previewSize = 15 + (_fontSize * 3.5);
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
                      Text('Preview mode', style: AppTextStyles.cardTitle),
                      SizedBox(height: 3),
                      Text(
                        'These controls update the preview below only. They are not saved as app-wide preferences yet.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Text preview'),
          const SizedBox(height: 10),
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
                  title: const Text('High contrast preview'),
                  subtitle: const Text('Increase contrast in this preview'),
                  value: _highContrast,
                  onChanged: (value) => setState(() => _highContrast = value),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 14, 0, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('COMING LATER', style: AppTextStyles.eyebrow),
                  ),
                ),
                const SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Large button mode'),
                  subtitle: Text('App-wide preference is not available yet'),
                  value: true,
                  onChanged: null,
                ),
                const Divider(),
                const SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Reduced animations'),
                  subtitle: Text('App-wide preference is not available yet'),
                  value: false,
                  onChanged: null,
                ),
                const Divider(),
                const SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Text-to-speech preference'),
                  subtitle: Text('App-wide preference is not available yet'),
                  value: false,
                  onChanged: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
