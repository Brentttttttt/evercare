import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const quick = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 240);
  static const page = Duration(milliseconds: 340);
  static const emphasizedCurve = Curves.easeOutCubic;
}

class EverCarePageTransitionsBuilder extends PageTransitionsBuilder {
  const EverCarePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasizedCurve,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: .12, end: 1).animate(curvedAnimation),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.055, .012),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: ScaleTransition(
          scale: Tween<double>(begin: .985, end: 1).animate(curvedAnimation),
          child: child,
        ),
      ),
    );
  }
}

class EverCarePageRoute<T> extends MaterialPageRoute<T> {
  EverCarePageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  Duration get reverseTransitionDuration => AppMotion.standard;
}

class PressScale extends StatefulWidget {
  const PressScale({
    required this.child,
    super.key,
    this.enabled = true,
    this.pressedScale = .975,
    this.hoverScale = 1.008,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;
  final double hoverScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final scale = reduceMotion || !widget.enabled
        ? 1.0
        : _pressed
        ? widget.pressedScale
        : _hovered
        ? widget.hoverScale
        : 1.0;

    return MouseRegion(
      onEnter: widget.enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.enabled
          ? (_) => setState(() {
              _hovered = false;
              _pressed = false;
            })
          : null,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onPointerUp: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onPointerCancel: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        child: AnimatedScale(
          scale: scale,
          duration: reduceMotion ? Duration.zero : AppMotion.quick,
          curve: AppMotion.emphasizedCurve,
          child: widget.child,
        ),
      ),
    );
  }
}
