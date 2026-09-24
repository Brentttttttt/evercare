import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../models/profile_photo.dart';
import '../../repositories/profile_repository.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/profile_photo_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/primary_button.dart';
import '../authentication/auth_widgets.dart';
import 'profile_photo_card.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.requireSetup = false,
    this.photoPicker,
  });

  final bool requireSetup;
  final ProfilePhotoPicker? photoPicker;

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
  String? _photoError;
  ProfilePhotoUpload? _pendingPhoto;
  bool _isPickingPhoto = false;
  int _pickGeneration = 0;
  bool get _isBusy => _isSaving || _isPickingPhoto;
  late final ProfilePhotoPicker _photoPicker =
      widget.photoPicker ??
      DeviceProfilePhotoPicker(
        currentUserId: () => _client?.auth.currentUser?.id,
      );

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
    if (nextClient?.auth.currentUser case final user?) {
      unawaited(_recoverPhoto(user.id));
    }
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
    if (_isBusy) return;
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
        photo: _pendingPhoto,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile changes saved.')));
      if (widget.requireSetup) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (_) => false,
        );
      } else {
        Navigator.pop(context, true);
      }
    } on ProfilePhotoFailure catch (error) {
      if (mounted) setState(() => _photoError = error.message);
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
    return PopScope(
      canPop: !widget.requireSetup && !_isBusy,
      child: DetailPage(
        title: widget.requireSetup ? 'Complete your profile' : 'Edit Profile',
        child: Column(
          children: [
            if (widget.requireSetup) ...[
              const AppCard(
                color: AppColors.accent,
                child: Text(
                  'Welcome to EverCare. Add your date of birth and choose how you use the app. A profile photo is optional.',
                  style: AppTextStyles.body,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isBusy ? null : _signOut,
                child: const Text('Use a different account'),
              ),
              const SizedBox(height: 12),
            ],
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    if (_isBusy) return;
    final client = _client;
    if (client == null) return;
    setState(() => _isSaving = true);
    try {
      await AuthService(client).signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not sign out. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _recoverPhoto(String userId) async {
    final generation = ++_pickGeneration;
    // Recovery can now open an interactive cropper. Keep other picker/save
    // actions disabled until it returns, just like a fresh selection.
    _isPickingPhoto = true;
    try {
      final photo = await _photoPicker.recoverLostPhoto();
      if (!mounted ||
          generation != _pickGeneration ||
          _client?.auth.currentUser?.id != userId ||
          photo == null) {
        return;
      }
      setState(() => _pendingPhoto = photo);
    } on ProfilePhotoFailure catch (error) {
      if (mounted &&
          generation == _pickGeneration &&
          _client?.auth.currentUser?.id == userId) {
        setState(() => _photoError = error.message);
      }
    } catch (_) {
      // A missing recovered selection must not prevent profile completion.
    } finally {
      if (mounted && generation == _pickGeneration) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _choosePhoto() async {
    if (_isBusy) return;
    final userId = _client?.auth.currentUser?.id;
    if (userId == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final source = await showModalBottomSheet<ProfilePhotoSource>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your profile photo',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a picture, adjust the crop, then check your preview before saving.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 16),
              ListTile(
                minTileHeight: 64,
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () =>
                    Navigator.pop(sheetContext, ProfilePhotoSource.gallery),
              ),
              if (!kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS))
                ListTile(
                  minTileHeight: 64,
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Take Photo'),
                  onTap: () =>
                      Navigator.pop(sheetContext, ProfilePhotoSource.camera),
                ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || source == null || _client?.auth.currentUser?.id != userId) {
      return;
    }
    _pickGeneration++;
    setState(() {
      _isPickingPhoto = true;
      _photoError = null;
    });
    try {
      final photo = await _photoPicker.pick(source);
      if (!mounted ||
          _client?.auth.currentUser?.id != userId ||
          photo == null) {
        return;
      }
      setState(() => _pendingPhoto = photo);
    } on ProfilePhotoFailure catch (error) {
      if (mounted) setState(() => _photoError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _photoError =
              'The photo could not be selected. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfilePhotoCard(
            profile: profile,
            preview: _pendingPhoto?.bytes,
            busy: _isBusy,
            error: _photoError,
            onChoose: _choosePhoto,
            onDiscard: () => setState(() {
              _pendingPhoto = null;
              _photoError = null;
            }),
          ),
          const SizedBox(height: 20),
          ProfileFormSection(
            title: 'About you',
            description: 'The details that make your care more personal.',
            icon: Icons.person_outline_rounded,
            children: [
              AppTextField(
                label: 'Full name',
                icon: Icons.person_outline_rounded,
                controller: _fullNameController,
                validator: (value) => validateRequiredText(value, 'Full name'),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                enabled: !_isBusy,
              ),
              AppTextField(
                label: 'Date of birth',
                icon: Icons.cake_outlined,
                hint: 'Select your date of birth',
                controller: _birthDateController,
                validator: (_) => widget.requireSetup && _birthDate == null
                    ? 'Select your date of birth.'
                    : null,
                readOnly: true,
                onTap: _isBusy ? null : _pickBirthDate,
                suffix: const Icon(Icons.calendar_month_outlined),
                enabled: !_isBusy,
              ),
              const Text(
                'How do you use EverCare?',
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in userTypes.entries)
                    AuthRoleOption(
                      label: entry.value,
                      selected: _userType == entry.key,
                      description: switch (entry.key) {
                        'senior' => 'Manage my health and daily care',
                        'caregiver' => 'Support someone with their care',
                        _ => 'Stay involved in a loved one’s wellbeing',
                      },
                      onSelected: _isBusy
                          ? null
                          : () => setState(() => _userType = entry.key),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ProfileFormSection(
            title: 'Contact details',
            description: 'Keep your information up to date.',
            icon: Icons.contact_page_outlined,
            children: [
              AppTextField(
                label: 'Account email',
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
                enabled: !_isBusy,
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Your sign-in email is protected. Changing it requires a separate verification.',
                  style: AppTextStyles.bodyMuted,
                ),
              ),
              AppTextField(
                label: 'Phone number',
                hint: 'Optional',
                icon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                enabled: !_isBusy,
              ),
              AppTextField(
                label: 'Address',
                hint: 'Optional',
                icon: Icons.home_outlined,
                controller: _addressController,
                maxLines: 2,
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.newline,
                autofillHints: const [AutofillHints.fullStreetAddress],
                enabled: !_isBusy,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null) ...[
            Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.destructiveContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.destructiveContainerForeground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          PrimaryButton(
            label: widget.requireSetup ? 'Save and Continue' : 'Save Changes',
            loadingLabel: _pendingPhoto == null
                ? 'Saving changes…'
                : 'Saving photo & profile…',
            isLoading: _isSaving,
            icon: Icons.check_rounded,
            onPressed: _isBusy ? null : _save,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your changes are saved securely to your EverCare account.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
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
