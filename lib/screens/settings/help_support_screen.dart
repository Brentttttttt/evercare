import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
import '../authentication/auth_widgets.dart';

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
                        'Browse simple guides or preview the support form.',
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
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                _HelpItem(
                  title: 'Frequently asked questions',
                  icon: Icons.quiz_outlined,
                  onTap: () => _guide(context, 'Frequently asked questions'),
                ),
                _HelpItem(
                  title: 'How to use EverCare',
                  icon: Icons.touch_app_outlined,
                  onTap: () => _guide(context, 'How to use EverCare'),
                ),
                _HelpItem(
                  title: 'Medication guide',
                  icon: Icons.medication_outlined,
                  onTap: () => _guide(context, 'Medication guide'),
                ),
                _HelpItem(
                  title: 'Blood-pressure record guide',
                  icon: Icons.monitor_heart_outlined,
                  onTap: () => _guide(context, 'Blood-pressure record guide'),
                ),
                _HelpItem(
                  title: 'Caregiver guide',
                  icon: Icons.diversity_1_outlined,
                  onTap: () => _guide(context, 'Caregiver guide'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Contact Support'),
          const SizedBox(height: 10),
          const MockTextField(
            label: 'Subject',
            hint: 'What do you need help with?',
            icon: Icons.subject_rounded,
          ),
          const MockTextField(
            label: 'Message',
            hint: 'Tell us more',
            icon: Icons.chat_bubble_outline_rounded,
            maxLines: 4,
          ),
          PrimaryButton(
            label: 'Preview Support Request',
            icon: Icons.send_outlined,
            onPressed: () => showMockDialog(
              context,
              title: 'Support request preview',
              message:
                  'Your message has not been sent. The support form is visual only.',
              icon: Icons.mark_email_read_outlined,
            ),
          ),
        ],
      ),
    );
  }

  void _guide(BuildContext context, String title) {
    showMockDialog(
      context,
      title: title,
      message:
          'This sample guide introduces the feature with large, simple steps. Full support content will be added in a later phase.',
      icon: Icons.menu_book_outlined,
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 60,
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
