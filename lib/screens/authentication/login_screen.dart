import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/primary_button.dart';
import 'auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
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
      await AuthService(client).signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
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
              'EverCare could not reach the account service. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AuthPage(
        title: 'Welcome back',
        subtitle: 'Log in to continue caring for your health.',
        children: [
          AppTextField(
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            controller: _emailController,
            validator: validateEmailAddress,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            enabled: !_isSubmitting,
          ),
          AppTextField(
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            controller: _passwordController,
            validator: (value) => validateRequiredText(value, 'Password'),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            enabled: !_isSubmitting,
            onFieldSubmitted: (_) => _logIn(),
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () =>
                        Navigator.pushNamed(context, AppRoutes.forgotPassword),
              child: const Text('Forgot password?'),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 6),
            _AuthError(message: _errorMessage!),
          ],
          const SizedBox(height: 20),
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            )
          else
            PrimaryButton(
              label: 'Log In',
              icon: Icons.login_rounded,
              onPressed: _logIn,
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
            onPressed: _isSubmitting
                ? null
                : () => Navigator.pushNamed(context, AppRoutes.registration),
            child: const Text('Create an Account'),
          ),
        ],
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(message, style: AppTextStyles.bodyMuted)),
        ],
      ),
    );
  }
}
