import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../widgets/app_header.dart';

/// The brand stays outside the scroll view, just as it does on the auth pages.
class IntroBrand extends StatelessWidget {
  const IntroBrand({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('intro-fixed-brand'),
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Row(
        children: [
          const EverCareLogo(size: 42, showWordmark: false),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // This is a wordmark, not form text. Fitting only the brand
                  // keeps it intact when larger accessibility text is enabled.
                  const SizedBox(
                    height: 29,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'EverCare',
                        style: TextStyle(
                          fontSize: 26,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.7,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 18,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Care, made simpler',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          color: AppColors.darkGreen.withValues(alpha: .85),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Whole watercolor compositions are retained; faces are never cover-cropped.
class IntroIllustration extends StatelessWidget {
  const IntroIllustration({
    required this.assetPath,
    required this.semanticLabel,
    required this.height,
    super.key,
  });

  final String assetPath;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border.withValues(alpha: .75)),
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          cacheWidth: 1000,
          semanticLabel: semanticLabel,
          filterQuality: FilterQuality.medium,
          // Keep the introduction readable if an asset fails to decode.
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        ),
      ),
    );
  }
}

class IntroActionSurface extends StatelessWidget {
  const IntroActionSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7).withValues(alpha: .97),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: .55)),
        ),
      ),
      child: child,
    );
  }
}

/// A single, quiet reveal on entry; no looping motion around reading content.
class IntroEntrance extends StatelessWidget {
  const IntroEntrance({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: AppMotion.emphasizedCurve,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
