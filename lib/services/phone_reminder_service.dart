import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/scheduled_reminder.dart';
import 'phone_notification_driver.dart';
import 'phone_reminder_controller.dart';
import 'reminder_changes.dart';
import 'reminder_data_source.dart';
import 'reminder_schedule_planner.dart';

/// Owns only device reminders, not the server-backed notifications inbox.
/// Operations are serialized; generation checks prevent old account reads from
/// scheduling alarms after logout, account switches, or a newer successful edit.
class PhoneReminderService extends PhoneReminderController {
  PhoneReminderService({
    required ReminderDataSource source,
    required PhoneNotificationDriver driver,
    DateTime Function()? now,
    this.onOpenReminder,
  }) : _source = source,
       _driver = driver,
       _now = now ?? DateTime.now;

  final ReminderDataSource _source;
  final PhoneNotificationDriver _driver;
  final DateTime Function() _now;
  final void Function(ReminderNotificationTarget? target)? onOpenReminder;
  static const _ownerKey = 'evercare.phone_reminders.owner.v1';
  static const _manifestKey = 'evercare.phone_reminders.manifest.v1';
  static const _syncKey = 'evercare.phone_reminders.synced.v1';
  static String _enabledKey(String id) =>
      'evercare.phone_reminders.enabled.$id.v1';
  static String _promptKey(String id) =>
      'evercare.phone_reminders.prompt.$id.v1';

  SharedPreferences? _preferences;
  StreamSubscription<String?>? _authSubscription;
  Future<void>? _initializing;
  Future<void> _serial = Future.value();
  String? _userId;
  int _generation = 0;
  bool _disposed = false;
  final Map<int, _ReminderRecord> _records = {};

  @override
  bool get supported => _driver.supported;
  @override
  bool initialized = false;
  @override
  bool get signedIn => _source.currentUserId != null;
  @override
  bool enabled = false;
  @override
  bool notificationsAllowed = false;
  @override
  bool exactAlarmsAllowed = false;
  @override
  bool busy = false;
  @override
  int get scheduledCount => _records.values
      .where((record) => record.when.isAfter(_now().toUtc()))
      .length;
  @override
  DateTime? get scheduledThrough {
    final future =
        _records.values
            .map((record) => record.when)
            .where((when) => when.isAfter(_now().toUtc()))
            .toList()
          ..sort();
    return future.isEmpty ? null : future.last;
  }

