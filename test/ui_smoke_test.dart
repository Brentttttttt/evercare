import 'dart:convert';

import 'package:evercare/models/appointment.dart';
import 'package:evercare/models/blood_pressure_reading.dart';
import 'package:evercare/models/bp_monitor_packet.dart';
import 'package:evercare/models/hospital_location.dart';
import 'package:evercare/models/journal_entry.dart';
import 'package:evercare/models/journal_photo.dart';
import 'package:evercare/models/medication.dart';
import 'package:evercare/models/medication_dose.dart';
import 'package:evercare/routes/app_route_observer.dart';
import 'package:evercare/routes/app_routes.dart';
import 'package:evercare/services/bp_monitor_ble_service.dart';
import 'package:evercare/services/hospital_finder_service.dart';
import 'package:evercare/screens/appointments/add_appointment_screen.dart';
import 'package:evercare/screens/appointments/appointment_detail_screen.dart';
import 'package:evercare/screens/appointments/appointments_screen.dart';
import 'package:evercare/screens/appointments/edit_appointment_screen.dart';
import 'package:evercare/screens/authentication/login_screen.dart';
import 'package:evercare/screens/authentication/registration_screen.dart';
import 'package:evercare/screens/caregiver/health_report_screen.dart';
import 'package:evercare/screens/care_book/care_book_ai_chat_sheet.dart';
import 'package:evercare/screens/care_book/care_book_screen.dart';
import 'package:evercare/screens/emergency/emergency_screen.dart';
import 'package:evercare/screens/hospitals/hospital_finder_screen.dart';
import 'package:evercare/screens/health/blood_pressure_history_screen.dart';
import 'package:evercare/screens/health/blood_pressure_record_screen.dart';
import 'package:evercare/screens/health/blood_pressure_trend_screen.dart';
import 'package:evercare/screens/health/bp_monitor_test_page.dart';
import 'package:evercare/screens/health/health_overview_screen.dart';
import 'package:evercare/screens/health/health_bp_ai_chat_sheet.dart';
import 'package:evercare/screens/health/manual_health_record_screen.dart';
import 'package:evercare/screens/home/home_dashboard_screen.dart';
import 'package:evercare/screens/home/main_shell.dart';
import 'package:evercare/screens/journals/add_journal_entry_screen.dart';
import 'package:evercare/screens/journals/journal_entry_card.dart';
import 'package:evercare/screens/journals/journal_entry_reader.dart';
import 'package:evercare/screens/journals/journals_screen.dart';
import 'package:evercare/screens/medications/add_medication_screen.dart';
import 'package:evercare/screens/medications/medication_detail_screen.dart';
import 'package:evercare/screens/medications/medication_screen.dart';
import 'package:evercare/screens/notifications/notifications_screen.dart';
import 'package:evercare/screens/onboarding/welcome_screen.dart';
import 'package:evercare/screens/profile/profile_screen.dart';
import 'package:evercare/screens/profile/accessibility_screen.dart';
import 'package:evercare/screens/settings/settings_screen.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:evercare/theme/app_motion.dart';
import 'package:evercare/widgets/app_bottom_navigation.dart';
import 'package:evercare/widgets/blood_pressure_widgets.dart';
import 'package:evercare/widgets/bp_level_visual.dart';
import 'package:evercare/widgets/bp_monitor_ble_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

HospitalFinderService _hospitalFinderFixture() => HospitalFinderService(
  client: MockClient(
    (_) async => http.Response(
      jsonEncode([
        {
          'place_id': 10,
          'osm_type': 'node',
          'osm_id': 501,
          'lat': '14.8300',
          'lon': '120.8800',
          'name': 'Guiguinto Community Hospital',
          'display_name':
              'Guiguinto Community Hospital, Guiguinto, Bulacan, Philippines',
          'address': {'amenity': 'Guiguinto Community Hospital'},
        },
      ]),
      200,
    ),
  ),
  nominatimEndpoint: Uri.parse('https://example.test/search'),
);

const _confirmedMonitorResult = <int>[
  0x81,
  0x46,
  0x24,
  0x32,
  0x00,
  0x00,
  0x19,
  0x03,
  0x15,
  0x0A,
  0x11,
  0x00,
  0x00,
  0x00,
  0x00,
];

// Raw systolic 128 is corrected by the app to 118. Diastolic 95 alone
// determines the Stage 2 measurement range.
const _diastolicStage2MonitorResult = <int>[
  0x81,
  0x80,
  0x5F,
  0x4B,
  0x00,
  0x00,
  0x00,
  0x00,
];

// Raw systolic 191 is corrected by the app to 181, preserving the existing
// severely elevated / urgent handling path.
const _severeMonitorResult = <int>[
  0x81,
  0xBF,
  0x50,
  0x4B,
  0x00,
  0x00,
  0x00,
  0x00,
];

final _testReading = BloodPressureReading(
  id: 'reading-test-id',
  userId: 'user-test-id',
  systolic: 120,
  diastolic: 80,
  pulse: 72,
  measuredAt: DateTime(2026, 7, 30, 9, 15),
  source: 'ble',
  monitorName: 'YK-IBPA1',
  notes: 'Widget test fixture',
  isMedicallyVerified: false,
);

