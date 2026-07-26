import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import 'auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = true;

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Welcome back',
      subtitle: 'Log in to continue caring for your health.',
      children: [
        const MockTextField(
          label: 'Email address',
          hint: 'maria.santos@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const MockTextField(
          label: 'Password',
          hint: 'Enter your password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          suffix: Icon(Icons.visibility_off_outlined),
        ),
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) =>
                  setState(() => _rememberMe = value ?? false),
            ),
            const Expanded(
              child: Text('Remember me', style: AppTextStyles.body),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.forgotPassword),
              child: const Text('Forgot password?'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Log In',
          icon: Icons.login_rounded,
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('New to EverCare?', style: AppTextStyles.bodyMuted),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.registration),
          child: const Text('Create an Account'),
        ),
      ],
    );
  }
}
