import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../models/scheduled_reminder.dart';

const phoneReminderTestId = 2147483647;

class PhoneNotificationPermissions {
  const PhoneNotificationPermissions({
    required this.allowed,
    required this.exact,
  });
  final bool allowed;
  final bool exact;
}

class PendingPhoneReminder {
  const PendingPhoneReminder(this.id, this.payload);
  final int id;
  final String? payload;
}

abstract interface class PhoneNotificationDriver {
  bool get supported;
  Future<String?> initialize(void Function(String? payload) onTap);
  Future<PhoneNotificationPermissions> permissions();
  Future<void> requestPermission();
  Future<void> requestExactTiming();
  Future<void> openSettings();
  Future<List<PendingPhoneReminder>> pending();
  Future<void> schedule(ScheduledReminder reminder, {required bool exact});
  Future<void> scheduleTest(
    String userId,
    DateTime when, {
    required bool exact,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
}

/// Android stores these one-shot alarms and delivers them without a running
/// Dart isolate or an internet connection. Permission requests are user-driven.
class LocalPhoneNotificationDriver implements PhoneNotificationDriver {
  LocalPhoneNotificationDriver({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()!;

  @override
  Future<String?> initialize(void Function(String? payload) onTap) async {
    timezone_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_evercare'),
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
    for (final kind in ReminderKind.values) {
      await _android.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId(kind),
          kind == ReminderKind.medication
              ? 'Medication reminders'
              : 'Appointment reminders',
          description: 'Scheduled EverCare reminders on this phone.',
          importance: Importance.high,
        ),
      );
    }
    final launch = await _plugin.getNotificationAppLaunchDetails();
    return launch?.didNotificationLaunchApp == true
        ? launch?.notificationResponse?.payload
        : null;
  }

  @override
  Future<PhoneNotificationPermissions> permissions() async =>
      PhoneNotificationPermissions(
        allowed: await _android.areNotificationsEnabled() ?? false,
        exact: await _android.canScheduleExactNotifications() ?? false,
      );

  @override
  Future<void> requestPermission() async {
    await _android.requestNotificationsPermission();
  }

  @override
  Future<void> requestExactTiming() async {
    await _android.requestExactAlarmsPermission();
  }

  @override
  Future<void> openSettings() async {
    await _android.openAppNotificationSettings();
  }

  @override
  Future<List<PendingPhoneReminder>> pending() async => [
    for (final notification in await _plugin.pendingNotificationRequests())
      PendingPhoneReminder(notification.id, notification.payload),
  ];

  @override
  Future<void> schedule(ScheduledReminder reminder, {required bool exact}) =>
      _schedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        when: reminder.scheduledForUtc,
        payload: reminder.payload,
        kind: reminder.kind,
        exact: exact,
      );

  @override
  Future<void> scheduleTest(
    String userId,
    DateTime when, {
    required bool exact,
  }) => _schedule(
    id: phoneReminderTestId,
    title: 'EverCare test reminder',
    body: 'Phone reminders can appear here even when EverCare is not open.',
    when: when,
    payload: jsonEncode({'version': 1, 'test': true, 'userId': userId}),
    kind: ReminderKind.medication,
    exact: exact,
  );

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String payload,
    required ReminderKind kind,
    required bool exact,
  }) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: timezone.TZDateTime.from(when.toUtc(), timezone.UTC),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId(kind),
        kind == ReminderKind.medication
            ? 'Medication reminders'
            : 'Appointment reminders',
        channelDescription: 'Scheduled EverCare reminders on this phone.',
        icon: 'ic_stat_evercare',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.private,
      ),
    ),
    androidScheduleMode: exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
    payload: payload,
  );

  static String _channelId(ReminderKind kind) =>
      'evercare_${kind.name}_reminders_v1';

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