final _testAppointment = Appointment(
  id: 'appointment-test-id',
  userId: 'user-test-id',
  title: 'Clinic visit',
  doctorName: 'Test clinician',
  specialty: 'General practice',
  startsAt: DateTime(2026, 8, 4, 9, 30),
  clinic: 'Test clinic',
  address: 'Test address',
  notes: 'Widget test fixture',
  status: AppointmentStatus.upcoming,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPhoneScreen(
    WidgetTester tester,
    Widget screen, {
    BpMonitorBleService? service,
    Size size = const Size(390, 844),
    double textScaleFactor = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bpMonitorService = service ?? BpMonitorBleService();
    addTearDown(bpMonitorService.close);

    await tester.pumpWidget(
      BpMonitorBleScope(
        service: bpMonitorService,
        child: MaterialApp(
          theme: AppTheme.light,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          navigatorObservers: [everCareRouteObserver],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
            child: child!,
          ),
          home: Scaffold(body: SafeArea(child: screen)),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  test('all named pages use the shared EverCare transition route', () {
    final route = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutes.login),
    );

    expect(route, isA<EverCarePageRoute<dynamic>>());
    final animatedRoute = route as EverCarePageRoute<dynamic>;
    expect(animatedRoute.transitionDuration, AppMotion.page);
    expect(animatedRoute.reverseTransitionDuration, AppMotion.standard);
    expect(
      AppTheme.light.pageTransitionsTheme.builders.values,
      everyElement(isA<EverCarePageTransitionsBuilder>()),
    );
  });

  test('raw BP monitor packets keep bytes and format uppercase hex', () {
    final packet = BpMonitorPacket(
      index: 1,
      bytes: const [128, 0, 1, 0],
      receivedAt: DateTime(2026, 7, 30, 10, 15),
    );

    expect(packet.index, 1);
    expect(packet.length, 4);
    expect(packet.decimalString, '[128, 0, 1, 0]');
    expect(packet.hexadecimalString, '80 00 01 00');
  });

  test('progress packets share one structure and are not highlighted', () {
    final first = BpMonitorPacket.fromNotification(
      index: 1,
      bytes: const [128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      receivedAt: DateTime(2026, 7, 30, 10, 15),
      compareAgainstProgressStructure: false,
    );
    final next = BpMonitorPacket.fromNotification(
      index: 2,
      bytes: const [128, 0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      receivedAt: DateTime(2026, 7, 30, 10, 15, 1),
      compareAgainstProgressStructure: true,
    );

    expect(first.isHighlighted, isFalse);
    expect(next.isHighlighted, isFalse);
    expect(first.structureSignature, next.structureSignature);
  });

  test('unusual packet bytes are highlighted without decoding values', () {
    final packet = BpMonitorPacket.fromNotification(
      index: 42,
      bytes: const [128, 0, 30, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      receivedAt: DateTime(2026, 7, 30, 10, 15),
      compareAgainstProgressStructure: true,
    );
    final json = packet.toJson();

    expect(packet.isHighlighted, isTrue);
    expect(
      packet.highlightReasons,
      contains('A byte after index 2 is nonzero'),
    );
    expect(json['index'], 42);
    expect(json['timestamp'], isA<String>());
    expect(json['decimalBytes'], packet.bytes);
    expect(json['hex'], packet.hexadecimalString);
    expect(json['length'], 15);
  });

  testWidgets('welcome screen fits a common Android phone', (tester) async {
    await pumpPhoneScreen(tester, const WelcomeScreen());
  });

  testWidgets('home dashboard renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, HomeDashboardScreen(onSelectTab: (_) {}));
    expect(find.text('No real reading received yet'), findsOneWidget);
    expect(find.text('120/80'), findsNothing);
    expect(find.text('Synced today at 8:45 AM'), findsNothing);
  });

  testWidgets('home latest BLE card uses friendly reading wording', (
    tester,
  ) async {
    final service = BpMonitorBleService();
    service.processNotificationForTesting(
      _diastolicStage2MonitorResult,
      receivedAt: DateTime(2026, 8, 25, 12, 30),
    );

    await pumpPhoneScreen(
      tester,
      HomeDashboardScreen(onSelectTab: (_) {}),
      service: service,
    );

    expect(find.text('This reading needs some attention'), findsOneWidget);
    expect(find.text('Stage 2 blood pressure range'), findsOneWidget);
    expect(find.text('118/95'), findsOneWidget);
  });

  testWidgets('health overview renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const HealthOverviewScreen());
    expect(
      find.text('No blood-pressure measurement received yet.'),
      findsOneWidget,
    );
    expect(find.text('No BLE reading in this session yet.'), findsOneWidget);
    expect(find.text('Preview device state'), findsNothing);
    expect(find.text('85%'), findsNothing);
    expect(find.text('120 / 80'), findsNothing);
  });

  testWidgets('health overview displays only a real decoded BLE result', (
    tester,
  ) async {
    final service = BpMonitorBleService();
    service.processNotificationForTesting(
      _confirmedMonitorResult,
      receivedAt: DateTime(2026, 7, 30, 18, 30),
    );

    await pumpPhoneScreen(
      tester,
      const HealthOverviewScreen(),
      service: service,
    );

    expect(find.text('60'), findsOneWidget);
    expect(find.text('36'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('Received directly through BLE'), findsOneWidget);
    expect(find.text('This reading is lower than usual'), findsOneWidget);
    expect(find.text('Lower-than-usual blood pressure reading'), findsWidgets);
    expect(find.text('Bluetooth (BLE)'), findsOneWidget);
    expect(find.text(service.currentResult!.deviceName), findsWidgets);
    expect(
      find.text(
        'More saved readings are needed before a trend can be displayed.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('July 30, 2026'), findsWidgets);
    expect(find.textContaining('06:30 PM'), findsWidgets);
    expect(find.byKey(const Key('bp-hero-card')), findsOneWidget);
    expect(find.byKey(const Key('bp-metric-sys')), findsOneWidget);
    expect(find.byKey(const Key('bp-metric-dia')), findsOneWidget);
    expect(find.byKey(const Key('bp-metric-pulse')), findsOneWidget);
    expect(find.byKey(const Key('bp-meaning-card')), findsOneWidget);
    expect(find.byKey(const Key('evercare-ai-card')), findsOneWidget);
    expect(find.byKey(healthBpAiChatButtonKey), findsOneWidget);
    expect(find.byKey(evercareAiMascotKey), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final provider = widget.image;
        final asset = provider is ResizeImage
            ? provider.imageProvider
            : provider;
        return asset is AssetImage &&
            asset.assetName == 'assets/health/bp_levels/bp_lower_hero.webp';
      }),
      findsOneWidget,
    );
    expect(find.text('144'), findsNothing);
    expect(find.text('106'), findsNothing);
    expect(find.text('85'), findsNothing);
    expect(find.text('Normal'), findsNothing);
    expect(find.text('Elevated'), findsNothing);
    expect(find.text('High'), findsNothing);
    expect(find.text('Save Result'), findsOneWidget);
    expect(find.text('Share'), findsNothing);

    final historyRect = tester.getRect(find.text('View History'));
    final trendRect = tester.getRect(find.text('View Trend'));
    expect((historyRect.top - trendRect.top).abs(), lessThan(2));
  });

  testWidgets('health insight opens a chat for the current corrected reading', (
    tester,
  ) async {
    final service = BpMonitorBleService();
    service.processNotificationForTesting(
      _diastolicStage2MonitorResult,
      receivedAt: DateTime(2026, 8, 25, 12, 30),
    );

    await pumpPhoneScreen(
      tester,
      const HealthOverviewScreen(),
      service: service,
    );

    final chatButton = find.byKey(healthBpAiChatButtonKey);
    await tester.ensureVisible(chatButton);
    await tester.pumpAndSettle();
    await tester.tap(chatButton);
    await tester.pumpAndSettle();

    expect(find.byKey(healthBpAiChatSheetKey), findsOneWidget);
    expect(find.text('Ask about this reading'), findsOneWidget);
    expect(find.textContaining('118/95 mmHg'), findsWidgets);
    expect(find.byKey(healthBpAiChatHeaderMascotKey), findsOneWidget);
    expect(find.byKey(healthBpAiChatAssistantMascotKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('health result explains a diastolic-only Stage 2 measurement range', (
    tester,
  ) async {
    final service = BpMonitorBleService();
    service.processNotificationForTesting(
      _diastolicStage2MonitorResult,
      receivedAt: DateTime(2026, 8, 25, 12, 30),
    );

    await pumpPhoneScreen(
      tester,
      const HealthOverviewScreen(),
      service: service,
    );

    expect(find.text('This reading needs some attention'), findsOneWidget);
    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('Stage 2 blood pressure range'), findsWidgets);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final provider = widget.image;
        final asset = provider is ResizeImage
            ? provider.imageProvider
            : provider;
        return asset is AssetImage &&
            asset.assetName == 'assets/health/bp_levels/bp_stage2_hero.webp';
      }),
      findsOneWidget,
    );
    expect(find.text('Upper number'), findsOneWidget);
    expect(find.text('Lower number'), findsOneWidget);
    expect(
      find.textContaining(
        'upper number (systolic) is 118 mmHg, which is within the normal range',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'lower number (diastolic) is 95 mmHg, which falls within the Stage 2 range',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('use whichever value falls into the higher category'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'lower number (diastolic) determines the Stage 2 range for this measurement',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'This result describes this reading only and is not a medical diagnosis.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('You have Stage 2'), findsNothing);
    expect(find.textContaining('High blood pressure · Stage 2'), findsNothing);

    await tester.ensureVisible(find.byTooltip('More about this result'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More about this result'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Blood pressure can change throughout the day. Repeated measurements and evaluation by a qualified healthcare professional are used when assessing high blood pressure.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('completed reading cards fit a narrow scaled phone', (
    tester,
  ) async {
    final service = BpMonitorBleService();
    service.processNotificationForTesting(
      _confirmedMonitorResult,
      receivedAt: DateTime(2026, 7, 30, 18, 30),
    );

    await pumpPhoneScreen(
      tester,
      const HealthOverviewScreen(),
      service: service,
      size: const Size(320, 700),
      textScaleFactor: 1.3,
    );

    expect(find.text('Measurement information'), findsOneWidget);
    expect(find.text('Recent trend'), findsOneWidget);
    expect(find.text('View History'), findsOneWidget);
    expect(find.text('View Trend'), findsOneWidget);
    expect(find.text('Completed reading'), findsOneWidget);
    expect(
      find.text(
        'Decoder is provisional. Raw packet metadata is preserved and available through BLE Diagnostics.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open BLE Diagnostics'), findsOneWidget);
    expect(find.textContaining('July 30, 2026'), findsWidgets);
    expect(find.textContaining('06:30 PM'), findsWidgets);
    expect(tester.takeException(), isNull);

    final sysRect = tester.getRect(find.text('SYS'));
    final diaRect = tester.getRect(find.text('DIA'));
    final pulseRect = tester.getRect(find.text('Pulse'));
    expect((sysRect.top - diaRect.top).abs(), lessThan(2));
    expect(diaRect.left, greaterThan(sysRect.left));
    expect(pulseRect.top, greaterThan(sysRect.bottom));
    expect((pulseRect.left - sysRect.left).abs(), lessThan(2));

    final timeRect = tester.getRect(find.text('Time measured'));
    final monitorRect = tester.getRect(find.text('Connected monitor'));
    final sourceRect = tester.getRect(find.text('Measurement source'));
    final statusRect = tester.getRect(find.text('Capture status'));
    expect((timeRect.top - monitorRect.top).abs(), lessThan(2));
    expect(monitorRect.left, greaterThan(timeRect.left));
    expect((sourceRect.top - statusRect.top).abs(), lessThan(2));
    expect(sourceRect.top, greaterThan(timeRect.bottom));
    expect(statusRect.left, greaterThan(sourceRect.left));

    await tester.pump(AppMotion.page);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('View History'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();

    expect(find.text('Blood Pressure History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed reading metrics use three columns on a wide phone', (
    tester,
  ) async {
    final service = BpMonitorBleService();
    service.processNotificationForTesting(
      _confirmedMonitorResult,
      receivedAt: DateTime(2026, 7, 30, 18, 30),
    );

    await pumpPhoneScreen(
      tester,
      const HealthOverviewScreen(),
      service: service,
      size: const Size(600, 900),
    );

    final sysRect = tester.getRect(find.text('SYS'));
    final diaRect = tester.getRect(find.text('DIA'));
    final pulseRect = tester.getRect(find.text('Pulse'));
    expect((sysRect.top - diaRect.top).abs(), lessThan(2));
    expect((sysRect.top - pulseRect.top).abs(), lessThan(2));
    expect(sysRect.left, lessThan(diaRect.left));
    expect(diaRect.left, lessThan(pulseRect.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed reading stays readable at 200 percent text', (
    tester,
  ) async {
    final service = BpMonitorBleService();
    service.processNotificationForTesting(
      _diastolicStage2MonitorResult,
      receivedAt: DateTime(2026, 8, 25, 12, 30),
    );

    await pumpPhoneScreen(
      tester,
      const HealthOverviewScreen(),
      service: service,
      size: const Size(320, 700),
      textScaleFactor: 2,
    );
    await tester.pump(AppMotion.page);

    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('Upper number'), findsOneWidget);
    expect(find.text('Lower number'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('severely elevated result keeps urgent safety guidance', (
    tester,
  ) async {
    final service = BpMonitorBleService();
    service.processNotificationForTesting(
      _severeMonitorResult,
      receivedAt: DateTime(2026, 8, 25, 13, 5),
    );

    await pumpPhoneScreen(
      tester,
      const HealthOverviewScreen(),
      service: service,
      size: const Size(320, 700),
      textScaleFactor: 1.3,
    );

    expect(find.text('This reading needs urgent attention'), findsOneWidget);
    expect(find.text('Severely elevated blood pressure reading'), findsWidgets);
    expect(find.textContaining('seek urgent clinical advice'), findsOneWidget);
    expect(find.textContaining('local emergency services'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final provider = widget.image;
        final asset = provider is ResizeImage
            ? provider.imageProvider
            : provider;
        return asset is AssetImage &&
            asset.assetName == 'assets/health/bp_levels/bp_severe_hero.webp';
      }),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('health auto-connect lease pauses under another page', (
    tester,
  ) async {
    final service = BpMonitorBleService();
    await pumpPhoneScreen(
      tester,
      const MainShell(initialIndex: 1),
      service: service,
    );
    await tester.pump();
    expect(service.hasActiveClient, isTrue);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(AppRoutes.manualRecord);
    await tester.pumpAndSettle();
    expect(service.hasActiveClient, isFalse);

    navigator.pop();
    await tester.pumpAndSettle();
    expect(service.hasActiveClient, isTrue);
  });

  testWidgets('BLE monitor capture page renders without overflow', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const BpMonitorTestPage());
    expect(find.text('Capture session'), findsOneWidget);
    expect(find.text('Start new capture'), findsOneWidget);
    expect(find.text('Export / Copy Complete Session'), findsOneWidget);
  });

  testWidgets('blood-pressure history renders without overflow', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const BloodPressureHistoryScreen());
  });

  testWidgets('blood-pressure record details render without overflow', (
    tester,
  ) async {
    await pumpPhoneScreen(
      tester,
      BloodPressureRecordScreen(record: _testReading),
      size: const Size(320, 700),
      textScaleFactor: 2,
    );
    expect(
      find.text('Your reading is higher than recommended'),
      findsOneWidget,
    );
    expect(find.text('Upper number (systolic)'), findsOneWidget);
    expect(find.text('Lower number (diastolic)'), findsOneWidget);
  });

  testWidgets('saved reading card fits a narrow phone at large text', (
    tester,
  ) async {
    await pumpPhoneScreen(
      tester,
      SingleChildScrollView(
        child: BloodPressureRecordCard(record: _testReading, onTap: () {}),
      ),
      size: const Size(320, 700),
      textScaleFactor: 2,
    );

    expect(
      find.text('Your reading is higher than recommended'),
      findsOneWidget,
    );
    expect(find.text('Stage 1 blood pressure range'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blood-pressure trend renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const BloodPressureTrendScreen());
  });

  testWidgets('manual blood-pressure entry renders without overflow', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const ManualHealthRecordScreen());
  });

  testWidgets('blood-pressure report renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const HealthReportScreen());
  });

  testWidgets('focused notifications render without overflow', (tester) async {
    await pumpPhoneScreen(tester, const NotificationsScreen());
    expect(find.text('Blood pressure reading synchronized'), findsNothing);
    expect(find.textContaining('120/80'), findsNothing);
    expect(find.textContaining('YK-BPA1'), findsNothing);
  });

  testWidgets('medication screen renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const MedicationScreen());
  });

  testWidgets('due medication reminder exposes the Taken action', (
    tester,
  ) async {
    const medication = Medication(
      id: 'med-reminder',
      userId: 'user-1',
      name: 'Amlodipine',
      dosage: '5 mg',
      purpose: '',
      frequency: 'Monday',
      instructions: '',
      scheduleTime: '09:00:00',
      startDate: null,
      endDate: null,
      isActive: true,
      scheduleDays: [DateTime.monday],
    );
    final now = DateTime.utc(2026, 8, 10, 1, 30);
    final occurrence = MedicationDoseOccurrence(
      medication: medication,
      scheduledFor: DateTime.utc(2026, 8, 10, 1),
      state: MedicationDoseState.due,
    );
    var markedTaken = false;

    await pumpPhoneScreen(
      tester,
      MedicationReminderSection(
        doses: [occurrence],
        now: now,
        onTaken: (_) => markedTaken = true,
        takingDoseKeys: const {},
        hasUnconfirmedSchedules: false,
      ),
      size: const Size(320, 720),
      textScaleFactor: 1.2,
    );

    expect(find.text('Medication reminders'), findsOneWidget);
    expect(find.text('Due now'), findsOneWidget);
    expect(find.text('Taken'), findsOneWidget);
    await tester.tap(find.text('Taken'));
    expect(markedTaken, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grouped medication form fits a narrow phone', (tester) async {
    await pumpPhoneScreen(
      tester,
      const AddMedicationScreen(),
      size: const Size(320, 720),
    );
    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Frequency'), findsNothing);
    expect(find.text('Days to take this medicine'), findsOneWidget);
    expect(find.text('Every day'), findsOneWidget);
    expect(find.text('Weekdays'), findsOneWidget);
    expect(find.text('Weekends'), findsOneWidget);
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Sunday'), findsOneWidget);
    expect(find.text('Reminder time'), findsOneWidget);
    expect(find.text('Select reminder time'), findsOneWidget);
    expect(find.textContaining('Reminder time (optional)'), findsNothing);
    expect(find.text('Instructions and status'), findsOneWidget);
  });

  testWidgets('medication details expose a separate course done action', (
    tester,
  ) async {
    const medication = Medication(
      id: 'med-1',
      userId: 'user-1',
      name: 'Amlodipine',
      dosage: '5 mg',
      purpose: 'Blood pressure support',
      frequency: 'Mon, Wed, Fri',
      instructions: 'Take with water',
      scheduleTime: '09:00:00',
      startDate: null,
      endDate: null,
      isActive: true,
      scheduleDays: [DateTime.monday, DateTime.wednesday, DateTime.friday],
    );
    await pumpPhoneScreen(
      tester,
      const MedicationDetailScreen(medication: medication),
    );

    expect(find.text('Days to take'), findsOneWidget);
    expect(find.text('Mon, Wed, Fri'), findsOneWidget);
    expect(find.text('Frequency'), findsNothing);
    final finishButton = find.text('Mark Medication as Done');
    await tester.ensureVisible(finishButton);
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    expect(find.text('Mark medication as done?'), findsOneWidget);
    expect(find.text('Mark as Done'), findsOneWidget);
    expect(
      find.textContaining('Past Taken and Missed records'),
      findsOneWidget,
    );
  });

  testWidgets('profile screen renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const ProfileScreen());
  });

  testWidgets('login surface fits a narrow scaled phone', (tester) async {
    await pumpPhoneScreen(
      tester,
      const LoginScreen(),
      size: const Size(320, 720),
      textScaleFactor: 1.3,
    );
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Care, made simpler'), findsOneWidget);
  });

  testWidgets('registration surface fits a narrow phone', (tester) async {
    await pumpPhoneScreen(
      tester,
      const RegistrationScreen(),
      size: const Size(320, 720),
    );
    expect(find.text('About you'), findsOneWidget);
    expect(find.text('Account security'), findsOneWidget);
  });

  testWidgets('settings groups render without overflow', (tester) async {
    await pumpPhoneScreen(tester, const SettingsScreen());
    expect(find.text('Account and care'), findsOneWidget);
    expect(find.text('Support and information'), findsOneWidget);
  });

  testWidgets('accessibility page clearly labels preview-only controls', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const AccessibilityScreen());
    expect(find.text('Preview mode'), findsOneWidget);
    expect(find.text('COMING LATER'), findsOneWidget);
  });

  testWidgets('main shell shows appointments navigation and header', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const MainShell(initialIndex: 3));
    expect(find.text('Appointments'), findsWidgets);
  });

  testWidgets('main pages reset to the top when revisited', (tester) async {
    await pumpPhoneScreen(tester, const MainShell());
    final homePage = find.byType(HomeDashboardScreen);
    final homeScrollView = find
        .descendant(of: homePage, matching: find.byType(SingleChildScrollView))
        .first;
    final homeScrollable = find
        .descendant(of: homePage, matching: find.byType(Scrollable))
        .first;

    await tester.drag(homeScrollView, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(homeScrollable).position.pixels,
      greaterThan(0),
    );

    final navigation = find.byType(AppBottomNavigation);
    await tester.tap(
      find.descendant(of: navigation, matching: find.text('Medicine')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: navigation, matching: find.text('Home')),
    );
    await tester.pumpAndSettle();

    expect(tester.state<ScrollableState>(homeScrollable).position.pixels, 0);
  });

  testWidgets('returning from a detail route resets the main page', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const MainShell());
    final homePage = find.byType(HomeDashboardScreen);
    final homeScrollView = find
        .descendant(of: homePage, matching: find.byType(SingleChildScrollView))
        .first;
    final homeScrollable = find
        .descendant(of: homePage, matching: find.byType(Scrollable))
        .first;

    await tester.drag(homeScrollView, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(homeScrollable).position.pixels,
      greaterThan(0),
    );

    Navigator.of(tester.element(find.byType(MainShell))).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Temporary detail page')),
      ),
    );
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Temporary detail page'))).pop();
    await tester.pumpAndSettle();

    expect(tester.state<ScrollableState>(homeScrollable).position.pixels, 0);
  });

  testWidgets('activating Home does not return a Future from setState', (
    tester,
  ) async {
    var active = false;
    late StateSetter updateHost;
    await pumpPhoneScreen(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          updateHost = setState;
          return HomeDashboardScreen(isActive: active, onSelectTab: (_) {});
        },
      ),
    );

    updateHost(() => active = true);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('journals screen renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const JournalsScreen());
    expect(find.text('How are you feeling today?'), findsNothing);
    expect(find.text('Entry title'), findsNothing);
    expect(find.text('Add Journal Entry'), findsOneWidget);
  });

  testWidgets('add journal button opens the separate writing page', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const JournalsScreen());
    await tester.tap(find.text('Add Journal Entry'));
    await tester.pumpAndSettle();

    expect(find.text('Write a Journal Entry'), findsOneWidget);
    expect(find.text('Entry title'), findsOneWidget);
  });

  testWidgets('journal writing page renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const AddJournalEntryScreen());
  });

  testWidgets('journal chip labels keep readable contrast', (tester) async {
    await pumpPhoneScreen(tester, const AddJournalEntryScreen());

    final happyLabel = find.descendant(
      of: find.byType(ChoiceChip),
      matching: find.text('Happy'),
    );
    final calmLabel = find.descendant(
      of: find.byType(ChoiceChip),
      matching: find.text('Calm'),
    );
    final happyParagraph = tester.renderObject<RenderParagraph>(happyLabel);
    final calmParagraph = tester.renderObject<RenderParagraph>(calmLabel);
    final happyChip = tester.widget<ChoiceChip>(
      find.ancestor(of: happyLabel, matching: find.byType(ChoiceChip)),
    );

    expect(happyParagraph.text.style?.color, isNot(Colors.white));
    expect(calmParagraph.text.style?.color, isNot(Colors.white));
    expect(happyChip.showCheckmark, isFalse);
  });

  testWidgets('journal editor protects unsaved writing', (tester) async {
    await pumpPhoneScreen(tester, const JournalsScreen());
    await tester.tap(find.text('Add Journal Entry'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Give this memory a title…'),
      'A meaningful afternoon',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Discard this journal entry?'), findsOneWidget);
    expect(find.text('Keep Writing'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
  });

  testWidgets('no symptoms remains mutually exclusive', (tester) async {
    await pumpPhoneScreen(tester, const AddJournalEntryScreen());
    await tester.ensureVisible(find.text('Add details to this memory'));
    await tester.tap(find.text('Add details to this memory'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Headache'));
    await tester.tap(find.text('Headache'));
    await tester.tap(find.text('No symptoms'));
    await tester.pump();

    FilterChip chip(String label) => tester.widget<FilterChip>(
      find.ancestor(of: find.text(label), matching: find.byType(FilterChip)),
    );

    expect(chip('Headache').selected, isFalse);
    expect(chip('No symptoms').selected, isTrue);

    await tester.tap(find.text('Poor sleep'));
    await tester.pump();
    expect(chip('Poor sleep').selected, isTrue);
    expect(chip('No symptoms').selected, isFalse);
  });

  testWidgets('custom journal details are trimmed and reject duplicates', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const AddJournalEntryScreen());
    await tester.ensureVisible(find.text('Add details to this memory'));
    await tester.tap(find.text('Add details to this memory'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add your own'));

    await tester.tap(find.text('Add your own'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Journal detail'),
      '  Doctor visit  ',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(find.text('Doctor visit'), findsOneWidget);

    await tester.tap(find.text('Add your own'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Journal detail'),
      'doctor visit',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();
    expect(find.text('That detail is already added.'), findsOneWidget);
  });

  testWidgets('journal cards show a compact photo count preview', (
    tester,
  ) async {
    final entry = JournalEntry(
      id: 'entry-1',
      entryAt: DateTime(2026, 8, 5, 9, 15),
      title: 'Morning walk',
      body: 'We spent some time outside in the garden.',
      mood: 'Happy',
      symptoms: const ['No symptoms'],
      activities: const ['Walking'],
      tags: const ['Walked outside'],
      bookmarked: true,
      photos: [
        for (var index = 0; index < 2; index++)
          JournalPhoto(
            id: 'photo-$index',
            journalEntryId: 'entry-1',
            storagePath: 'user-1/entry-1/photo-$index.jpg',
            displayOrder: index,
            createdAt: DateTime(2026, 8, 5, 9, 16),
          ),
      ],
    );

    await pumpPhoneScreen(
      tester,
      JournalEntryCard(entry: entry, onAction: (_) {}),
    );
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('Walked outside'), findsOneWidget);
    expect(find.text('Photo unavailable'), findsOneWidget);
  });

  testWidgets('journal reader shows the complete diary details', (
    tester,
  ) async {
    final entry = JournalEntry(
      id: 'entry-1',
      entryAt: DateTime(2026, 8, 5, 9, 15),
      title: 'Morning walk',
      body: 'We spent some time outside in the garden.',
      mood: 'Happy',
      symptoms: const ['No symptoms'],
      activities: const ['Walking'],
      tags: const ['Walked outside'],
      bookmarked: true,
    );
    await pumpPhoneScreen(
      tester,
      Builder(
        builder: (context) => Center(
          child: FilledButton(
            onPressed: () => showJournalEntryReader(context, entry),
            child: const Text('Open diary'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open diary'));
    await tester.pumpAndSettle();

    expect(find.text('Morning walk'), findsOneWidget);
    expect(find.text('Feeling happy'), findsOneWidget);
    expect(
      find.text('We spent some time outside in the garden.'),
      findsOneWidget,
    );
    expect(find.text('Symptoms'), findsOneWidget);
    expect(find.text('Walking'), findsOneWidget);
    expect(find.text('Walked outside'), findsOneWidget);
    expect(find.byTooltip('Close journal entry'), findsOneWidget);
  });

  testWidgets('care book screen renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const CareBookScreen());
    expect(find.text('The EverCare\nCare Book'), findsNothing);
    expect(find.text('Need help while reading?'), findsOneWidget);
    expect(find.text('Ask Care Guide'), findsOneWidget);
    expect(find.byKey(careBookAiLauncherKey), findsOneWidget);
    expect(find.byKey(careBookAiLauncherButtonKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(careBookAiLauncherButtonKey),
        matching: find.byType(AiMascotAvatar),
      ),
      findsOneWidget,
    );
    expect(find.text('Official NIA Reference'), findsOneWidget);
    expect(find.text('Official Source Website'), findsOneWidget);
    expect(find.text('Getting Started With Caregiving'), findsOneWidget);
    expect(find.text('Download Original NIA PDF'), findsOneWidget);

    final promptRect = tester.getRect(find.byKey(careBookAiLauncherLabelKey));
    final buttonRect = tester.getRect(find.byKey(careBookAiLauncherButtonKey));
    expect(promptRect.right, lessThan(buttonRect.left));
    expect(buttonRect.size, const Size.square(70));

    await tester.tap(find.byKey(careBookAiLauncherButtonKey));
    await tester.pumpAndSettle();
    expect(find.byKey(careBookAiSheetKey), findsOneWidget);
    expect(find.byKey(careBookAiHeaderMascotKey), findsOneWidget);
    expect(find.byKey(careBookAiAssistantAvatarKey), findsOneWidget);
    expect(find.text('Care Guide'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Care Book AI launcher stays fixed at 200 percent text', (
    tester,
  ) async {
    await pumpPhoneScreen(
      tester,
      const CareBookScreen(),
      size: const Size(320, 700),
      textScaleFactor: 2,
    );

    final prompt = find.byKey(careBookAiLauncherLabelKey);
    final button = find.byKey(careBookAiLauncherButtonKey);
    final launcher = find.byKey(careBookAiLauncherKey);
    final beforePrompt = tester.getRect(prompt);
    final beforeButton = tester.getRect(button);
    final beforeLauncher = tester.getRect(launcher);
    expect(beforePrompt.left, greaterThanOrEqualTo(0));
    expect(beforePrompt.right, lessThan(beforeButton.left));
    expect(beforeButton.right, lessThanOrEqualTo(320));
    expect(beforeButton.size, const Size.square(70));
    expect(beforeLauncher.bottom, closeTo(604, .1));

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(500);
    await tester.pump();

    final afterPrompt = tester.getRect(prompt);
    final afterButton = tester.getRect(button);
    final afterLauncher = tester.getRect(launcher);
    expect((afterPrompt.top - beforePrompt.top).abs(), lessThan(1));
    expect((afterLauncher.top - beforeLauncher.top).abs(), lessThan(1));
    expect(afterButton.size, beforeButton.size);
    expect(tester.takeException(), isNull);
  });

  test('bundled caregiver handbook is available for download', () async {
    final pdf = await rootBundle.load('assets/care_book/caregivers-book.pdf');
    expect(pdf.lengthInBytes, greaterThan(1000));
  });

  testWidgets('emergency screen renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const EmergencyScreen());
    expect(find.textContaining('143'), findsOneWidget);
    expect(find.textContaining('911'), findsNothing);
    expect(find.text('Find Nearby Emergency Hospitals'), findsOneWidget);
    expect(find.text('Medical information'), findsNothing);
  });

  testWidgets('hospital finder renders without a provider API key', (
    tester,
  ) async {
    await pumpPhoneScreen(
      tester,
      const HospitalFinderScreen(autoLocate: false, showMapTiles: false),
    );
    expect(find.text('Find nearby hospitals'), findsOneWidget);
    expect(find.textContaining('OpenStreetMap'), findsWidgets);
  });

  testWidgets('hospital search suggests matches after typing pauses', (
    tester,
  ) async {
    var requestCount = 0;
    final service = HospitalFinderService(
      client: MockClient((_) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'features': [
              {
                'type': 'Feature',
                'geometry': {
                  'type': 'Point',
                  'coordinates': [120.8800, 14.8300],
                },
                'properties': {
                  'osm_type': 'N',
                  'osm_id': 700,
                  'name': 'Guiguinto Community Hospital',
                  'city': 'Guiguinto',
                  'state': 'Bulacan',
                  'country': 'Philippines',
                },
              },
            ],
          }),
          200,
        );
      }),
      photonEndpoint: Uri.parse('https://example.test/api'),
    );
    addTearDown(service.close);
    await pumpPhoneScreen(
      tester,
      HospitalFinderScreen(
        autoLocate: false,
        showMapTiles: false,
        service: service,
      ),
    );

    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'Gui');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(searchField, 'Guiguinto');
    await tester.pump(const Duration(milliseconds: 899));
    expect(requestCount, 0);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pumpAndSettle();

    expect(requestCount, 1);
    expect(find.text('Guiguinto Community Hospital'), findsWidgets);
  });

  testWidgets('appointment hospital result returns when its card is tapped', (
    tester,
  ) async {
    final service = _hospitalFinderFixture();
    addTearDown(service.close);
    HospitalLocation? selectedHospital;

    await pumpPhoneScreen(
      tester,
      Builder(
        builder: (context) => Center(
          child: FilledButton(
            onPressed: () async {
              selectedHospital = await Navigator.push<HospitalLocation>(
                context,
                MaterialPageRoute(
                  builder: (_) => HospitalFinderScreen(
                    allowSelection: true,
                    autoLocate: false,
                    showMapTiles: false,
                    service: service,
                  ),
                ),
              );
            },
            child: const Text('Open hospital picker'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open hospital picker'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search hospital, city, or place'),
      'Guiguinto',
    );
    await tester.tap(find.byTooltip('Search hospitals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guiguinto Community Hospital'));
    await tester.pumpAndSettle();

    expect(selectedHospital?.name, 'Guiguinto Community Hospital');
    expect(find.text('Open hospital picker'), findsOneWidget);
  });

  testWidgets('emergency hospital selection shows directions and contacts', (
    tester,
  ) async {
    final service = _hospitalFinderFixture();
    addTearDown(service.close);
    await pumpPhoneScreen(
      tester,
      HospitalFinderScreen(
        autoLocate: false,
        showMapTiles: false,
        service: service,
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Search hospital, city, or place'),
      'Guiguinto',
    );
    await tester.tap(find.byTooltip('Search hospitals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guiguinto Community Hospital'));
    await tester.pumpAndSettle();

    expect(find.text('Get Directions in Google Maps'), findsOneWidget);
    expect(find.text('Find Contact Number & Details'), findsOneWidget);
    expect(
      find.textContaining('Verify the hospital\'s contact details'),
      findsOneWidget,
    );
  });

  testWidgets('main shell opens the new care destinations', (tester) async {
    await pumpPhoneScreen(tester, const MainShell(initialIndex: 4));
    expect(find.text('Journals'), findsWidgets);
  });

  testWidgets('bottom navigation pages three destinations at a time', (
    tester,
  ) async {
    await pumpPhoneScreen(
      tester,
      AppBottomNavigation(selectedIndex: 0, onDestinationSelected: (_) {}),
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Daily care'), findsOneWidget);

    await tester.tap(find.byTooltip('Next navigation pages'));
    await tester.pumpAndSettle();

    expect(find.text('Visits'), findsOneWidget);
    expect(find.text('Journals'), findsOneWidget);
    expect(find.text('Care Book'), findsOneWidget);
    expect(find.text('Planning and memories'), findsOneWidget);
  });

  testWidgets('appointments dashboard renders without overflow', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const AppointmentsScreen());
  });

  testWidgets('appointment details render without overflow', (tester) async {
    await pumpPhoneScreen(
      tester,
      AppointmentDetailScreen(appointment: _testAppointment),
    );
    expect(find.text('Get Directions in Google Maps'), findsOneWidget);
    expect(find.text('Find Contact Number & Details'), findsOneWidget);
  });

  testWidgets('appointment details show attendance action when due', (
    tester,
  ) async {
    final dueAppointment = _testAppointment.copyWith(
      startsAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
    await pumpPhoneScreen(
      tester,
      AppointmentDetailScreen(appointment: dueAppointment),
    );

    expect(find.text('Due now'), findsOneWidget);
    expect(find.text('Mark Appointment as Done'), findsOneWidget);
  });

  testWidgets('add appointment form renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const AddAppointmentScreen());
    expect(find.text('Type manually'), findsOneWidget);
    expect(find.text('OpenStreetMap'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Type manually')).dy,
      closeTo(tester.getTopLeft(find.text('OpenStreetMap')).dy, 1),
    );

    await tester.tap(find.text('OpenStreetMap'));
    await tester.pumpAndSettle();

    expect(find.text('Find a Hospital on OpenStreetMap'), findsOneWidget);
  });

  testWidgets('edit appointment form renders without overflow', (tester) async {
    await pumpPhoneScreen(
      tester,
      EditAppointmentScreen(appointment: _testAppointment),
    );
  });
}
