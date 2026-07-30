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
            color: AppColors.lightGreen,
            borderColor: AppColors.lightGreen,
            child: Row(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primaryGreen,
                  size: 38,
                ),
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
          const SectionHeader(title: 'Guides'),
          const SizedBox(height: 10),
          const _HelpItem(
            title: 'Getting started',
            icon: Icons.touch_app_outlined,
            steps: [
              'Sign in to load records connected to your EverCare account.',
              'Use the navigation bar and arrow controls to move between the '
                  'main pages.',
              'An empty page means no record has been added yet; EverCare '
                  'does not create records on your behalf.',
            ],
          ),
          const SizedBox(height: 10),
          const _HelpItem(
            title: 'Medicines and appointments',
            icon: Icons.event_note_outlined,
            steps: [
              'Open Medicines or Appointments, then use the add button.',
              'Enter only information you have confirmed before saving.',
              'Use the detail page to review or update a saved record.',
            ],
          ),
          const SizedBox(height: 10),
          const _HelpItem(
            title: 'Blood-pressure readings',
            icon: Icons.monitor_heart_outlined,
            steps: [
              'Open My Health to connect a supported blood-pressure monitor.',
              'Keep the app open until the monitor reports a completed result.',
              'Readings are personal health records and are not medically '
                  'verified by EverCare.',
            ],
          ),
          const SizedBox(height: 10),
          const _HelpItem(
            title: 'Connection troubleshooting',
            icon: Icons.wifi_tethering_error_rounded,
            steps: [
              'Confirm that you are signed in and connected to the internet.',
              'Return to the page and try loading the records again.',
              'For monitor issues, confirm Bluetooth is available and keep the '
                  'monitor nearby while connecting.',
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'More help'),
          const SizedBox(height: 10),
          const AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.darkGreen),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Direct support messaging is not available in this version. '
                    'EverCare is not an emergency service; seek local emergency '
                    'help immediately when urgent care is needed.',
                    style: AppTextStyles.body,
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
    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.darkGreen, size: 22),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        childrenPadding: const EdgeInsets.fromLTRB(17, 0, 17, 17),
        children: [
          for (var index = 0; index < steps.length; index++)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(steps[index])),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
