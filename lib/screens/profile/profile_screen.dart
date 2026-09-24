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
import '../../widgets/profile_avatar.dart';
import '../../widgets/section_header.dart';
import 'logout_action_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

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
      controller: widget.scrollController,
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileSummaryCard(
                      profile: snapshot.data!,
                      onEdit: _openEditProfile,
                    ),
                    const SizedBox(height: 26),
                    const SectionHeader(
                      title: 'Personal details',
                      subtitle: 'Your information, in one place.',
                    ),
                    const SizedBox(height: 12),
                    _PersonalDetailsCard(profile: snapshot.data!),
                  ],
                );
              },
            ),
          const SizedBox(height: 26),
          const SectionHeader(
            title: 'Your account',
            subtitle: 'Keep your profile and contact details up to date.',
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _ProfileMenuItem(
              icon: Icons.badge_outlined,
              color: AppColors.primaryGreen,
              label: 'Personal Information',
              subtitle: 'Name, birthday, photo and contact details',
              onTap: isSignedIn ? _openEditProfile : null,
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'Emergency support',
            subtitle: 'Keep help close when you need it.',
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: _ProfileMenuItem(
              icon: Icons.contact_emergency_outlined,
              color: AppColors.danger,
              label: 'Emergency Contacts',
              subtitle: 'The people to reach when you need help',
              onTap: isSignedIn
                  ? () => Navigator.pushNamed(
                      context,
                      AppRoutes.emergencyContacts,
                    )
                  : null,
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
                  subtitle: 'Text size and a more comfortable view',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.accessibility),
                ),
                _ProfileMenuItem(
                  icon: Icons.settings_outlined,
                  color: AppColors.secondaryText,
                  label: 'Settings',
                  subtitle: 'Phone reminders and app preferences',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                ),
                _ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  color: AppColors.warning,
                  label: 'Help and Support',
                  subtitle: 'Find guidance for using EverCare',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.helpSupport),
                ),
                _ProfileMenuItem(
                  icon: Icons.info_outline_rounded,
                  color: AppColors.primaryGreen,
                  label: 'About EverCare',
                  subtitle: 'Get to know your care companion',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                ),
              ],
            ),
          ),
          if (isSignedIn) ...[
            const SizedBox(height: 14),
            LogoutActionTile(onTap: _confirmLogout, isLoading: _isSigningOut),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkGreen, AppColors.primaryGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.favorite_outline_rounded,
                  color: Color(0xFFD6EFE0),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'YOUR EVERCARE PROFILE',
                    style: AppTextStyles.eyebrow.copyWith(
                      color: const Color(0xFFD6EFE0),
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Center(
              child: _EditableProfileAvatar(profile: profile, onEdit: onEdit),
            ),
            const SizedBox(height: 18),
            Text(
              profile.fullName.trim().isEmpty
                  ? 'Your EverCare profile'
                  : profile.fullName,
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle.copyWith(
                color: Colors.white,
                fontSize: 28,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: .2)),
                ),
                child: Text(
                  profile.userTypeLabel.isEmpty
                      ? 'Care role not added'
                      : profile.userTypeLabel,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              profile.email.trim().isEmpty
                  ? 'Account email unavailable'
                  : profile.email,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted.copyWith(
                color: const Color(0xFFE2F3E9),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onEdit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.darkGreen,
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_outlined, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Edit profile',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableProfileAvatar extends StatelessWidget {
  const _EditableProfileAvatar({required this.profile, required this.onEdit});

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('profile-photo-edit'),
      button: true,
      label: 'Change profile photo',
      hint: 'Opens Edit Profile to choose and crop a photo.',
      onTap: onEdit,
      excludeSemantics: true,
      child: Tooltip(
        message: 'Change profile photo',
        child: Material(
          color: Colors.white.withValues(alpha: .15),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: .35)),
          ),
          child: InkWell(
            onTap: onEdit,
            customBorder: const CircleBorder(),
            excludeFromSemantics: true,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Stack(
                children: [
                  ProfileAvatar(profile: profile, size: 104),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.darkGreen,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalDetailsCard extends StatelessWidget {
  const _PersonalDetailsCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final birthDate = profile.birthDate;
    final age = profile.ageOn(DateTime.now());
    final birthday = birthDate == null
        ? 'Not added yet'
        : MaterialLocalizations.of(context).formatCompactDate(birthDate);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          _PersonalDetail(
            icon: Icons.cake_outlined,
            label: 'Date of birth',
            value: birthday,
            note: age == null ? null : '$age years old',
          ),
          const Divider(height: 1),
          _PersonalDetail(
            icon: Icons.phone_outlined,
            label: 'Phone number',
            value: profile.phoneNumber.trim().isEmpty
                ? 'Not added yet'
                : profile.phoneNumber,
          ),
          const Divider(height: 1),
          _PersonalDetail(
            icon: Icons.home_outlined,
            label: 'Address',
            value: profile.address.trim().isEmpty
                ? 'Not added yet'
                : profile.address,
          ),
        ],
      ),
    );
  }
}

class _PersonalDetail extends StatelessWidget {
  const _PersonalDetail({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.darkGreen, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label),
                const SizedBox(height: 5),
                Text(value, style: AppTextStyles.body),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(note!, style: AppTextStyles.bodyMuted),
                ],
              ],
            ),
          ),
        ],
      ),
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
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 76),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: onTap == null ? .04 : .09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: onTap == null ? AppColors.mutedForeground : color,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 16,
                          color: onTap == null
                              ? AppColors.mutedForeground
                              : AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.small.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
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
