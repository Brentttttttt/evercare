import 'dart:async';
import 'dart:convert';

import 'package:evercare/models/appointment.dart';
import 'package:evercare/models/medication.dart';
import 'package:evercare/models/scheduled_reminder.dart';
import 'package:evercare/services/phone_notification_driver.dart';
import 'package:evercare/services/phone_reminder_service.dart';
import 'package:evercare/services/reminder_changes.dart';
import 'package:evercare/services/reminder_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 8, 10);
  late _FakeSource source;
  late _FakeDriver driver;
  late PhoneReminderService service;
  late List<ReminderNotificationTarget?> opened;
  var disposed = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReminderChanges.onChanged = null;
    ReminderChanges.onSigningOut = null;
    source = _FakeSource();
    driver = _FakeDriver();
    opened = [];
    disposed = false;
    service = PhoneReminderService(
      source: source,
      driver: driver,
      now: () => now,
      onOpenReminder: opened.add,
    );
  });

  tearDown(() async {
    if (!disposed) service.dispose();
    await source.auth.close();
    ReminderChanges.onChanged = null;
    ReminderChanges.onSigningOut = null;
  });

  Future<void> enableWithMedication() async {
    source.snapshot = _snapshot(medications: [_medication()]);
    await service.initialize();
    await service.enable();
    expect(service.enabled, isTrue);
    expect(service.scheduledCount, 2);
  }

  test(
    'initialization checks permission but never prompts or loads while disabled',
    () async {
      await service.initialize();
      await service.initialize();

      expect(service.initialized, isTrue);
      expect(service.supported, isTrue);
      expect(service.signedIn, isTrue);
      expect(service.enabled, isFalse);
      expect(driver.initializations, 1);
      expect(driver.permissionRequests, 0);
      expect(driver.exactRequests, 0);
      expect(source.loads, isEmpty);
      expect(driver.scheduled, isEmpty);
    },
  );

  test(
    'offers an explanation once per signed-in account without OS prompting',
    () async {
      expect(await service.shouldOfferPermissionPrompt(), isTrue);
      expect(await service.shouldOfferPermissionPrompt(), isFalse);
      expect(driver.permissionRequests, 0);
      source.userId = 'user-2';
      await service.refresh();
      expect(await service.shouldOfferPermissionPrompt(), isTrue);
      expect(await service.shouldOfferPermissionPrompt(), isFalse);
      source.userId = null;
      await service.refresh();
      expect(await service.shouldOfferPermissionPrompt(), isFalse);
    },
  );

  test(
    'denied permission leaves scheduling disabled with actionable feedback',
    () async {
      driver.allowed = false;
      await service.initialize();
      await service.enable();

      expect(driver.permissionRequests, 1);
      expect(service.enabled, isFalse);
      expect(service.notificationsAllowed, isFalse);
      expect(service.error, contains('permission was not granted'));
      expect(source.loads, isEmpty);
      expect(driver.alarms, isEmpty);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool('evercare.phone_reminders.enabled.user-1.v1'),
        isFalse,
      );
    },
  );

  test(
    'permission grant schedules future alarms and saves ownership and coverage',
    () async {
      driver.allowed = false;
      driver.allowAfterRequest = true;
      await enableWithMedication();

      expect(driver.permissionRequests, 1);
      expect(service.notificationsAllowed, isTrue);
      expect(service.exactAlarmsAllowed, isFalse);
      expect(driver.scheduled, hasLength(2));
      expect(driver.exactModes, everyElement(isFalse));
      expect(service.scheduledThrough, DateTime.utc(2026, 8, 11, 1));
      expect(service.lastSyncedAt, now);
      expect(service.error, isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString('evercare.phone_reminders.owner.v1'),
        'user-1',
      );
      expect(
        preferences.getString('evercare.phone_reminders.manifest.v1'),
        isNotEmpty,
      );
    },
  );

  test(
    'unchanged refresh does not reschedule existing operating-system alarms',
    () async {
      await enableWithMedication();
      final initialCount = driver.scheduled.length;
      await service.refresh();
      await service.refresh();

      expect(driver.scheduled, hasLength(initialCount));
      expect(driver.alarms, hasLength(2));
      expect(service.error, isNull);
    },
  );

  test(
    'restores an alarm missing from the operating system on refresh',
    () async {
      await enableWithMedication();
      final missingId = driver.alarms.keys.first;
      driver.alarms.remove(missingId);
      await service.refresh();

      expect(driver.scheduled, hasLength(3));
      expect(driver.scheduled.last.id, missingId);
      expect(driver.alarms, hasLength(2));
    },
  );

  test(
    'explicit exact-timing grant replaces inexact alarms without another notification prompt',
    () async {
      await enableWithMedication();
      driver.exactAfterRequest = true;
      await service.enableExactTiming();

      expect(driver.exactRequests, 1);
      expect(driver.permissionRequests, 1);
      expect(service.exactAlarmsAllowed, isTrue);
      expect(driver.exactModes, [false, false, true, true]);
      expect(driver.alarms, hasLength(2));
    },
  );

  test(
    'successful edit cancels the obsolete resource before a failed refresh',
    () async {
      source.snapshot = _snapshot(
        medications: [
          _medication(),
          _medication(id: 'unrelated-med'),
        ],
      );
      await service.initialize();
      await service.enable();
      final editedIds = driver.alarms.entries
          .where(
            (entry) =>
                ReminderNotificationTarget.tryParse(entry.value)?.resourceId ==
                'med-1',
          )
          .map((entry) => entry.key)
          .toSet();
      source.onLoad = (_, _) async {
        expect(editedIds.any(driver.alarms.containsKey), isFalse);
        throw StateError('offline after successful save');
      };

      await ReminderChanges.changed('user-1', ReminderKind.medication, 'med-1');

      expect(driver.cancelled.toSet().containsAll(editedIds), isTrue);
      expect(driver.alarms, hasLength(2));
      expect(service.scheduledCount, 2);
      expect(service.error, contains('Could not update phone reminders'));
    },
  );

  test(
    'successful deletion cancels obsolete appointment reminders before failed refresh',
    () async {
      source.snapshot = _snapshot(appointments: [_appointment()]);
      await service.initialize();
      await service.enable();
      expect(driver.alarms, hasLength(3));
      source.onLoad = (_, _) async {
        expect(driver.alarms, isEmpty);
        throw StateError('offline after successful deletion');
      };

      await ReminderChanges.changed(
        'user-1',
        ReminderKind.appointment,
        'appointment-1',
      );

      expect(driver.alarms, isEmpty);
      expect(service.scheduledCount, 0);
      expect(driver.cancelled, hasLength(3));
    },
  );

  test(
    'ordinary offline refresh preserves known alarms rather than clearing them',
    () async {
      await enableWithMedication();
      final initialAlarms = Map<int, String?>.from(driver.alarms);
      source.onLoad = (_, _) async => throw StateError('offline');
      await service.refresh();

      expect(driver.alarms, initialAlarms);
      expect(service.scheduledCount, 2);
      expect(service.error, isNotNull);
    },
  );

  test(
    'ordinary refreshed deletion removes alarms no longer present in snapshot',
    () async {
      await enableWithMedication();
      source.snapshot = _snapshot();
      await service.refresh();

      expect(driver.alarms, isEmpty);
      expect(service.scheduledCount, 0);
      expect(service.scheduledThrough, isNull);
    },
  );

  test(
    'an event from another account cannot cancel the signed-in schedule',
    () async {
      await enableWithMedication();
      final initialAlarms = Map<int, String?>.from(driver.alarms);
      final initialLoads = source.loads.length;

      await ReminderChanges.changed('user-2', ReminderKind.medication, 'med-1');

      expect(driver.alarms, initialAlarms);
      expect(source.loads, hasLength(initialLoads));
    },
  );

  test(
    'disabling persists opt-out and clears medication, visit, and test alarms',
    () async {
      await enableWithMedication();
      expect(await service.sendTestReminder(), isTrue);
      expect(driver.alarms, contains(phoneReminderTestId));
      await service.disable();
      await service.refresh();

      expect(service.enabled, isFalse);
      expect(driver.alarms, isEmpty);
      expect(service.scheduledCount, 0);
      expect(service.lastSyncedAt, isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool('evercare.phone_reminders.enabled.user-1.v1'),
        isFalse,
      );
    },
  );

  test(
    'permission revocation clears pending alarms and never re-prompts on resume',
    () async {
      await enableWithMedication();
      driver.allowed = false;
      await service.refresh();

      expect(service.notificationsAllowed, isFalse);
      expect(driver.alarms, isEmpty);
      expect(driver.permissionRequests, 1);
    },
  );

  test('logout hook cancels alarms before authentication is removed', () async {
    await enableWithMedication();
    await ReminderChanges.signingOut('user-1');

    expect(source.userId, 'user-1');
    expect(driver.alarms, isEmpty);
    source.userId = null;
    await service.refresh();
    expect(service.signedIn, isFalse);
    expect(service.enabled, isFalse);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('evercare.phone_reminders.owner.v1'), isNull);
  });

  test(
    'switching accounts clears old alarms and does not inherit opt-in',
    () async {
      await enableWithMedication();
      source.userId = 'user-2';
      await service.refresh();

      expect(driver.alarms, isEmpty);
      expect(service.enabled, isFalse);
      expect(service.signedIn, isTrue);
      expect(service.scheduledCount, 0);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString('evercare.phone_reminders.owner.v1'),
        'user-2',
      );
    },
  );

  test(
    'auth stream account changes trigger cancellation without explicit refresh',
    () async {
      await enableWithMedication();
      final cleared = Completer<void>();
      driver.onCancelAll = () {
        if (!cleared.isCompleted) cleared.complete();
      };
      source.userId = null;
      source.auth.add(null);
      await cleared.future;
      await service
          .refresh(); // Wait for the serialized auth refresh to finish.

      expect(driver.alarms, isEmpty);
      expect(service.signedIn, isFalse);
    },
  );

  test(
    'disable invalidates an in-flight fetch before its stale result schedules',
    () async {
      await enableWithMedication();
      final entered = Completer<void>();
      final delayed = Completer<ReminderSnapshot>();
      source.onLoad = (_, _) {
        entered.complete();
        return delayed.future;
      };
      final initialSchedules = driver.scheduled.length;
      final refresh = service.refresh();
      await entered.future;
      final disable = service.disable();
      delayed.complete(
        _snapshot(medications: [_medication(id: 'stale-new-med')]),
      );
      await Future.wait([refresh, disable]);

      expect(driver.scheduled, hasLength(initialSchedules));
      expect(driver.alarms, isEmpty);
      expect(service.enabled, isFalse);
    },
  );

  test(
    'logout invalidates an in-flight fetch and never schedules its stale result',
    () async {
      await enableWithMedication();
      final entered = Completer<void>();
      final delayed = Completer<ReminderSnapshot>();
      source.onLoad = (_, _) {
        entered.complete();
        return delayed.future;
      };
      final initialSchedules = driver.scheduled.length;
      final refresh = service.refresh();
      await entered.future;
      final logout = ReminderChanges.signingOut('user-1');
      delayed.complete(
        _snapshot(medications: [_medication(id: 'stale-new-med')]),
      );
      await Future.wait([refresh, logout]);

      expect(driver.scheduled, hasLength(initialSchedules));
      expect(driver.alarms, isEmpty);
    },
  );

  test(
    'account switch invalidates an in-flight fetch even before auth refresh runs',
    () async {
      await enableWithMedication();
      final entered = Completer<void>();
      final delayed = Completer<ReminderSnapshot>();
      source.onLoad = (_, _) {
        entered.complete();
        return delayed.future;
      };
      final initialSchedules = driver.scheduled.length;
      final refresh = service.refresh();
      await entered.future;
      source.userId = 'user-2';
      final switched = service.refresh();
      delayed.complete(
        _snapshot(medications: [_medication(id: 'stale-new-med')]),
      );
      await Future.wait([refresh, switched]);

      expect(driver.scheduled, hasLength(initialSchedules));
      expect(driver.alarms, isEmpty);
      expect(service.enabled, isFalse);
    },
  );

  test(
    'a newer edit invalidates an in-flight fetch before cancelling and replacing',
    () async {
      await enableWithMedication();
      final entered = Completer<void>();
      final delayed = Completer<ReminderSnapshot>();
      var requests = 0;
      source.onLoad = (_, _) {
        if (requests++ == 0) {
          entered.complete();
          return delayed.future;
        }
        return Future.value(
          _snapshot(),
        ); // The successful write removed this item.
      };
      final initialSchedules = driver.scheduled.length;
      final refresh = service.refresh();
      await entered.future;
      final changed = ReminderChanges.changed(
        'user-1',
        ReminderKind.medication,
        'med-1',
      );
      delayed.complete(_snapshot(medications: [_medication()]));
      await Future.wait([refresh, changed]);

      expect(driver.scheduled, hasLength(initialSchedules));
      expect(driver.alarms, isEmpty);
    },
  );

  test(
    'test reminder is user-driven, ten seconds ahead, and retained by ordinary sync',
    () async {
      expect(await service.sendTestReminder(), isFalse);
      expect(driver.testSchedules, isEmpty);
      await enableWithMedication();
      driver.exact = true;
      expect(await service.sendTestReminder(), isTrue);

      expect(driver.testSchedules.single, (
        userId: 'user-1',
        when: now.add(const Duration(seconds: 10)),
        exact: true,
      ));
      await service.refresh();
      expect(driver.alarms, contains(phoneReminderTestId));
    },
  );

  test('tap routing ignores malformed and cross-account payloads', () async {
    await enableWithMedication();
    final legitimate = driver.scheduled.first.payload;
    final otherAccount = jsonDecode(legitimate) as Map<String, dynamic>;
    otherAccount['userId'] = 'user-2';
    driver.tap?.call(jsonEncode(otherAccount));
    driver.tap?.call('not-json');
    driver.tap?.call('[]');
    driver.tap?.call(null);
    expect(opened, isEmpty);

    driver.tap?.call(legitimate);
    expect(opened.single?.resourceId, 'med-1');
    expect(opened.single?.kind, ReminderKind.medication);
    source.userId = null;
    driver.tap?.call(legitimate);
    expect(opened, hasLength(1));
  });

  test('test-notification taps accept only the current account', () async {
    await service.initialize();
    driver.tap?.call(
      jsonEncode({'version': 1, 'test': true, 'userId': 'user-2'}),
    );
    expect(opened, isEmpty);
    driver.tap?.call(
      jsonEncode({'version': 1, 'test': true, 'userId': 'user-1'}),
    );
    expect(opened, [null]);
  });

  test(
    'restored launch tap routes only after current owner is established',
    () async {
      await enableWithMedication();
      driver.launchPayload = driver.scheduled.first.payload;
      service.dispose();
      service = PhoneReminderService(
        source: source,
        driver: driver,
        now: () => now,
        onOpenReminder: opened.add,
      );
      await service.initialize();

      expect(opened.single?.userId, 'user-1');
      expect(opened.single?.resourceId, 'med-1');
    },
  );

  test(
    'same-owner offline startup restores saved coverage and preserves OS alarms',
    () async {
      await enableWithMedication();
      final initialAlarms = Map<int, String?>.from(driver.alarms);
      final initialCancels = driver.cancelAllCalls;
      driver.launchPayload = driver.scheduled.first.payload;
      service.dispose();
      source.onLoad = (_, _) async => throw StateError('offline at restart');
      service = PhoneReminderService(
        source: source,
        driver: driver,
        now: () => now,
        onOpenReminder: opened.add,
      );
      await service.initialize();

      expect(service.initialized, isTrue);
      expect(service.enabled, isTrue);
      expect(service.scheduledCount, 2);
      expect(service.scheduledThrough, DateTime.utc(2026, 8, 11, 1));
      expect(service.lastSyncedAt, now);
      expect(driver.alarms, initialAlarms);
      expect(driver.cancelAllCalls, initialCancels);
      expect(service.error, isNotNull);
      expect(opened.single?.userId, 'user-1');
      expect(opened.single?.resourceId, 'med-1');
    },
  );

  test(
    'startup as another account clears restored alarms even when offline',
    () async {
      await enableWithMedication();
      driver.launchPayload = driver.scheduled.first.payload;
      service.dispose();
      source.userId = 'user-2';
      source.onLoad = (_, _) async => throw StateError('offline at restart');
      service = PhoneReminderService(
        source: source,
        driver: driver,
        now: () => now,
        onOpenReminder: opened.add,
      );
      await service.initialize();

      expect(service.enabled, isFalse);
      expect(driver.alarms, isEmpty);
      expect(service.scheduledCount, 0);
      expect(service.lastSyncedAt, isNull);
      expect(opened, isEmpty);
    },
  );

  test(
    'normal disposal leaves Android alarms active and detaches callbacks',
    () async {
      await enableWithMedication();
      final initialAlarms = Map<int, String?>.from(driver.alarms);
      final initialCancels = driver.cancelAllCalls;
      service.dispose();
      disposed = true;
      driver.tap?.call(driver.scheduled.first.payload);

      expect(driver.alarms, initialAlarms);
      expect(driver.cancelAllCalls, initialCancels);
      expect(ReminderChanges.onChanged, isNull);
      expect(ReminderChanges.onSigningOut, isNull);
      expect(opened, isEmpty);
    },
  );

  test(
    'unsupported platform performs no plugin calls and never offers permission',
    () async {
      driver.isSupported = false;
      await service.initialize();
      await service.enable();
      await service.disable();
      await service.refresh();
      await service.enableExactTiming();
      await service.openSettings();

      expect(await service.sendTestReminder(), isFalse);
      expect(await service.shouldOfferPermissionPrompt(), isFalse);
      expect(service.initialized, isTrue);
      expect(service.supported, isFalse);
      expect(driver.initializations, 0);
      expect(driver.permissionRequests, 0);
      expect(driver.exactRequests, 0);
      expect(driver.settingsOpens, 0);
      expect(driver.cancelAllCalls, 0);
      expect(source.loads, isEmpty);
    },
  );

  test(
    'opening phone settings is explicit and does not prompt notification permission',
    () async {
      await service.initialize();
      await service.openSettings();

      expect(driver.settingsOpens, 1);
      expect(driver.permissionRequests, 0);
    },
  );
}

