import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    (
      title: 'Manage Your Daily Care',
      description:
          'Keep blood-pressure records, medications, and appointments organized in one accessible place.',
      icon: Icons.monitor_heart_outlined,
    ),
    (
      title: 'Stay Connected with Family',
      description:
          'Allow trusted caregivers and family members to view shared blood-pressure, medication, and appointment information.',
      icon: Icons.diversity_1_outlined,
    ),
    (
      title: 'Feel Safer Every Day',
      description:
          'Keep emergency contacts and important medical information easy to access.',
      icon: Icons.health_and_safety_outlined,
    ),
  ];

  void _finish() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 14),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            color: index == 1
                                ? AppColors.paleBlue
                                : AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(38),
                          ),
                          child: Icon(
                            page.icon,
                            size: 138,
                            color: index == 1
                                ? AppColors.blue
                                : AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 42),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.pageTitle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == _index ? 28 : 9,
                        height: 9,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _index
                              ? AppColors.primaryGreen
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      if (_index == _pages.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Text(
                      _index == _pages.length - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
