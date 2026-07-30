import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/blood_pressure_reading.dart';
import '../models/medication.dart';
import '../screens/appointments/add_appointment_screen.dart';
import '../screens/appointments/appointment_detail_screen.dart';
import '../screens/appointments/edit_appointment_screen.dart';
import '../screens/authentication/forgot_password_screen.dart';
import '../screens/authentication/login_screen.dart';
import '../screens/authentication/registration_screen.dart';
import '../screens/caregiver/caregiver_list_screen.dart';
import '../screens/caregiver/caregiver_profile_screen.dart';
import '../screens/caregiver/health_report_screen.dart';
import '../screens/emergency/emergency_contacts_screen.dart';
import '../screens/emergency/medical_information_screen.dart';
import '../screens/health/blood_pressure_history_screen.dart';
import '../screens/health/blood_pressure_record_screen.dart';
import '../screens/health/blood_pressure_trend_screen.dart';
import '../screens/health/bp_monitor_test_page.dart';
import '../screens/health/manual_health_record_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/journals/add_journal_entry_screen.dart';
import '../screens/medications/add_medication_screen.dart';
import '../screens/medications/medication_detail_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/profile/accessibility_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/help_support_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../theme/app_motion.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const registration = '/registration';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const deviceConnection = '/health/device-connection';
  static const bloodPressureHistory = '/health/history';
  static const bloodPressureRecord = '/health/record';
  static const bloodPressureTrend = '/health/trend';
  static const manualRecord = '/health/add-record';
  static const medicationDetails = '/medications/details';
  static const addMedication = '/medications/add';
  static const appointments = '/appointments';
  static const journals = '/journals';
  static const addJournal = '/journals/add';
  static const careBook = '/care-book';
  static const appointmentDetails = '/appointments/details';
  static const addAppointment = '/appointments/add';
  static const editAppointment = '/appointments/edit';
  static const caregiverList = '/caregivers';
  static const caregiverProfile = '/caregivers/profile';
  static const healthReport = '/caregivers/health-report';
  static const emergency = '/emergency';
  static const emergencyContacts = '/emergency/contacts';
  static const medicalInfo = '/emergency/medical-information';
  static const notifications = '/notifications';
  static const editProfile = '/profile/edit';
  static const accessibility = '/profile/accessibility';
  static const settings = '/settings';
  static const helpSupport = '/support';
  static const about = '/about';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    final page = switch (routeSettings.name) {
      splash => const SplashScreen(),
      welcome => const WelcomeScreen(),
      onboarding => const OnboardingScreen(),
      login => const LoginScreen(),
      registration => const RegistrationScreen(),
      forgotPassword => const ForgotPasswordScreen(),
      home => MainShell(
        initialIndex: routeSettings.arguments is int
            ? routeSettings.arguments! as int
            : 0,
      ),
      deviceConnection => const BpMonitorTestPage(),
      bloodPressureHistory => const BloodPressureHistoryScreen(),
      bloodPressureRecord =>
        routeSettings.arguments is BloodPressureReading
            ? BloodPressureRecordScreen(
                record: routeSettings.arguments! as BloodPressureReading,
              )
            : const BloodPressureHistoryScreen(),
      bloodPressureTrend => const BloodPressureTrendScreen(),
      manualRecord => const ManualHealthRecordScreen(),
      medicationDetails => routeSettings.arguments is Medication
          ? MedicationDetailScreen(
              medication: routeSettings.arguments! as Medication,
            )
          : const MainShell(initialIndex: 2),
      addMedication => AddMedicationScreen(
        medication: routeSettings.arguments is Medication
            ? routeSettings.arguments! as Medication
            : null,
      ),
      appointments => const MainShell(initialIndex: 3),
      journals => const MainShell(initialIndex: 4),
      addJournal => const AddJournalEntryScreen(),
      careBook => const MainShell(initialIndex: 5),
      appointmentDetails => routeSettings.arguments is Appointment
          ? AppointmentDetailScreen(
              appointment: routeSettings.arguments! as Appointment,
            )
          : const MainShell(initialIndex: 3),
      addAppointment => const AddAppointmentScreen(),
      editAppointment => routeSettings.arguments is Appointment
          ? EditAppointmentScreen(
              appointment: routeSettings.arguments! as Appointment,
            )
          : const MainShell(initialIndex: 3),
      caregiverList => const CaregiverListScreen(),
      caregiverProfile => CaregiverProfileScreen(
        caregiver: routeSettings.arguments is Map<String, String>
            ? routeSettings.arguments! as Map<String, String>
            : null,
      ),
      healthReport => const HealthReportScreen(),
      emergency => const MainShell(initialIndex: 6),
      emergencyContacts => const EmergencyContactsScreen(),
      medicalInfo => const MedicalInformationScreen(),
      notifications => const NotificationsScreen(),
      editProfile => const EditProfileScreen(),
      accessibility => const AccessibilityScreen(),
      settings => const SettingsScreen(),
      helpSupport => const HelpSupportScreen(),
      about => const AboutScreen(),
      _ => const WelcomeScreen(),
    };

    return EverCarePageRoute<dynamic>(
      builder: (_) => page,
      settings: routeSettings,
    );
  }
}