class _FakeSource implements ReminderDataSource {
  String? userId = 'user-1';
  final auth = StreamController<String?>.broadcast(sync: true);
  final loads = <String>[];
  ReminderSnapshot snapshot = _snapshot();
  Future<ReminderSnapshot> Function(String userId, DateTime now)? onLoad;

  @override
  String? get currentUserId => userId;

  @override
  Stream<String?> get authChanges => auth.stream;

  @override
  Future<ReminderSnapshot> load(String userId, DateTime now) async {
    loads.add(userId);
    return onLoad != null ? onLoad!(userId, now) : snapshot;
  }
}

class _FakeDriver implements PhoneNotificationDriver {
  bool isSupported = true;
  bool allowed = true;
  bool exact = false;
  bool? allowAfterRequest;
  bool? exactAfterRequest;
  int initializations = 0;
  int permissionRequests = 0;
  int exactRequests = 0;
  int settingsOpens = 0;
  int cancelAllCalls = 0;
  String? launchPayload;
  void Function(String? payload)? tap;
  void Function()? onCancelAll;
  final alarms = <int, String?>{};
  final scheduled = <ScheduledReminder>[];
  final exactModes = <bool>[];
  final cancelled = <int>[];
  final testSchedules = <({String userId, DateTime when, bool exact})>[];

