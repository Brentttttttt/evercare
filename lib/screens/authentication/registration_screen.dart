import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import 'auth_widgets.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String _userType = 'Senior';

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Create your account',
      subtitle:
          'Tell us a little about yourself to personalize the experience.',
      children: [
        const MockTextField(
          label: 'Full name',
          icon: Icons.person_outline_rounded,
        ),
        const MockTextField(
          label: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const MockTextField(
          label: 'Phone number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const MockTextField(
          label: 'Date of birth',
          icon: Icons.cake_outlined,
          hint: 'Month / Day / Year',
        ),
        const Text('I am a', style: AppTextStyles.cardTitle),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Senior', 'Caregiver', 'Family Member']
              .map(
                (type) => ChoiceChip(
                  label: Text(type),
                  selected: _userType == type,
                  selectedColor: AppColors.lightGreen,
                  onSelected: (_) => setState(() => _userType = type),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        const MockTextField(
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
        ),
        const MockTextField(
          label: 'Confirm password',
          icon: Icons.lock_reset_rounded,
          obscureText: true,
        ),
        const SizedBox(height: 6),
        PrimaryButton(
          label: 'Create Account',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Already have an account? Log In'),
          ),
        ),
      ],
    );
  }
}
