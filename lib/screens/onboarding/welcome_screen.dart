import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../authentication/auth_background.dart';
import 'intro_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const IntroBrand(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => IntroEntrance(
                        child: SingleChildScrollView(
                          key: const ValueKey('welcome-content-scroll'),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: (constraints.maxHeight - 28).clamp(
                                0,
                                double.infinity,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IntroIllustration(
                                  assetPath:
                                      'assets/images/onboarding/care_at_home.png',
                                  semanticLabel:
                                      'A caregiver offering warm support to an older adult at home',
                                  height: (constraints.maxHeight * .53).clamp(
                                    150,
                                    310,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'Health support that feels close to home',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.pageTitle.copyWith(
                                      color: AppColors.darkGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Keep blood-pressure readings, medicines, appointments, and family support together in one simple place.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IntroActionSurface(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PrimaryButton(
                          label: 'Get Started',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.onboarding,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.login),
                          child: const Text('Log In'),
                        ),
                      ],
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