  @override
  bool get supported => isSupported;

  @override
  Future<String?> initialize(void Function(String? payload) onTap) async {
    initializations++;
    tap = onTap;
    return launchPayload;
  }

  @override
  Future<PhoneNotificationPermissions> permissions() async =>
      PhoneNotificationPermissions(allowed: allowed, exact: exact);

  @override
  Future<void> requestPermission() async {
    permissionRequests++;
    allowed = allowAfterRequest ?? allowed;
  }

  @override
  Future<void> requestExactTiming() async {
    exactRequests++;
    exact = exactAfterRequest ?? exact;
  }

  @override
  Future<void> openSettings() async => settingsOpens++;

  @override
  Future<List<PendingPhoneReminder>> pending() async => [
    for (final entry in alarms.entries)
      PendingPhoneReminder(entry.key, entry.value),
  ];

  @override
  Future<void> schedule(
    ScheduledReminder reminder, {
    required bool exact,
  }) async {
    scheduled.add(reminder);
    exactModes.add(exact);
    alarms[reminder.id] = reminder.payload;
  }

  @override
  Future<void> scheduleTest(
    String userId,
    DateTime when, {
    required bool exact,
  }) async {
    testSchedules.add((userId: userId, when: when, exact: exact));
    alarms[phoneReminderTestId] = jsonEncode({
      'version': 1,
      'test': true,
      'userId': userId,
    });
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    alarms.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    alarms.clear();
    onCancelAll?.call();
  }
}

ReminderSnapshot _snapshot({
  List<Medication> medications = const [],
  List<Appointment> appointments = const [],
}) => ReminderSnapshot(
  medications: medications,
  appointments: appointments,
  doseEvents: const [],
);

Medication _medication({String id = 'med-1'}) => Medication(
  id: id,
  userId: 'user-1',
  name: 'Example medicine',
  dosage: '5 mg',
  purpose: '',
  frequency: '',
  instructions: '',
  scheduleTime: '09:00:00',
  startDate: DateTime(2026, 8, 10),
  endDate: DateTime(2026, 8, 11),
  isActive: true,
  scheduleDays: const [1, 2, 3, 4, 5, 6, 7],
);

Appointment _appointment() => Appointment(
  id: 'appointment-1',
  userId: 'user-1',
  title: 'Visit',
  doctorName: '',
  specialty: '',
  startsAt: DateTime.utc(2026, 8, 12, 3),
  clinic: '',
  address: '',
  notes: '',
  status: AppointmentStatus.upcoming,
);
