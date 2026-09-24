import 'package:flutter/material.dart';

/// Shared, non-interactive artwork behind the fixed brand and scrolling form.
class AuthBackground extends StatelessWidget {
  const AuthBackground({required this.child, super.key});

  final Widget child;
  static const assetPath = 'assets/images/auth_background.png';

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEDF4E8), Color(0xFFFFFDF7)],
      ),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                // Limit decoded memory on large displays. No runtime blur or
                // animation is necessary for this quiet, decorative layer.
                cacheWidth: 1024,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        child,
      ],
    ),
  );
}
