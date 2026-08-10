import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_page.dart';

/// A quiet loading placeholder inspired by shadcn's skeleton primitive.
///
/// The pulse is disabled automatically when reduced motion is requested.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: .46,
    end: .84,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  bool? _animationsDisabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled == animationsDisabled) return;
    _animationsDisabled = animationsDisabled;
    if (animationsDisabled) {
      _controller
        ..stop()
        ..value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}

/// A reusable card-shaped placeholder for data-driven pages.
class AppCardSkeleton extends StatelessWidget {
  const AppCardSkeleton({super.key, this.showLeading = true, this.lines = 2})
    : assert(lines > 0);

  final bool showLeading;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading content',
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLeading) ...[
              const AppSkeleton(width: 48, height: 48, borderRadius: 12),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  lines,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 3 : 0,
                      bottom: index == lines - 1 ? 0 : 11,
                    ),
                    child: AppSkeleton(
                      width: index == 0 ? double.infinity : 190,
                      height: index == 0 ? 16 : 13,
                      borderRadius: 6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
