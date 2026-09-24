import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:evercare/routes/app_routes.dart';
import 'package:evercare/screens/authentication/auth_background.dart';
import 'package:evercare/screens/onboarding/intro_widgets.dart';
import 'package:evercare/screens/onboarding/onboarding_screen.dart';
import 'package:evercare/screens/onboarding/welcome_screen.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:evercare/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

const _assets = [
  'assets/images/onboarding/care_at_home.png',
  'assets/images/onboarding/daily_care.png',
  'assets/images/onboarding/connected_care.png',
  'assets/images/onboarding/safety_support.png',
];

Future<void> _pumpIntro(
  WidgetTester tester, {
  Widget screen = const OnboardingScreen(),
  Size size = const Size(390, 844),
  double scale = 1,
  bool reduceMotion = false,
  GlobalKey? boundaryKey,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundaryKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: const bool.fromEnvironment('CAPTURE_EVERCARE_UI')
            ? _reviewTheme()
            : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: screen,
        routes: {
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.login: (_) => const Scaffold(body: Text('Existing login')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_EVERCARE_UI')) {
      const fontPath = String.fromEnvironment('UI_REVIEW_FONT');
      if (fontPath.isNotEmpty) {
        final font = FontLoader('Roboto')
          ..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView));
        await font.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });

  test('all four watercolor illustrations are bundled as PNG assets', () async {
    for (final asset in _assets) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(100));
      expect(bytes.buffer.asUint8List(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    }
  });

  testWidgets('welcome uses the shared auth background and home illustration', (
    tester,
  ) async {
    await _pumpIntro(tester, screen: const WelcomeScreen());
    expect(find.byType(AuthBackground), findsOneWidget);
    expect(find.text('Care, made simpler'), findsOneWidget);
    expect(
      tester
          .widget<IntroIllustration>(find.byType(IntroIllustration))
          .assetPath,
      _assets.first,
    );
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(IntroIllustration),
        matching: find.byType(Image),
      ),
    );
    expect(image.fit, BoxFit.contain);
    expect(
      tester.getSize(find.widgetWithText(TextButton, 'Log In')).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome Get Started opens existing onboarding route', (
    tester,
  ) async {
    await _pumpIntro(tester, screen: const WelcomeScreen());
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome Log In opens existing login route', (tester) async {
    await _pumpIntro(tester, screen: const WelcomeScreen());
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(find.text('Existing login'), findsOneWidget);
  });

  testWidgets('three care pages advance and finish at existing login', (
    tester,
  ) async {
    await _pumpIntro(tester);
    expect(find.byType(AuthBackground), findsOneWidget);
    expect(find.text('Manage Your Daily Care'), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('onboarding-progress')))
          .properties
          .label,
      'Introduction, page 1 of 3',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(
      find.text('Stay Connected with Family').hitTestable(),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Semantics>(find.byKey(const ValueKey('onboarding-progress')))
          .properties
          .label,
      'Introduction, page 2 of 3',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Feel Safer Every Day').hitTestable(), findsOneWidget);
    expect(find.text('Get Started').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Existing login'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skip preserves navigation to existing login', (tester) async {
    await _pumpIntro(tester);
    expect(
      tester.getSize(find.widgetWithText(TextButton, 'Skip')).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Existing login'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('horizontal swipes update the page and accessible progress', (
    tester,
  ) async {
    await _pumpIntro(tester);
    await tester.drag(
      find.byKey(const ValueKey('onboarding-pages')),
      const Offset(-350, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Stay Connected with Family').hitTestable(),
      findsOneWidget,
    );
    final progress = tester.widget<Semantics>(
      find.byKey(const ValueKey('onboarding-progress')),
    );
    expect(progress.properties.liveRegion, isTrue);
    expect(progress.properties.label, 'Introduction, page 2 of 3');
    await tester.drag(
      find.byKey(const ValueKey('onboarding-pages')),
      const Offset(350, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Manage Your Daily Care').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Next has a gentle transition and prevents repeated taps', (
    tester,
  ) async {
    await _pumpIntro(tester);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 120));
    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    expect(controller.page, greaterThan(0));
    expect(controller.page, lessThan(1));
    await tester.pumpAndSettle();
    expect(controller.page, 1);
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion switches pages without animated travel', (
    tester,
  ) async {
    await _pumpIntro(tester, reduceMotion: true);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(tester.widget<PageView>(find.byType(PageView)).controller!.page, 1);
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNotNull,
    );
    final indicators = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('onboarding-progress')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(indicators.every((item) => item.duration == Duration.zero), isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in [
    (name: 'small phone', size: const Size(320, 480), scale: 1.0),
    (name: 'large text', size: const Size(320, 568), scale: 3.0),
    (name: 'landscape', size: const Size(640, 320), scale: 1.0),
    (name: 'landscape large text', size: const Size(640, 320), scale: 3.0),
  ]) {
    for (final welcome in [true, false]) {
      testWidgets(
        '${welcome ? 'welcome' : 'onboarding'} stays usable on ${scenario.name}',
        (tester) async {
          await _pumpIntro(
            tester,
            screen: welcome ? const WelcomeScreen() : const OnboardingScreen(),
            size: scenario.size,
            scale: scenario.scale,
          );
          final brand = find.byKey(const ValueKey('intro-fixed-brand'));
          final before = tester.getRect(brand);
          final scroll = find.byKey(
            ValueKey(
              welcome ? 'welcome-content-scroll' : 'intro-slide-scroll-0',
            ),
          );
          expect(tester.getSize(scroll).height, greaterThan(0));
          await tester.drag(scroll, const Offset(0, -500));
          await tester.pumpAndSettle();
          expect(tester.getRect(brand), before);
          expect(find.text('EverCare').hitTestable(), findsOneWidget);
          expect(find.text('Care, made simpler').hitTestable(), findsOneWidget);
          expect(
            find.text(welcome ? 'Get Started' : 'Next').hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  if (const bool.fromEnvironment('CAPTURE_EVERCARE_UI')) {
    for (final page in [
      'welcome',
      'daily-care',
      'connected-care',
      'safety-support',
    ]) {
      testWidgets('visual capture introduction $page', (tester) async {
        final boundaryKey = GlobalKey();
        await _pumpIntro(
          tester,
          screen: page == 'welcome'
              ? const WelcomeScreen()
              : const OnboardingScreen(),
          boundaryKey: boundaryKey,
        );
        final advances = switch (page) {
          'connected-care' => 1,
          'safety-support' => 2,
          _ => 0,
        };
        for (var i = 0; i < advances; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 180)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('tmp/ui-review/intro-$page.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}

ThemeData _reviewTheme() {
  final base = AppTheme.light;
  TextStyle label(ButtonStyle? style) =>
      (style?.textStyle?.resolve({}) ?? const TextStyle()).copyWith(
        fontFamily: 'Roboto',
      );
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(label(base.filledButtonTheme.style)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(label(base.textButtonTheme.style)),
      ),
    ),
  );
}
