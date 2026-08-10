import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/primary_button.dart';
import 'auth_widgets.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _userType = 'senior';
  DateTime? _birthDate;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
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

  Future<void> _register() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final client = EverCareBackendScope.maybeClient(context);
    if (client == null) {
      setState(() {
        _errorMessage =
            'Account services are unavailable in this app environment.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final response = await AuthService(client).register(
        fullName: _fullNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text,
        birthDate: _birthDate,
        userType: _userType,
      );
      if (!mounted) return;

      if (response.session == null) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.primaryGreen,
            ),
            title: const Text('Confirm your email'),
            content: Text(
              'We sent a confirmation link to ${_emailController.text.trim()}. '
              'Open it before logging in to EverCare.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } on AuthException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'EverCare could not create the account. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const userTypes = <String, String>{
      'senior': 'Senior',
      'caregiver': 'Caregiver',
      'family_member': 'Family Member',
    };
    return Form(
      key: _formKey,
      child: AuthPage(
        title: 'Create your account',
        subtitle:
            'Tell us a little about yourself to personalize the experience.',
        children: [
          const _RegistrationSection(
            icon: Icons.person_outline_rounded,
            title: 'About you',
            description: 'Your basic profile and role in care.',
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Full name',
            icon: Icons.person_outline_rounded,
            controller: _fullNameController,
            validator: (value) => validateRequiredText(value, 'Full name'),
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            enabled: !_isSubmitting,
          ),
          AppTextField(
            label: 'Email address',
            icon: Icons.email_outlined,
            controller: _emailController,
            validator: validateEmailAddress,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            enabled: !_isSubmitting,
          ),
          AppTextField(
            label: 'Phone number',
            icon: Icons.phone_outlined,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            enabled: !_isSubmitting,
          ),
          AppTextField(
            label: 'Date of birth',
            icon: Icons.cake_outlined,
            hint: 'Select your date of birth',
            controller: _birthDateController,
            readOnly: true,
            onTap: _isSubmitting ? null : _pickBirthDate,
            validator: (_) =>
                _birthDate == null ? 'Select your date of birth.' : null,
            suffix: const Icon(Icons.calendar_month_outlined),
            enabled: !_isSubmitting,
          ),
          const Text('I am a', style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: userTypes.entries
                .map(
                  (entry) => ChoiceChip(
                    label: Text(entry.value),
                    selected: _userType == entry.key,
                    selectedColor: AppColors.lightGreen,
                    onSelected: _isSubmitting
                        ? null
                        : (_) => setState(() => _userType = entry.key),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 22),
          const _RegistrationSection(
            icon: Icons.shield_outlined,
            title: 'Account security',
            description: 'Use at least 8 characters for your password.',
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            enabled: !_isSubmitting,
            validator: (value) {
              final requiredMessage = validateRequiredText(value, 'Password');
              if (requiredMessage != null) return requiredMessage;
              if (value!.length < 8) {
                return 'Use at least 8 characters.';
              }
              return null;
            },
            suffix: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          AppTextField(
            label: 'Confirm password',
            icon: Icons.lock_reset_rounded,
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmation,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            enabled: !_isSubmitting,
            onFieldSubmitted: (_) => _register(),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match.';
              }
              return validateRequiredText(value, 'Password confirmation');
            },
            suffix: IconButton(
              tooltip: _obscureConfirmation
                  ? 'Show confirmation'
                  : 'Hide confirmation',
              onPressed: () =>
                  setState(() => _obscureConfirmation = !_obscureConfirmation),
              icon: Icon(
                _obscureConfirmation
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            _RegistrationError(message: _errorMessage!),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 6),
          PrimaryButton(
            label: 'Create Account',
            loadingLabel: 'Creating Account…',
            isLoading: _isSubmitting,
            icon: Icons.arrow_forward_rounded,
            onPressed: _register,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Already have an account? Log In'),
            ),
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

class _RegistrationSection extends StatelessWidget {
  const _RegistrationSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.darkGreen),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.cardTitle),
              const SizedBox(height: 2),
              Text(description, style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegistrationError extends StatelessWidget {
  const _RegistrationError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: .25)),
      ),
      child: Text(message, style: AppTextStyles.bodyMuted),
    );
  }
}
