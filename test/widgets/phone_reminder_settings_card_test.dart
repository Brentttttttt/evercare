import 'package:evercare/screens/home/main_shell.dart';
import 'package:evercare/screens/notifications/notifications_screen.dart';
import 'package:evercare/services/bp_monitor_ble_service.dart';
import 'package:evercare/services/phone_reminder_controller.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:evercare/widgets/bp_monitor_ble_scope.dart';
import 'package:evercare/widgets/phone_reminder_scope.dart';
import 'package:evercare/widgets/phone_reminder_settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReminders extends PhoneReminderController {
  @override
  bool supported = true;
  @override
  bool initialized = true;
  @override
  bool signedIn = true;
  @override
  bool enabled = false;
  @override
  bool notificationsAllowed = false;
  @override
  bool exactAlarmsAllowed = false;
  @override
  bool busy = false;
  @override
  int scheduledCount = 0;
  @override
  DateTime? scheduledThrough;
  @override
  DateTime? lastSyncedAt;
  @override
  String? error;

  int enables = 0;
  int disables = 0;
  int exactRequests = 0;
  int settingsOpened = 0;
  int refreshes = 0;
  int testsSent = 0;
  int promptChecks = 0;
  bool grantPermission = true;
  bool testSucceeds = true;
  bool offerPrompt = true;

  void changed() => notifyListeners();

  @override
  Future<void> enable() async {
    enables++;
    enabled = true;
    notificationsAllowed = grantPermission;
    notifyListeners();
  }

  @override
  Future<void> disable() async {
    disables++;
    enabled = false;
    scheduledCount = 0;
    notifyListeners();
  }

  @override
  Future<void> enableExactTiming() async {
    exactRequests++;
    exactAlarmsAllowed = true;
    notifyListeners();
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<void> refresh() async => refreshes++;

  @override
  Future<bool> sendTestReminder() async {
    testsSent++;
    return testSucceeds;
  }

  @override
  Future<bool> shouldOfferPermissionPrompt() async {
    promptChecks++;
    final result = offerPrompt;
    offerPrompt = false;
    return result;
  }
}

