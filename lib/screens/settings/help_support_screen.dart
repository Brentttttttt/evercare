import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/section_header.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Help and Support',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpIcon(icon: Icons.support_agent_rounded),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How can we help?',
                        style: AppTextStyles.sectionTitle,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Open a guide below for practical steps and '
                        'troubleshooting tips.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Guides',
            subtitle: 'Choose a topic to see step-by-step help.',
          ),
          const SizedBox(height: 10),
          const AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _HelpItem(
                  title: 'Getting started',
                  icon: Icons.touch_app_outlined,
                  steps: [
                    'Sign in to load records connected to your EverCare account.',
                    'Use the navigation bar and arrow controls to move between '
                        'the main pages.',
                    'An empty page means no record has been added yet; EverCare '
                        'does not create records on your behalf.',
                  ],
                ),
                Divider(height: 1, indent: 72, endIndent: 16),
                _HelpItem(
                  title: 'Medicines and appointments',
                  icon: Icons.event_note_outlined,
                  steps: [
                    'Open Medicines or Appointments, then use the add button.',
                    'Enter only information you have confirmed before saving.',
                    'Use the detail page to review or update a saved record.',
                  ],
                ),
                Divider(height: 1, indent: 72, endIndent: 16),
                _HelpItem(
                  title: 'Blood-pressure readings',
                  icon: Icons.monitor_heart_outlined,
                  steps: [
                    'Open My Health to connect a supported blood-pressure '
                        'monitor.',
                    'Keep the app open until the monitor reports a completed '
                        'result.',
                    'Readings are personal health records and are not medically '
                        'verified by EverCare.',
                  ],
                ),
                Divider(height: 1, indent: 72, endIndent: 16),
                _HelpItem(
                  title: 'Connection troubleshooting',
                  icon: Icons.wifi_tethering_error_rounded,
                  steps: [
                    'Confirm that you are signed in and connected to the '
                        'internet.',
                    'Return to the page and try loading the records again.',
                    'For monitor issues, confirm Bluetooth is available and '
                        'keep the monitor nearby while connecting.',
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'More help'),
          const SizedBox(height: 10),
          const AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpIcon(icon: Icons.info_outline_rounded),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support availability',
                        style: AppTextStyles.cardTitle,
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Direct support messaging is not available in this '
                        'version. EverCare is not an emergency service; seek '
                        'local emergency help immediately when urgent care is '
                        'needed.',
                        style: AppTextStyles.body,
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

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.title,
    required this.icon,
    required this.steps,
  });

  final String title;
  final IconData icon;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title help guide',
      child: ExpansionTile(
        key: PageStorageKey<String>(title),
        minTileHeight: 64,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: ExcludeSemantics(child: _HelpIcon(icon: icon)),
        title: Text(title, style: AppTextStyles.cardTitle),
        subtitle: const Text('Tap to view steps', style: AppTextStyles.small),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          for (var index = 0; index < steps.length; index++)
            Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.secondaryForeground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(steps[index], style: AppTextStyles.body),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HelpIcon extends StatelessWidget {
  const _HelpIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: .1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
