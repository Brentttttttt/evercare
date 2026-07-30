import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Settings',
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Account',
                  subtitle: 'Review and update your profile',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                _SettingsItem(
                  icon: Icons.share_outlined,
                  title: 'Trusted caregivers',
                  subtitle: 'Manage people connected to your care',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.caregiverList),
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'View your account notifications',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.notifications),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help and support',
                  subtitle: 'Read guides and troubleshooting tips',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.helpSupport),
                ),
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About EverCare',
                  subtitle: 'App information and health-use notice',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppCard(
            color: AppColors.lightGreen,
            borderColor: AppColors.lightGreen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tune_rounded, color: AppColors.darkGreen),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Language, theme, permission controls, and legal documents '
                    'are not available in this version of EverCare.',
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

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 72,
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppColors.darkGreen),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(subtitle),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.secondaryText,
      ),
      onTap: onTap,
    );
  }
}
