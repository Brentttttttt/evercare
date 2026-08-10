import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_page.dart';
import '../../widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Account and care',
            subtitle: 'Manage the people and updates connected to EverCare.',
          ),
          const SizedBox(height: 11),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _SettingsGroup(
              children: [
                _SettingsItem(
                  icon: Icons.manage_accounts_outlined,
                  color: AppColors.blue,
                  title: 'Account',
                  subtitle: 'Review and update your profile',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                _SettingsItem(
                  icon: Icons.share_outlined,
                  color: AppColors.primaryGreen,
                  title: 'Trusted caregivers',
                  subtitle: 'Manage people connected to your care',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.caregiverList),
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  color: AppColors.purple,
                  title: 'Notifications',
                  subtitle: 'View your account notifications',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.notifications),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Support and information',
            subtitle:
                'Find guidance and learn how EverCare handles health information.',
          ),
          const SizedBox(height: 11),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _SettingsGroup(
              children: [
                _SettingsItem(
                  icon: Icons.help_outline_rounded,
                  color: AppColors.warning,
                  title: 'Help and support',
                  subtitle: 'Read guides and troubleshooting tips',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.helpSupport),
                ),
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  color: AppColors.secondaryText,
                  title: 'About EverCare',
                  subtitle: 'App information and health-use notice',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            const Divider(indent: 70, endIndent: 14),
        ],
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
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
          color: color,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(subtitle),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.secondaryText,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