  @override
  DateTime? lastSyncedAt;
  @override
  String? error;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (!supported) {
      initialized = true;
      _notify();
      return;
    }
    String? launchPayload;
    try {
      launchPayload = await _driver.initialize(_handleTap);
      _preferences = await SharedPreferences.getInstance();
      _restoreManifest();
      ReminderChanges.onChanged = _changed;
      ReminderChanges.onSigningOut = _signingOut;
      _authSubscription = _source.authChanges.listen((_) {
        unawaited(refresh());
      });
      await _refreshCurrentUser();
    } catch (_) {
      error = 'Phone reminders could not initialize. Please reopen EverCare.';
    } finally {
      initialized = true;
      _notify();
      // Opening an already-delivered alert must not depend on an online sync.
      // _handleTap still validates its payload against the signed-in account.
      _handleTap(launchPayload);
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _serial.then((_) => operation());
    _serial = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<bool> _perform(Future<void> Function() operation) async {
    await initialize();
    if (!supported || _disposed || _preferences == null) return false;
    return _enqueue(() async {
      if (_disposed) return false;
      busy = true;
      error = null;
      _notify();
      try {
        await operation();
        return true;
      } catch (_) {
        error =
            'Could not update phone reminders. Existing reminders are kept where possible. Check your connection and try again.';
        return false;
      } finally {
        busy = false;
        _notify();
      }
    });
  }

  @override
  Future<void> refresh() async {
    _generation++;
    await _perform(_refreshCurrentUser);
  }

  Future<void> _refreshCurrentUser() async {
    final userId = _source.currentUserId;
    if (_preferences!.getString(_ownerKey) != userId || _userId != userId) {
      // A process restart with the same owner keeps its saved schedules. A
      // different or absent owner must never inherit the former user's alarms.
      if (_preferences!.getString(_ownerKey) != userId || userId == null) {
        await _clearAll();
      }
      _userId = userId;
      if (userId == null) {
        await _preferences!.remove(_ownerKey);
      } else {
        await _preferences!.setString(_ownerKey, userId);
      }
    }
    enabled =
        userId != null && (_preferences!.getBool(_enabledKey(userId)) ?? false);
    final permissions = await _driver.permissions();
    notificationsAllowed = permissions.allowed;
    exactAlarmsAllowed = permissions.exact;
    if (userId == null || !enabled || !notificationsAllowed) {
      await _clearAll();
      return;
    }
    final generation = _generation;
    final snapshot = await _source.load(userId, _now());
    if (!_isCurrent(userId, generation)) return;
    final plan = const ReminderSchedulePlanner().plan(
      userId: userId,
      now: _now(),
      medications: snapshot.medications,
      appointments: snapshot.appointments,
      doseEvents: snapshot.doseEvents,
    );
    await _applyPlan(userId, generation, plan);
  }

  bool _isCurrent(String userId, int generation) =>
      !_disposed &&
      generation == _generation &&
      _source.currentUserId == userId;

  Future<void> _applyPlan(
    String userId,
    int generation,
    List<ScheduledReminder> plan,
  ) async {
    final pending = {for (final item in await _driver.pending()) item.id: item};
    final desired = {for (final reminder in plan) reminder.id: reminder};
    final previousIds = {...pending.keys, ..._records.keys}
      ..remove(phoneReminderTestId);
    for (final id in previousIds.difference(desired.keys.toSet())) {
      if (!_isCurrent(userId, generation)) return;
      await _driver.cancel(id);
      _records.remove(id);
    }
    try {
      for (final reminder in plan) {
        if (!_isCurrent(userId, generation)) return;
        if (!reminder.scheduledForUtc.isAfter(_now().toUtc())) continue;
        final record = _ReminderRecord.fromReminder(
          reminder,
          exactAlarmsAllowed,
        );
        if (!pending.containsKey(reminder.id) ||
            _records[reminder.id]?.signature != record.signature) {
          await _driver.schedule(reminder, exact: exactAlarmsAllowed);
        }
        _records[reminder.id] = record;
      }
      if (!_isCurrent(userId, generation)) return;
      lastSyncedAt = _now().toUtc();
      await _preferences!.setString(_syncKey, lastSyncedAt!.toIso8601String());
    } finally {
      await _saveManifest();
    }
  }

  @override
  Future<void> enable() async {
    await _perform(() async {
      final userId = _source.currentUserId;
      if (userId == null) return;
      await _driver.requestPermission();
      final permission = await _driver.permissions();
      if (_source.currentUserId != userId) return;
      await _preferences!.setBool(_enabledKey(userId), permission.allowed);
      await _refreshCurrentUser();
      if (!permission.allowed) {
        error =
            'Notification permission was not granted. You can allow it in your phone settings.';
      }
    });
  }

  @override
  Future<void> disable() async {
    _generation++;
    await _perform(() async {
      final userId = _source.currentUserId;
      if (userId != null) {
        await _preferences!.setBool(_enabledKey(userId), false);
      }
      enabled = false;
      await _clearAll();
    });
  }

  @override
  Future<void> enableExactTiming() async {
    await _perform(() async {
      await _driver.requestExactTiming();
      await _refreshCurrentUser();
    });
  }

  @override
  Future<void> openSettings() async {
    await _perform(_driver.openSettings);
  }

  @override
  Future<bool> sendTestReminder() async {
    var scheduled = false;
    await _perform(() async {
      final userId = _source.currentUserId;
      final permission = await _driver.permissions();
      notificationsAllowed = permission.allowed;
      exactAlarmsAllowed = permission.exact;
      if (userId == null || !enabled || !permission.allowed) {
        error =
            'Enable phone reminders and allow notifications before sending a test.';
        return;
      }
      await _driver.scheduleTest(
        userId,
        _now().toUtc().add(const Duration(seconds: 10)),
        exact: permission.exact,
      );
      scheduled = true;
    });
    return scheduled;
  }

  @override
  Future<bool> shouldOfferPermissionPrompt() async {
    await initialize();
    final userId = _source.currentUserId;
    if (!supported ||
        _disposed ||
        _preferences == null ||
        userId == null ||
        (_preferences!.getBool(_promptKey(userId)) ?? false)) {
      return false;
    }
    await _preferences!.setBool(_promptKey(userId), true);
    return !enabled;
  }

  Future<void> _changed(
    String userId,
    ReminderKind kind,
    String? resourceId,
  ) async {
    if (_source.currentUserId != userId) return;
    _generation++;
    await _perform(() async {
      if (_source.currentUserId != userId) return;
      // Cancel the old schedule BEFORE fetching. An offline refresh after a
      // successful deletion/edit must not leave that obsolete alarm active.
      if (resourceId != null) await _cancelResource(userId, kind, resourceId);
      await _refreshCurrentUser();
    });
  }

  Future<void> _cancelResource(
    String userId,
    ReminderKind kind,
    String resourceId,
  ) async {
    final items = <int, String?>{
      for (final record in _records.entries) record.key: record.value.payload,
      for (final item in await _driver.pending()) item.id: item.payload,
    };
    for (final item in items.entries) {
      final target = ReminderNotificationTarget.tryParse(item.value);
      if (target?.userId == userId &&
          target?.kind == kind &&
          target?.resourceId == resourceId) {
        await _driver.cancel(item.key);
        _records.remove(item.key);
      }
    }
    await _saveManifest();
  }

  Future<void> _signingOut(String userId) async {
    _generation++;
    await _perform(() async {
      if (_userId == userId) await _clearAll();
    });
  }

  Future<void> _clearAll() async {
    await _driver.cancelAll();
    _records.clear();
    lastSyncedAt = null;
    await _preferences!.remove(_manifestKey);
    await _preferences!.remove(_syncKey);
  }

  void _handleTap(String? payload) {
    if (_disposed || payload == null || _source.currentUserId == null) return;
    final target = ReminderNotificationTarget.tryParse(payload);
    if (target != null && target.userId == _source.currentUserId) {
      onOpenReminder?.call(target);
      return;
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic> &&
          decoded['version'] == 1 &&
          decoded['test'] == true &&
          decoded['userId'] == _source.currentUserId) {
        onOpenReminder?.call(null);
      }
    } on FormatException {
      // Untrusted or stale notification payloads do not navigate.
    }
  }

