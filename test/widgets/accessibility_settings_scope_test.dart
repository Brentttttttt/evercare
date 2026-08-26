import 'package:evercare/services/accessibility_settings_controller.dart';
import 'package:evercare/widgets/accessibility_settings_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'keeps device scaling and applies saved text size and reduced motion',
    (tester) async {
      final settings = AccessibilitySettingsController();
      addTearDown(settings.dispose);
      await settings.setTextSize(EverCareTextSize.large);
      await settings.setReduceMotion(true);

      late MediaQueryData observed;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.2),
              disableAnimations: false,
            ),
            child: EverCareAccessibilityScope(
              settings: settings,
              child: EverCareAccessibilityMediaQuery(
                child: Builder(
                  builder: (context) {
                    observed = MediaQuery.of(context);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(observed.textScaler.scale(10), closeTo(13.8, .001));
      expect(observed.disableAnimations, isTrue);
    },
  );

  testWidgets('keeps the platform reduced-motion preference enabled', (
    tester,
  ) async {
    final settings = AccessibilitySettingsController();
    addTearDown(settings.dispose);

    late bool animationsDisabled;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: EverCareAccessibilityScope(
            settings: settings,
            child: EverCareAccessibilityMediaQuery(
              child: Builder(
                builder: (context) {
                  animationsDisabled = MediaQuery.disableAnimationsOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(animationsDisabled, isTrue);
  });
}
