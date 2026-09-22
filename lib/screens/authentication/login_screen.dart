import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/primary_button.dart';
import 'auth_widgets.dart';
import 'google_auth_flow.dart';
import 'google_sign_in_section.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onGoogleSignIn});

  final GoogleSignInAction? onGoogleSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  String? _errorMessage;
  String? _googleErrorMessage;

  bool get _isBusy => _isSubmitting || _isGoogleSubmitting;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    if (_isBusy) return;
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
      _googleErrorMessage = null;
    });
    try {
      final auth = AuthService(client);
      await auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      bool needsProfileSetup;
      try {
        // Linked Google accounts need the same setup even when their owner
        // chooses a password. Ordinary email accounts do not query a profile.
        needsProfileSetup = await auth.needsGoogleProfileSetup();
      } catch (_) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Your EverCare profile could not be loaded. Check your connection and try again.';
          });
        }
        return;
      }
      if (!mounted) return;
      finishGoogleSignIn(
        context,
        needsProfileSetup
            ? GoogleAuthResult.needsProfileSetup
            : GoogleAuthResult.ready,
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

  Future<void> _continueWithGoogle() async {
    if (_isBusy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isGoogleSubmitting = true;
      _googleErrorMessage = null;
      _errorMessage = null;
    });
    try {
      final result = await startGoogleSignIn(
        context,
        signIn: widget.onGoogleSignIn,
      );
      if (mounted && result != null) finishGoogleSignIn(context, result);
    } catch (error) {
      if (mounted) {
        setState(() => _googleErrorMessage = googleSignInErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _isGoogleSubmitting = false);
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
            enabled: !_isBusy,
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
            enabled: !_isBusy,
            onFieldSubmitted: (_) => _logIn(),
            suffix: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: _isBusy
                  ? null
                  : () => setState(() => _obscurePassword = !_obscurePassword),
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
              onPressed: _isBusy
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
          PrimaryButton(
            label: 'Log In',
            loadingLabel: 'Logging In…',
            isLoading: _isSubmitting,
            icon: Icons.login_rounded,
            onPressed: _isBusy ? null : _logIn,
          ),
          const SizedBox(height: 20),
          GoogleSignInSection(
            onPressed: _isBusy ? null : _continueWithGoogle,
            isLoading: _isGoogleSubmitting,
            errorMessage: _googleErrorMessage,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'New to EverCare?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: _isBusy
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