  void _restoreManifest() {
    final raw = _preferences!.getString(_manifestKey);
    try {
      if (raw != null) {
        final items = jsonDecode(raw) as List;
        for (final item in items) {
          final record = _ReminderRecord.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          _records[record.id] = record;
        }
      }
      lastSyncedAt = DateTime.tryParse(_preferences!.getString(_syncKey) ?? '');
    } catch (_) {
      _records.clear();
      // OS pending payloads still allow safe replacement/cancellation.
    }
  }

  Future<void> _saveManifest() async {
    await _preferences!.setString(
      _manifestKey,
      jsonEncode([for (final record in _records.values) record.toJson()]),
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_authSubscription?.cancel());
    if (ReminderChanges.onChanged == _changed) ReminderChanges.onChanged = null;
    if (ReminderChanges.onSigningOut == _signingOut) {
      ReminderChanges.onSigningOut = null;
    }
    // Normal process shutdown must NOT cancel alarms entrusted to Android.
    super.dispose();
  }
}

class _ReminderRecord {
  const _ReminderRecord(this.id, this.payload, this.when, this.signature);
  factory _ReminderRecord.fromReminder(
    ScheduledReminder reminder,
    bool exact,
  ) => _ReminderRecord(
    reminder.id,
    reminder.payload,
    reminder.scheduledForUtc,
    jsonEncode([reminder.payload, reminder.title, reminder.body, exact]),
  );
  factory _ReminderRecord.fromJson(Map<String, dynamic> value) =>
      _ReminderRecord(
        value['id'] as int,
        value['payload'] as String,
        DateTime.parse(value['when'] as String).toUtc(),
        value['signature'] as String,
      );
  final int id;
  final String payload;
  final DateTime when;
  final String signature;
  Map<String, dynamic> toJson() => {
    'id': id,
    'payload': payload,
    'when': when.toIso8601String(),
    'signature': signature,
  };
}
