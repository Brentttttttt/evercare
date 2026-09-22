import 'dart:convert';

import '../models/appointment.dart';
import '../models/medication.dart';
import '../models/medication_dose.dart';
import '../models/scheduled_reminder.dart';

/// Plans bounded, one-shot device notifications without a running application.
///
/// Reconcile this rolling plan when the app opens/resumes or a record changes.
/// Medication times follow the existing Philippine wall-clock schedule. Visit
/// times are absolute instants. No reminder is inferred from free-text frequency.
class ReminderSchedulePlanner {
  const ReminderSchedulePlanner();

  static const defaultHorizonDays = 30;
  static const defaultMaxNotifications = 400;

  List<ScheduledReminder> plan({
    required String userId,
    required DateTime now,
    required Iterable<Medication> medications,
    required Iterable<Appointment> appointments,
    Iterable<MedicationDose> doseEvents = const [],
    int horizonDays = defaultHorizonDays,
    int maxNotifications = defaultMaxNotifications,
  }) {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'A signed-in user is required.',
      );
    }
    if (horizonDays < 1 || horizonDays > 366) {
      throw RangeError.range(horizonDays, 1, 366, 'horizonDays');
    }
    if (maxNotifications < 0 || maxNotifications > 10000) {
      throw RangeError.range(maxNotifications, 0, 10000, 'maxNotifications');
    }
    if (maxNotifications == 0) return const [];

    final nowUtc = now.toUtc();
    final cutoff = nowUtc.add(Duration(days: horizonDays));
    final wallNow = MedicationScheduleEngine.toPhilippineWallClock(nowUtc);
    final firstDate = DateTime.utc(wallNow.year, wallNow.month, wallNow.day);
    final engine = MedicationScheduleEngine(now: () => nowUtc);
    final terminalDays = <String>{};
    final missedOccurrences = <String>{};
    for (final dose in doseEvents) {
      if (dose.userId != userId) continue;
      if (dose.status == MedicationDoseStatus.taken ||
          dose.status == MedicationDoseStatus.skipped) {
        // A time edit must not invent a second dose on an already handled day.
        terminalDays.add(_dayKey(dose.medicationId, dose.scheduledFor));
      } else if (dose.status == MedicationDoseStatus.missed) {
        missedOccurrences.add(
          _occurrenceKey(dose.medicationId, dose.scheduledFor),
        );
      }
    }

    final candidates = <String, _Candidate>{};
    void add(_Candidate candidate) {
      if (candidate.scheduledForUtc.isAfter(nowUtc) &&
          !candidate.scheduledForUtc.isAfter(cutoff)) {
        candidates[candidate.key] = candidate;
      }
    }

    for (final medication in medications) {
      if (medication.userId != userId) continue;
      for (var day = 0; day <= horizonDays; day++) {
        final occurrence = engine.occurrenceForPhilippineDate(
          medication,
          firstDate.add(Duration(days: day)),
        );
        if (occurrence == null ||
            terminalDays.contains(_dayKey(medication.id, occurrence)) ||
            missedOccurrences.contains(
              _occurrenceKey(medication.id, occurrence),
            )) {
          continue;
        }
        add(
          _Candidate(
            userId: userId,
            resourceId: medication.id,
            kind: ReminderKind.medication,
            scheduledForUtc: occurrence,
            occurrenceUtc: occurrence,
            title: 'Medication reminder',
            body:
                'Scheduled for ${_philippineTimeLabel(occurrence)}. '
                'Open EverCare to review your medication schedule.',
          ),
        );
      }
    }

    for (final appointment in appointments) {
      if (appointment.userId != userId ||
          appointment.status != AppointmentStatus.upcoming ||
          appointment.completedAt != null) {
        continue;
      }
      final occurrence = appointment.startsAt.toUtc();
      for (final lead in const [
        Duration(days: 1),
        Duration(hours: 1),
        Duration.zero,
      ]) {
        add(
          _Candidate(
            userId: userId,
            resourceId: appointment.id,
            kind: ReminderKind.appointment,
            scheduledForUtc: occurrence.subtract(lead),
            occurrenceUtc: occurrence,
            title: 'Appointment reminder',
            body:
                'Appointment scheduled for ${_philippineTimeLabel(occurrence)}. '
                'Open EverCare for details.',
          ),
        );
      }
    }

    // Apply the device limit only after merging both resource types. Iterating
    // through medication records first must not crowd out a nearer appointment.
    final ordered = candidates.values.toList()
      ..sort((first, second) {
        final timeOrder = first.scheduledForUtc.compareTo(
          second.scheduledForUtc,
        );
        return timeOrder != 0 ? timeOrder : first.key.compareTo(second.key);
      });
    final usedIds = <int>{};
    final reminders = <ScheduledReminder>[];
    for (final candidate in ordered.take(maxNotifications)) {
      var id = _stablePositiveId(candidate.key);
      while (!usedIds.add(id)) {
        id = id == 0x7ffffffe ? 1 : id + 1;
      }
      reminders.add(
        ScheduledReminder(
          id: id,
          userId: candidate.userId,
          resourceId: candidate.resourceId,
          kind: candidate.kind,
          scheduledForUtc: candidate.scheduledForUtc,
          occurrenceUtc: candidate.occurrenceUtc,
          title: candidate.title,
          body: candidate.body,
        ),
      );
    }
    return List.unmodifiable(reminders);
  }
}

class _Candidate {
  const _Candidate({
    required this.userId,
    required this.resourceId,
    required this.kind,
    required this.scheduledForUtc,
    required this.occurrenceUtc,
    required this.title,
    required this.body,
  });

  final String userId;
  final String resourceId;
  final ReminderKind kind;
  final DateTime scheduledForUtc;
  final DateTime occurrenceUtc;
  final String title;
  final String body;

  String get key => jsonEncode([
    userId,
    kind.name,
    resourceId,
    occurrenceUtc.toIso8601String(),
    scheduledForUtc.toIso8601String(),
  ]);
}

String _dayKey(String medicationId, DateTime instant) {
  final wall = MedicationScheduleEngine.toPhilippineWallClock(instant);
  return jsonEncode([medicationId, wall.year, wall.month, wall.day]);
}

String _occurrenceKey(String medicationId, DateTime instant) =>
    jsonEncode([medicationId, instant.toUtc().toIso8601String()]);

String _philippineTimeLabel(DateTime instant) {
  final wall = MedicationScheduleEngine.toPhilippineWallClock(instant);
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${wall.year}-${pad(wall.month)}-${pad(wall.day)} '
      '${pad(wall.hour)}:${pad(wall.minute)} PHT';
}

/// Explicit 31-bit arithmetic is stable across launches and Dart platforms;
/// Object.hash/String.hashCode are deliberately not used for persisted IDs.
int _stablePositiveId(String key) {
  var hash = 0;
  for (final byte in utf8.encode(key)) {
    hash = (hash * 31 + byte) & 0x7fffffff;
  }
  // Reserve the highest signed 32-bit ID for the settings test notification.
  return hash == 0 || hash == 0x7fffffff ? 1 : hash;
}
