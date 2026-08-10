import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/section_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  SupabaseClient? _client;
  Future<UserProfile>? _profileFuture;
  bool _scopeChecked = false;
  bool _isSigningOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextClient = EverCareBackendScope.maybeClient(context);
    if (_scopeChecked && identical(nextClient, _client)) return;
    _scopeChecked = true;
    _client = nextClient;
    _loadProfile();
  }

  void _loadProfile() {
    final client = _client;
    _profileFuture = client == null || client.auth.currentUser == null
        ? null
        : ProfileRepository(client).fetchCurrentProfile();
  }

  void _retryProfile() {
    setState(_loadProfile);
  }

  Future<void> _openEditProfile() async {
    final changed = await Navigator.pushNamed(context, AppRoutes.editProfile);
    if (changed == true && mounted) _retryProfile();
  }

  Future<void> _confirmLogout() async {
    final client = _client;
    if (client == null) return;
    final shouldLogOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
        title: const Text('Log out of EverCare?'),
        content: const Text(
          'This will securely end your current EverCare session on this device.',
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
    if (shouldLogOut != true || !mounted) return;

    setState(() => _isSigningOut = true);
    try {
      await AuthService(client).signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not log out. Check your connection and retry.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = _client;
    final isSignedIn = client?.auth.currentUser != null;
    return SingleChildScrollView(
      padding: mainPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (client == null)
            const _ProfileNotice(
              icon: Icons.cloud_off_outlined,
              title: 'Account data unavailable',
              message:
                  'This screen is not connected to the configured Supabase project.',
            )
          else if (!isSignedIn)
            _ProfileNotice(
              icon: Icons.person_off_outlined,
              title: 'You are signed out',
              message: 'Log in to view and update your EverCare profile.',
              actionLabel: 'Go to Login',
              onAction: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              ),
            )
          else
            FutureBuilder<UserProfile>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppCardSkeleton(showLeading: false, lines: 4);
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _ProfileNotice(
                    icon: Icons.sync_problem_outlined,
                    title: 'Profile could not be loaded',
                    message:
                        'Check your connection and confirm the EverCare database setup.',
                    actionLabel: 'Try Again',
                    onAction: _retryProfile,
                  );
                }
                return _ProfileSummaryCard(
                  profile: snapshot.data!,
                  onEdit: _openEditProfile,
                );
              },
            ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Personal care',
            subtitle: 'Keep your identity and care information up to date.',
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _ProfileMenuGroup(
              children: [
                _ProfileMenuItem(
                  icon: Icons.badge_outlined,
                  color: AppColors.blue,
                  label: 'Personal Information',
                  onTap: isSignedIn ? _openEditProfile : null,
                ),
                _ProfileMenuItem(
                  icon: Icons.medical_information_outlined,
                  color: AppColors.primaryGreen,
                  label: 'Medical Information',
                  onTap: isSignedIn
                      ? () =>
                            Navigator.pushNamed(context, AppRoutes.medicalInfo)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'Safety and sharing',
            subtitle: 'Manage emergency details and trusted people.',
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _ProfileMenuGroup(
              children: [
                _ProfileMenuItem(
                  icon: Icons.contact_emergency_outlined,
                  color: AppColors.danger,
                  label: 'Emergency Contacts',
                  onTap: isSignedIn
                      ? () => Navigator.pushNamed(
                          context,
                          AppRoutes.emergencyContacts,
                        )
                      : null,
                ),
                _ProfileMenuItem(
                  icon: Icons.family_restroom_rounded,
                  color: AppColors.purple,
                  label: 'Family and Caregivers',
                  onTap: isSignedIn
                      ? () => Navigator.pushNamed(
                          context,
                          AppRoutes.caregiverList,
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'App and support',
            subtitle: 'Adjust your experience or find help.',
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _ProfileMenuGroup(
              children: [
                _ProfileMenuItem(
                  icon: Icons.accessibility_new_rounded,
                  color: AppColors.blue,
                  label: 'Accessibility',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.accessibility),
                ),
                _ProfileMenuItem(
                  icon: Icons.settings_outlined,
                  color: AppColors.secondaryText,
                  label: 'Settings',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                ),
                _ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  color: AppColors.warning,
                  label: 'Help and Support',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.helpSupport),
                ),
                _ProfileMenuItem(
                  icon: Icons.info_outline_rounded,
                  color: AppColors.primaryGreen,
                  label: 'About EverCare',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                ),
              ],
            ),
          ),
          if (isSignedIn) ...[
            const SizedBox(height: 14),
            AppCard(
              onTap: _isSigningOut ? null : _confirmLogout,
              child: Row(
                children: [
                  if (_isSigningOut)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    const Icon(Icons.logout_rounded, color: AppColors.danger),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.profile, required this.onEdit});

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final age = profile.ageOn(DateTime.now());
    final details = <String>[
      if (age != null) '$age years old',
      if (profile.userTypeLabel.isNotEmpty) profile.userTypeLabel,
    ];
    return AppCard(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryContainer, AppColors.accent],
                  ),
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.card,
                  child: profile.initials.isEmpty
                      ? const Icon(
                          Icons.person_outline_rounded,
                          size: 40,
                          color: AppColors.darkGreen,
                        )
                      : Text(
                          profile.initials,
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              Positioned(
                right: -5,
                bottom: -3,
                child: IconButton.filled(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit profile',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.fullName.isEmpty
                ? 'Profile name not added'
                : profile.fullName,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 5),
          Text(
            details.isEmpty
                ? 'Profile details not added yet'
                : details.join(' · '),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _ContactLine(
                  icon: Icons.mail_outline_rounded,
                  value: profile.email.isEmpty
                      ? 'Account email unavailable'
                      : profile.email,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                _ContactLine(
                  icon: Icons.phone_outlined,
                  value: profile.phoneNumber.isEmpty
                      ? 'Phone number not added'
                      : profile.phoneNumber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 17, color: AppColors.darkGreen),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
        ),
      ],
    );
  }
}

class _ProfileNotice extends StatelessWidget {
  const _ProfileNotice({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.lightGreen,
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.darkGreen),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      enabled: onTap != null,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null ? color.withValues(alpha: .42) : color,
          borderRadius: BorderRadius.circular(11),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: .1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: AppColors.secondaryText,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}

class _ProfileMenuGroup extends StatelessWidget {
  const _ProfileMenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            const Divider(indent: 72, endIndent: 14),
        ],
      ],
    );
  }
}
