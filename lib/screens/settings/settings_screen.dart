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
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: [
            _SettingsItem(
              icon: Icons.manage_accounts_outlined,
              title: 'Account',
              subtitle: 'Profile and account preferences',
              onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
            ),
            _SettingsItem(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy',
              subtitle: 'Privacy controls and information',
              onTap: () => _preview(context, 'Privacy'),
            ),
            _SettingsItem(
              icon: Icons.share_outlined,
              title: 'Shared health information',
              subtitle: 'Manage trusted people',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.caregiverList),
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              title: 'Notification preferences',
              subtitle: 'Static notification settings',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.notifications),
            ),
            _SettingsItem(
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: 'English',
              onTap: () => _preview(context, 'Language'),
            ),
            _SettingsItem(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: 'Light',
              onTap: () => _preview(context, 'Theme'),
            ),
            _SettingsItem(
              icon: Icons.policy_outlined,
              title: 'Data permissions',
              subtitle: 'Review sample permissions',
              onTap: () => _preview(context, 'Data permissions'),
            ),
            _SettingsItem(
              icon: Icons.gavel_outlined,
              title: 'Terms and conditions',
              subtitle: 'Read the placeholder terms',
              onTap: () => _preview(context, 'Terms and conditions'),
            ),
          ],
        ),
      ),
    );
  }

  void _preview(BuildContext context, String title) {
    showMockDialog(
      context,
      title: title,
      message:
          'This setting is included as a static interface preview. No preference or permission has been changed.',
      icon: Icons.tune_rounded,
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
