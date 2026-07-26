import 'package:flutter/material.dart';

import '../../widgets/app_page.dart';
import '../../widgets/primary_button.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Reset your password',
      subtitle:
          'Enter your email and we’ll show a confirmation for a sample reset link.',
      children: [
        const MockTextField(
          label: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Send Reset Link',
          icon: Icons.mark_email_read_outlined,
          onPressed: () => showMockDialog(
            context,
            title: 'Reset link ready',
            message:
                'A password reset link would be sent to your email. This UI prototype has not sent a real message.',
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Return to Login'),
        ),
      ],
    );
  }
}
