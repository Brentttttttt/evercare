import 'package:flutter/widgets.dart';

import '../services/accessibility_settings_controller.dart';

/// Makes the app-owned accessibility preferences available to every route.
class EverCareAccessibilityScope
    extends InheritedNotifier<AccessibilitySettingsController> {
  const EverCareAccessibilityScope({
    required AccessibilitySettingsController settings,
    required super.child,
    super.key,
  }) : super(notifier: settings);

  static AccessibilitySettingsController? maybeWatch(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<EverCareAccessibilityScope>()
        ?.notifier;
  }

  static AccessibilitySettingsController watch(BuildContext context) {
    final settings = maybeWatch(context);
    assert(
      settings != null,
      'EverCareAccessibilityScope is missing above this route.',
    );
    return settings!;
  }

  static AccessibilitySettingsController? maybeRead(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<EverCareAccessibilityScope>();
    return (element?.widget as EverCareAccessibilityScope?)?.notifier;
  }
}

/// Applies EverCare's saved preferences while preserving the platform's own
/// accessibility choices, including the system reduced-motion setting.
class EverCareAccessibilityMediaQuery extends StatelessWidget {
  const EverCareAccessibilityMediaQuery({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final settings = EverCareAccessibilityScope.watch(context);
    final mediaQuery = MediaQuery.of(context);
    final textScaler = settings.textScaleMultiplier == 1
        ? mediaQuery.textScaler
        : _CombinedTextScaler(
            base: mediaQuery.textScaler,
            multiplier: settings.textScaleMultiplier,
          );

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: textScaler,
        disableAnimations:
            mediaQuery.disableAnimations || settings.reduceMotion,
      ),
      child: child,
    );
  }
}

/// Keeps non-linear platform text scaling intact while adding EverCare's
/// optional, app-wide size preference.
class _CombinedTextScaler extends TextScaler {
  const _CombinedTextScaler({required this.base, required this.multiplier});

  final TextScaler base;
  final double multiplier;

  @override
  double scale(double fontSize) => base.scale(fontSize) * multiplier;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) {
    return other is _CombinedTextScaler &&
        other.base == base &&
        other.multiplier == multiplier;
  }

  @override
  int get hashCode => Object.hash(base, multiplier);
}
