import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/primary_button.dart';
import '../authentication/auth_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _addressController = TextEditingController();

  SupabaseClient? _client;
  Future<UserProfile>? _profileFuture;
  UserProfile? _profile;
  DateTime? _birthDate;
  String _userType = '';
  bool _scopeChecked = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextClient = EverCareBackendScope.maybeClient(context);
    if (_scopeChecked && identical(nextClient, _client)) return;
    _scopeChecked = true;
    _client = nextClient;
    _profile = null;
    _profileFuture = nextClient == null || nextClient.auth.currentUser == null
        ? null
        : ProfileRepository(nextClient).fetchCurrentProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _populate(UserProfile profile) {
    if (_profile != null) return;
    _profile = profile;
    _fullNameController.text = profile.fullName;
    _emailController.text = profile.email;
    _phoneController.text = profile.phoneNumber;
    _birthDate = profile.birthDate;
    _birthDateController.text = profile.birthDate == null
        ? ''
        : _formatDate(profile.birthDate!);
    _addressController.text = profile.address;
    if (const {
      'senior',
      'caregiver',
      'family_member',
    }.contains(profile.userType)) {
      _userType = profile.userType;
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 60),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Select date of birth',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _birthDate = selected;
      _birthDateController.text = _formatDate(selected);
    });
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (!formIsValid || _userType.isEmpty) {
      if (_userType.isEmpty) {
        setState(() => _errorMessage = 'Select how you use EverCare.');
      }
      return;
    }
    final client = _client;
    final current = _profile;
    if (client == null || current == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ProfileRepository(client).save(
        current.copyWith(
          fullName: _fullNameController.text,
          phoneNumber: _phoneController.text,
          birthDate: _birthDate,
          userType: _userType,
          address: _addressController.text,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile changes saved.')));
      Navigator.pop(context, true);
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Your profile could not be saved. Check your connection and retry.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailPage(title: 'Personal Information', child: _buildContent());
  }

  Widget _buildContent() {
    final client = _client;
    if (client == null) {
      return const _EditProfileNotice(
        icon: Icons.cloud_off_outlined,
        title: 'Account data unavailable',
        message:
            'This screen is not connected to the configured Supabase project.',
      );
    }
    if (client.auth.currentUser == null) {
      return const _EditProfileNotice(
        icon: Icons.person_off_outlined,
        title: 'You are signed out',
        message: 'Log in again before editing your personal information.',
      );
    }

    return FutureBuilder<UserProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 90),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _EditProfileNotice(
            icon: Icons.sync_problem_outlined,
            title: 'Profile could not be loaded',
            message:
                'Check your connection and confirm the EverCare database setup.',
            actionLabel: 'Try Again',
            onAction: () {
              setState(() {
                _profile = null;
                _profileFuture = ProfileRepository(
                  client,
                ).fetchCurrentProfile();
              });
            },
          );
        }

        _populate(snapshot.data!);
        return _buildForm(snapshot.data!);
      },
    );
  }

  Widget _buildForm(UserProfile profile) {
    const userTypes = <String, String>{
      'senior': 'Senior',
      'caregiver': 'Caregiver',
      'family_member': 'Family Member',
    };
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.lightGreen,
            child: profile.initials.isEmpty
                ? const Icon(
                    Icons.person_outline_rounded,
                    size: 42,
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
          const SizedBox(height: 10),
          Text(
            'Profile photos are not enabled yet.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Full name',
            icon: Icons.person_outline_rounded,
            controller: _fullNameController,
            validator: (value) => validateRequiredText(value, 'Full name'),
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            enabled: !_isSaving,
          ),
          AppTextField(
            label: 'Account email',
            icon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
            enabled: !_isSaving,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 14),
              child: Text(
                'Account email changes require a separate verified flow.',
                style: AppTextStyles.small,
              ),
            ),
          ),
          AppTextField(
            label: 'Phone number',
            icon: Icons.phone_outlined,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            enabled: !_isSaving,
          ),
          AppTextField(
            label: 'Date of birth',
            icon: Icons.cake_outlined,
            hint: 'Select your date of birth',
            controller: _birthDateController,
            readOnly: true,
            onTap: _isSaving ? null : _pickBirthDate,
            suffix: const Icon(Icons.calendar_month_outlined),
            enabled: !_isSaving,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('I am a', style: AppTextStyles.cardTitle),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: userTypes.entries
                  .map(
                    (entry) => ChoiceChip(
                      label: Text(entry.value),
                      selected: _userType == entry.key,
                      selectedColor: AppColors.lightGreen,
                      onSelected: _isSaving
                          ? null
                          : (_) => setState(() => _userType = entry.key),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Address',
            icon: Icons.home_outlined,
            controller: _addressController,
            maxLines: 2,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.newline,
            autofillHints: const [AutofillHints.fullStreetAddress],
            enabled: !_isSaving,
          ),
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(_errorMessage!, style: AppTextStyles.bodyMuted),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 4),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            )
          else
            PrimaryButton(
              label: 'Save Changes',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }
}

class _EditProfileNotice extends StatelessWidget {
  const _EditProfileNotice({
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
            style: AppTextStyles.cardTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
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
