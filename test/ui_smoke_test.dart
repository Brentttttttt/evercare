import 'package:evercare/data/mock_data.dart';
import 'package:evercare/routes/app_routes.dart';
import 'package:evercare/screens/appointments/add_appointment_screen.dart';
import 'package:evercare/screens/appointments/appointment_detail_screen.dart';
import 'package:evercare/screens/appointments/appointments_screen.dart';
import 'package:evercare/screens/appointments/edit_appointment_screen.dart';
import 'package:evercare/screens/caregiver/health_report_screen.dart';
import 'package:evercare/screens/care_book/care_book_screen.dart';
import 'package:evercare/screens/emergency/emergency_screen.dart';
import 'package:evercare/screens/health/blood_pressure_history_screen.dart';
import 'package:evercare/screens/health/blood_pressure_record_screen.dart';
import 'package:evercare/screens/health/blood_pressure_trend_screen.dart';
import 'package:evercare/screens/health/device_connection_screen.dart';
import 'package:evercare/screens/health/health_overview_screen.dart';
import 'package:evercare/screens/health/manual_health_record_screen.dart';
import 'package:evercare/screens/home/home_dashboard_screen.dart';
import 'package:evercare/screens/home/main_shell.dart';
import 'package:evercare/screens/journals/add_journal_entry_screen.dart';
import 'package:evercare/screens/journals/journals_screen.dart';
import 'package:evercare/screens/medications/medication_screen.dart';
import 'package:evercare/screens/notifications/notifications_screen.dart';
import 'package:evercare/screens/onboarding/welcome_screen.dart';
import 'package:evercare/screens/profile/profile_screen.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:evercare/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPhoneScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: Scaffold(body: SafeArea(child: screen)),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  testWidgets('welcome screen fits a common Android phone', (tester) async {
    await pumpPhoneScreen(tester, const WelcomeScreen());
  });

  testWidgets('home dashboard renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, HomeDashboardScreen(onSelectTab: (_) {}));
  });

  testWidgets('health overview renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const HealthOverviewScreen());
  });

  testWidgets('device connection preview renders without overflow', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const DeviceConnectionScreen());
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
      BloodPressureRecordScreen(record: MockData.latestBloodPressure),
    );
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
  });

  testWidgets('medication screen renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const MedicationScreen());
  });

  testWidgets('profile screen renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const ProfileScreen());
  });

  testWidgets('main shell shows appointments navigation and header', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const MainShell(initialIndex: 3));
    expect(find.text('Appointments'), findsWidgets);
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

    expect(happyParagraph.text.style?.color, isNot(Colors.white));
    expect(calmParagraph.text.style?.color, isNot(Colors.white));
  });

  testWidgets('care book screen renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const CareBookScreen());
  });

  testWidgets('emergency screen renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const EmergencyScreen());
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

    await tester.tap(find.byTooltip('Next navigation pages'));
    await tester.pumpAndSettle();

    expect(find.text('Visits'), findsOneWidget);
    expect(find.text('Journals'), findsOneWidget);
    expect(find.text('Care Book'), findsOneWidget);
  });

  testWidgets('appointments dashboard renders without overflow', (
    tester,
  ) async {
    await pumpPhoneScreen(tester, const AppointmentsScreen());
  });

  testWidgets('appointment details render without overflow', (tester) async {
    await pumpPhoneScreen(
      tester,
      AppointmentDetailScreen(appointment: MockData.upcomingAppointments.first),
    );
  });

  testWidgets('add appointment form renders without overflow', (tester) async {
    await pumpPhoneScreen(tester, const AddAppointmentScreen());
  });

  testWidgets('edit appointment form renders without overflow', (tester) async {
    await pumpPhoneScreen(
      tester,
      EditAppointmentScreen(appointment: MockData.upcomingAppointments.first),
    );
  });
}
