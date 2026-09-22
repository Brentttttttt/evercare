import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'routes/app_route_observer.dart';
import 'routes/app_routes.dart';
import 'models/scheduled_reminder.dart';
import 'services/accessibility_settings_controller.dart';
import 'services/bp_monitor_ble_service.dart';
import 'services/phone_notification_driver.dart';
import 'services/phone_reminder_service.dart';
import 'services/reminder_data_source.dart';
import 'theme/app_theme.dart';
import 'widgets/accessibility_settings_scope.dart';
import 'widgets/bp_monitor_ble_scope.dart';
import 'widgets/evercare_backend_scope.dart';
import 'widgets/phone_reminder_scope.dart';

class EverCareApp extends StatefulWidget {
  const EverCareApp({super.key});

  @override
  State<EverCareApp> createState() => _EverCareAppState();
}

class _EverCareAppState extends State<EverCareApp> with WidgetsBindingObserver {
  late final BpMonitorBleService _bpMonitorService = BpMonitorBleService();
  late final AccessibilitySettingsController _accessibilitySettings =
      AccessibilitySettingsController();
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final _reminderRouteObserver = _ReminderRouteObserver(
    _openPendingReminder,
  );
  late final _phoneReminders = PhoneReminderService(
    source: SupabaseReminderDataSource(Supabase.instance.client),
    driver: LocalPhoneNotificationDriver(),
    onOpenReminder: (target) {
      _pendingReminder = target;
      _pendingReminderUserId = Supabase.instance.client.auth.currentUser?.id;
      _hasPendingReminder = true;
      _openPendingReminder();
    },
  );
  ReminderNotificationTarget? _pendingReminder;
  String? _pendingReminderUserId;
  bool _hasPendingReminder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bpMonitorService.initialize());
    unawaited(_accessibilitySettings.load());
    unawaited(_phoneReminders.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _bpMonitorService.setAppInForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) {
      unawaited(_phoneReminders.refresh());
    }
  }

  void _openPendingReminder() {
    if (!_hasPendingReminder || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hasPendingReminder) return;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null || userId != _pendingReminderUserId) {
        _hasPendingReminder = false;
        return;
      }
      final current = _reminderRouteObserver.currentPage;
      if (current == null ||
          const {
            AppRoutes.splash,
            AppRoutes.welcome,
            AppRoutes.onboarding,
            AppRoutes.login,
            AppRoutes.registration,
            AppRoutes.forgotPassword,
            AppRoutes.editProfile,
          }.contains(current)) {
        return;
      }
      final target = _pendingReminder;
      _hasPendingReminder = false;
      // Load current account data in the existing screens, never stale health
      // information from the notification. No attendance/dose action is taken.
      _navigatorKey.currentState?.pushNamed(
        target == null ? AppRoutes.notifications : AppRoutes.home,
        arguments: target?.kind == ReminderKind.medication ? 2 : 3,
      );
    });
    // A notification intent can arrive while the foreground app is idle.
    // Registering a post-frame callback alone does not schedule that frame.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_bpMonitorService.close());
    _accessibilitySettings.dispose();
    _phoneReminders.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EverCareAccessibilityScope(
      settings: _accessibilitySettings,
      child: AnimatedBuilder(
        animation: _accessibilitySettings,
        builder: (context, child) {
          return EverCareBackendScope(
            client: Supabase.instance.client,
            child: BpMonitorBleScope(
              service: _bpMonitorService,
              child: PhoneReminderScope(
                controller: _phoneReminders,
                child: MaterialApp(
                  navigatorKey: _navigatorKey,
                  title: 'EverCare',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light,
                  themeAnimationDuration: _accessibilitySettings.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  themeAnimationCurve: Curves.easeOutCubic,
                  scrollBehavior: const _EverCareScrollBehavior(),
                  initialRoute: AppRoutes.splash,
                  onGenerateRoute: AppRoutes.onGenerateRoute,
                  navigatorObservers: [
                    everCareRouteObserver,
                    _reminderRouteObserver,
                  ],
                  builder: (context, child) => EverCareAccessibilityMediaQuery(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReminderRouteObserver extends NavigatorObserver {
  _ReminderRouteObserver(this.onChanged);
  final VoidCallback onChanged;
  String? currentPage;
  void _changed(Route<dynamic>? route) {
    if (route is PageRoute) {
      currentPage = route.settings.name;
      onChanged();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _changed(newRoute);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed(previousRoute);
}

class _EverCareScrollBehavior extends MaterialScrollBehavior {
  const _EverCareScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
