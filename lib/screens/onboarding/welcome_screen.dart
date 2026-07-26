import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 80,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const EverCareLogo(size: 62),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 34),
                  child: Container(
                    width: double.infinity,
                    height: 285,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF0FAF4), Color(0xFFE2F1E9)],
                      ),
                      borderRadius: BorderRadius.circular(38),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: -54,
                          top: -42,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: .10,
                                ),
                                width: 24,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 24,
                          right: 24,
                          child: _Bubble(
                            icon: Icons.favorite_outline_rounded,
                            size: 54,
                          ),
                        ),
                        Positioned(
                          bottom: 26,
                          left: 22,
                          child: _Bubble(
                            icon: Icons.medication_outlined,
                            size: 56,
                          ),
                        ),
                        Container(
                          width: 184,
                          height: 184,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(color: Colors.white),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 28,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.health_and_safety_rounded,
                                size: 82,
                                color: AppColors.primaryGreen,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Care made simple',
                                style: AppTextStyles.cardTitle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      'Health support that\nfeels close to home',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Keep blood-pressure readings, medicines, appointments, and family support together in one simple place.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 30),
                    PrimaryButton(
                      label: 'Get Started',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.onboarding),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.login),
                      child: const Text(
                        'I already have an account · Log In',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primaryGreen, size: size * .48),
    );
  }
}
