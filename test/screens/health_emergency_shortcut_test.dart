import 'package:evercare/routes/app_route_observer.dart';
import 'package:evercare/routes/app_routes.dart';
import 'package:evercare/screens/emergency/emergency_screen.dart';
import 'package:evercare/screens/health/health_overview_screen.dart';
import 'package:evercare/screens/home/main_shell.dart';
import 'package:evercare/services/bp_monitor_ble_service.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:evercare/widgets/app_bottom_navigation.dart';
import 'package:evercare/widgets/bp_monitor_ble_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _emergencyButton = Key('bp-emergency-button');
const _statusIndicator = Key('bp-status-indicator');

class _RouteObserver extends NavigatorObserver {
  final List<String?> pushedNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

Future<void> _pumpReading(
  WidgetTester tester, {
  int systolic = 123,
  int diastolic = 96,
  Size size = const Size(390, 844),
  double textScale = 1,
  NavigatorObserver? observer,
  bool inMainShell = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final service = BpMonitorBleService();
  addTearDown(service.close);
  // The monitor packet's upper number includes the existing +10 offset.
  service.processNotificationForTesting([
    0x81,
    systolic + 10,
    diastolic,
    77,
    0,
    0,
    0,
    0,
  ], receivedAt: DateTime(2026, 9, 21, 10));
  await tester.pumpWidget(
    BpMonitorBleScope(
      service: service,
      child: MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        navigatorObservers: [everCareRouteObserver, ?observer],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: inMainShell
            ? const MainShell(initialIndex: 1)
            : const Scaffold(body: SafeArea(child: HealthOverviewScreen())),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  for (final size in [
    const Size(320, 700),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('Needs Attention keeps Emergency to its right at $size', (
      tester,
    ) async {
      await _pumpReading(tester, size: size);

      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('123 / 96 mmHg'), findsOneWidget);
      final button = find.byKey(_emergencyButton);
      final indicatorRect = tester.getRect(find.byKey(_statusIndicator));
      final buttonRect = tester.getRect(button);
      expect(buttonRect.left, greaterThan(indicatorRect.right));
      expect(buttonRect.right, lessThanOrEqualTo(size.width - 20));
      expect(buttonRect.width, greaterThanOrEqualTo(48));
      expect(buttonRect.height, greaterThanOrEqualTo(48));
      expect(find.text('For severe symptoms or emergencies'), findsOneWidget);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.3, 2.0, 3.0]) {
    testWidgets('Emergency wraps readably on a 320px phone at scale $scale', (
      tester,
    ) async {
      await _pumpReading(tester, size: const Size(320, 700), textScale: scale);
      final indicatorRect = tester.getRect(find.byKey(_statusIndicator));
      final button = find.byKey(_emergencyButton);
      final buttonRect = tester.getRect(button);
      expect(buttonRect.top, greaterThan(indicatorRect.bottom));
      expect(buttonRect.left, greaterThanOrEqualTo(20));
      expect(buttonRect.right, lessThanOrEqualTo(300));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Emergency help'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Emergency confirms, reuses existing route, and returns to result',
    (tester) async {
      final observer = _RouteObserver();
      final platformCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });
      await _pumpReading(tester, observer: observer);
      final semantics = tester.ensureSemantics();

      final button = find.byKey(_emergencyButton);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(button),
        matchesSemantics(
          label: 'Emergency',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Emergency help'), findsOneWidget);
      expect(observer.pushedNames, isNot(contains(AppRoutes.emergency)));
      expect(find.byType(EmergencyScreen), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('123 / 96 mmHg'), findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(observer.pushedNames, contains(AppRoutes.emergency));
      expect(find.byType(EmergencyScreen), findsOneWidget);
      expect(find.text('Find Nearby Emergency Hospitals'), findsOneWidget);
      expect(
        platformCalls.where((call) => call.method == 'Clipboard.setData'),
        isEmpty,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('123 / 96 mmHg'), findsOneWidget);
      expect(button, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final reading in [(118, 75), (125, 75), (135, 85), (181, 80)]) {
    testWidgets('Emergency shortcut is absent for other range $reading', (
      tester,
    ) async {
      await _pumpReading(tester, systolic: reading.$1, diastolic: reading.$2);
      expect(find.byKey(_emergencyButton), findsNothing);
      if (reading.$1 == 181) {
        expect(find.text('Urgent Attention'), findsOneWidget);
        expect(find.textContaining('local emergency services'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Emergency stays reachable above the floating navigation', (
    tester,
  ) async {
    await _pumpReading(
      tester,
      size: const Size(320, 700),
      textScale: 2,
      inMainShell: true,
    );
    final button = find.byKey(_emergencyButton);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    final buttonRect = tester.getRect(button);
    final navigationRect = tester.getRect(find.byType(AppBottomNavigation));
    expect(buttonRect.bottom, lessThan(navigationRect.top));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Emergency help'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
