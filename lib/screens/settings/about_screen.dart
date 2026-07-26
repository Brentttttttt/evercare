import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_page.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'About EverCare',
      child: Column(
        children: [
          const EverCareLogo(size: 78),
          const SizedBox(height: 10),
          const Text('Your Health. Our Care.', style: AppTextStyles.body),
          const SizedBox(height: 6),
          const Text('Version 1.0.0', style: AppTextStyles.bodyMuted),
          const SizedBox(height: 24),
          const AppCard(
            child: Text(
              'EverCare is an accessible care interface designed to help senior citizens and trusted caregivers keep blood-pressure readings, medicines, and appointments organized and easy to understand.',
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(height: 14),
          const AppCard(
            color: AppColors.lightGreen,
            borderColor: AppColors.lightGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.public_rounded,
                      color: AppColors.primaryGreen,
                      size: 30,
                    ),
                    SizedBox(width: 11),
                    Text('Supporting SDG 3', style: AppTextStyles.sectionTitle),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'EverCare reflects the goal of ensuring healthy lives and promoting well-being for all ages through an inclusive, elderly-friendly design.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.primaryGreen,
                  ),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _legal(context, 'Privacy Policy'),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.gavel_outlined,
                    color: AppColors.primaryGreen,
                  ),
                  title: const Text('Terms and Conditions'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _legal(context, 'Terms and Conditions'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '© 2026 EverCare UI Prototype',
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }

  void _legal(BuildContext context, String title) {
    showMockDialog(
      context,
      title: title,
      message:
          'This is placeholder legal content for the EverCare interface prototype.',
      icon: Icons.description_outlined,
    );
  }
}