Future<void> pumpCard(
  WidgetTester tester, {
  FakeReminders? controller,
  double textScale = 1,
  Widget? page,
}) async {
  Widget app = MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home:
        page ??
        const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: PhoneReminderSettingsCard(),
          ),
        ),
  );
  if (controller != null) {
    app = PhoneReminderScope(controller: controller, child: app);
  }
  final ble = BpMonitorBleService();
  addTearDown(ble.close);
  app = BpMonitorBleScope(service: ble, child: app);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Future<void> tapLabel(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('absent scope leaves existing screens unchanged', (tester) async {
    await pumpCard(tester);
    expect(find.text('Phone reminders'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets(
    'unsupported, initializing, and signed-out states have no toggle',
    (tester) async {
      final controller = FakeReminders()..supported = false;
      addTearDown(controller.dispose);
      await pumpCard(tester, controller: controller);
      expect(
        find.text('Phone reminders are available on Android.'),
        findsOneWidget,
      );
      expect(find.byType(Switch), findsNothing);
      controller
        ..supported = true
        ..initialized = false
        ..changed();
      await tester.pump();
      expect(find.text('Checking phone reminder settings…'), findsOneWidget);
      controller
        ..initialized = true
        ..signedIn = false
        ..changed();
      await tester.pump();
      expect(find.text('Sign in to turn on phone reminders.'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    },
  );

  testWidgets('enable and disable are explicit and exact access is optional', (
    tester,
  ) async {
    final controller = FakeReminders();
    addTearDown(controller.dispose);
    await pumpCard(tester, controller: controller);
    expect(controller.enables, 0);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(controller.enables, 1);
    expect(controller.exactRequests, 0);
    expect(find.text('Allow exact timing'), findsOneWidget);
    expect(find.textContaining('Reminders may be delayed.'), findsOneWidget);
    await tapLabel(tester, 'Allow exact timing');
    expect(controller.exactRequests, 1);
    expect(find.text('Exact timing permission: allowed.'), findsOneWidget);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(controller.disables, 1);
    expect(find.text('0 reminders queued on this phone.'), findsOneWidget);
  });

  testWidgets('denied permission explains phone settings and disables tests', (
    tester,
  ) async {
    final controller = FakeReminders()..grantPermission = false;
    addTearDown(controller.dispose);
    await pumpCard(tester, controller: controller);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('Phone permission is blocked.'), findsOneWidget);
    final testButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Test phone reminder'),
    );
    expect(testButton.onPressed, isNull);
    await tapLabel(tester, 'Open phone settings');
    expect(controller.settingsOpened, 1);
    await tapLabel(tester, 'Refresh reminders');
    expect(controller.refreshes, 1);
  });

  testWidgets(
    'test reminder reports scheduling, not inbox or delivery success',
    (tester) async {
      final controller = FakeReminders()
        ..enabled = true
        ..notificationsAllowed = true;
      addTearDown(controller.dispose);
      await pumpCard(tester, controller: controller);
      await tapLabel(tester, 'Test phone reminder');
      expect(controller.testsSent, 1);
      expect(find.textContaining('Test queued for 10 seconds'), findsOneWidget);
      expect(
        find.textContaining('does not add an inbox message'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      controller.testSucceeds = false;
      await tapLabel(tester, 'Test phone reminder');
      expect(find.textContaining('Test was not queued.'), findsOneWidget);
    },
  );

  testWidgets('busy and errors remain visible and block duplicate actions', (
    tester,
  ) async {
    final controller = FakeReminders()
      ..busy = true
      ..error = 'Could not sync your reminder schedule.';
    addTearDown(controller.dispose);
    await pumpCard(tester, controller: controller);
    expect(find.text('Updating phone reminders…'), findsOneWidget);
    expect(find.text(controller.error!), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    for (final button in tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    )) {
      expect(button.onPressed, isNull);
    }
  });

  testWidgets('queue coverage and details wrap at 320px with 3x text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = FakeReminders()
      ..enabled = true
      ..notificationsAllowed = true
      ..scheduledCount = 400
      ..scheduledThrough = DateTime.utc(2026, 10, 1, 0)
      ..lastSyncedAt = DateTime.utc(2026, 9, 22, 1);
    addTearDown(controller.dispose);
    await pumpCard(tester, controller: controller, textScale: 3);
    expect(find.text('400 reminders queued on this phone.'), findsOneWidget);
    expect(
      find.textContaining('This does not confirm every event is covered.'),
      findsOneWidget,
    );
    expect(find.textContaining('Last synced:'), findsOneWidget);
    await tapLabel(tester, 'How reminders work');
    expect(
      find.textContaining('up to 400 of the earliest reminders'),
      findsOneWidget,
    );
    expect(find.textContaining('Philippine time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone card remains above the unavailable account inbox', (
    tester,
  ) async {
    final controller = FakeReminders();
    addTearDown(controller.dispose);
    await pumpCard(
      tester,
      controller: controller,
      page: const NotificationsScreen(),
    );
    expect(find.text('Phone reminders'), findsOneWidget);
    expect(find.text('Sign in to see notifications'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Phone reminders')).dy,
      lessThan(tester.getTopLeft(find.text('Sign in to see notifications')).dy),
    );
  });

  testWidgets(
    'first-login prompt waits for initialization and never enables on Not now',
    (tester) async {
      final controller = FakeReminders()..initialized = false;
      addTearDown(controller.dispose);
      await pumpCard(tester, controller: controller, page: const MainShell());
      expect(find.text('Get reminders on this phone?'), findsNothing);
      controller
        ..initialized = true
        ..changed();
      await tester.pumpAndSettle();
      expect(find.text('Get reminders on this phone?'), findsOneWidget);
      expect(controller.enables, 0);
      await tapLabel(tester, 'Not now');
      controller.changed();
      await tester.pumpAndSettle();
      expect(controller.enables, 0);
      expect(controller.promptChecks, 1);
      expect(find.text('Get reminders on this phone?'), findsNothing);
    },
  );

  testWidgets('first-login Enable requests notifications only', (tester) async {
    final controller = FakeReminders();
    addTearDown(controller.dispose);
    await pumpCard(tester, controller: controller, page: const MainShell());
    await tapLabel(tester, 'Enable');
    expect(controller.enables, 1);
    expect(controller.exactRequests, 0);
    expect(controller.promptChecks, 1);
  });
}
