import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
        title: const Text('Log out of EverCare?'),
        content: const Text(
          'You will return to the login screen. No account data is changed in this prototype.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (shouldLogOut == true && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = MockData.profile;
    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            color: AppColors.lightGreen,
            borderColor: AppColors.lightGreen,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      child: Text(
                        'MS',
                        style: TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -5,
                      bottom: -3,
                      child: IconButton.filled(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Edit profile',
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.editProfile),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(profile['name']!, style: AppTextStyles.sectionTitle),
                const SizedBox(height: 5),
                Text(
                  '${profile['age']} years old · ${profile['userType']}',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .74),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            size: 17,
                            color: AppColors.darkGreen,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              profile['email']!,
                              style: AppTextStyles.bodyMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 17,
                            color: AppColors.darkGreen,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            profile['phone']!,
                            style: AppTextStyles.bodyMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              children: [
                _ProfileMenuItem(
                  icon: Icons.badge_outlined,
                  label: 'Personal Information',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                _ProfileMenuItem(
                  icon: Icons.medical_information_outlined,
                  label: 'Medical Information',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.medicalInfo),
                ),
                _ProfileMenuItem(
                  icon: Icons.contact_emergency_outlined,
                  label: 'Emergency Contacts',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.emergencyContacts),
                ),
                _ProfileMenuItem(
                  icon: Icons.family_restroom_rounded,
                  label: 'Family and Caregivers',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.caregiverList),
                ),
                _ProfileMenuItem(
                  icon: Icons.accessibility_new_rounded,
                  label: 'Accessibility',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.accessibility),
                ),
                _ProfileMenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                ),
                _ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help and Support',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.helpSupport),
                ),
                _ProfileMenuItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About EverCare',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            onTap: () => _confirmLogout(context),
            child: const Row(
              children: [
                Icon(Icons.logout_rounded, color: AppColors.danger),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Log Out',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.danger),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.darkGreen, size: 22),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.secondaryText,
      ),
      onTap: onTap,
    );
  }
}
