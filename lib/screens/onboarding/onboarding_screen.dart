import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../authentication/auth_background.dart';
import 'intro_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _transitioning = false;

  static const _pages = [
    (
      title: 'Manage Your Daily Care',
      description:
          'Keep blood-pressure records, medications, and appointments organized in one accessible place.',
      asset: 'assets/images/onboarding/daily_care.png',
      illustration:
          'An older adult and caregiver organizing medicines and a daily care routine',
    ),
    (
      title: 'Stay Connected with Family',
      description:
          'Allow trusted caregivers and family members to view shared blood-pressure, medication, and appointment information.',
      asset: 'assets/images/onboarding/connected_care.png',
      illustration: 'An older adult sharing a warm moment with family',
    ),
    (
      title: 'Feel Safer Every Day',
      description:
          'Keep emergency contacts and important medical information easy to access.',
      asset: 'assets/images/onboarding/safety_support.png',
      illustration:
          'A reassuring caregiver beside an older adult with everyday safety support',
    ),
  ];

  void _finish() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Future<void> _next() async {
    if (_transitioning) return;
    if (_index == _pages.length - 1) {
      _finish();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(_index + 1);
      return;
    }
    setState(() => _transitioning = true);
    await _controller.animateToPage(
      _index + 1,
      duration: AppMotion.page,
      curve: Curves.easeInOutCubic,
    );
    if (mounted) setState(() => _transitioning = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  IntroBrand(
                    trailing: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _finish,
                      child: const Text('Skip'),
                    ),
                  ),
                  Expanded(
                    child: IntroEntrance(
                      child: PageView.builder(
                        key: const ValueKey('onboarding-pages'),
                        controller: _controller,
                        itemCount: _pages.length,
                        onPageChanged: (value) =>
                            setState(() => _index = value),
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          return AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final position =
                                  _controller.hasClients &&
                                      _controller.position.hasContentDimensions
                                  ? _controller.page ?? _index.toDouble()
                                  : _index.toDouble();
                              final distance = reduceMotion
                                  ? 0.0
                                  : (position - index).abs().clamp(0.0, 1.0);
                              return Opacity(
                                opacity: 1 - distance * .25,
                                child: Transform.translate(
                                  offset: Offset(0, distance * 8),
                                  child: child,
                                ),
                              );
                            },
                            child: _IntroSlide(
                              index: index,
                              title: page.title,
                              description: page.description,
                              asset: page.asset,
                              illustration: page.illustration,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  IntroActionSurface(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          key: const ValueKey('onboarding-progress'),
                          liveRegion: true,
                          label:
                              'Introduction, page ${_index + 1} of ${_pages.length}',
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _pages.length,
                                (index) => AnimatedContainer(
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : AppMotion.standard,
                                  curve: AppMotion.emphasizedCurve,
                                  width: index == _index ? 28 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index == _index
                                        ? AppColors.primaryGreen
                                        : const Color(0xFFB5C9BB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          label: _index == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _transitioning ? null : _next,
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

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.index,
    required this.title,
    required this.description,
    required this.asset,
    required this.illustration,
  });

  final int index;
  final String title;
  final String description;
  final String asset;
  final String illustration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: ValueKey('intro-slide-scroll-$index'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 32).clamp(0, double.infinity),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IntroIllustration(
                assetPath: asset,
                semanticLabel: illustration,
                height: (constraints.maxHeight * .53).clamp(150, 310),
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle.copyWith(
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
