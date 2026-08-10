import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medication.dart';
import '../models/medication_dose.dart';

class MedicationOverview {
  const MedicationOverview({
    required this.medications,
    required this.todayDoses,
  });

  final List<Medication> medications;
  final List<MedicationDoseOccurrence> todayDoses;
}

class MedicationRepository {
  const MedicationRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Sign in to access medications.');
    return id;
  }

  Future<List<Medication>> fetchAll() async {
    return _fetchAll(_userId);
  }

  Future<List<Medication>> _fetchAll(String userId) async {
    final rows = await _client
        .from('medications')
        .select()
        .eq('user_id', userId)
        .order('is_active', ascending: false)
        .order('schedule_time');
    return rows.map(Medication.fromJson).toList(growable: false);
  }

  Future<MedicationOverview> fetchOverview({DateTime? now}) async {
    final userId = _userId;
    final instant = (now ?? DateTime.now()).toUtc();
    final medications = await _fetchAll(userId);
    final dayRange = _philippineDayRange(instant);
    final queryStart = dayRange.start.subtract(const Duration(days: 1));
    final rows = await _client
        .from('medication_dose_events')
        .select()
        .eq('user_id', userId)
        .gte('scheduled_for', queryStart.toIso8601String())
        .lt('scheduled_for', dayRange.end.toIso8601String())
        .order('scheduled_for');
    final doses = rows.map(MedicationDose.fromJson).toList(growable: false);
    final dosesByOccurrence = <String, MedicationDose>{
      for (final dose in doses)
        _doseKey(dose.medicationId, dose.scheduledFor): dose,
    };
    final engine = MedicationScheduleEngine(now: () => instant);
    final todayDoses = <MedicationDoseOccurrence>[];
    final terminalDoseTodayByMedication = <String, MedicationDose>{
      for (final dose in doses)
        if (!dose.scheduledFor.isBefore(dayRange.start) &&
            dose.scheduledFor.isBefore(dayRange.end) &&
            (dose.status == MedicationDoseStatus.taken ||
                dose.status == MedicationDoseStatus.skipped))
          dose.medicationId: dose,
    };
    for (final medication in medications) {
      // Carry a late-night dose across midnight until its one-hour outcome is
      // reconciled. If the medication was edited after that occurrence, do
      // not reconstruct an old schedule from its new values.
      final previousScheduledFor = engine.previousMidnightCarryover(
        medication,
        at: instant,
      );
      final updatedAt = medication.updatedAt?.toUtc();
      if (previousScheduledFor != null &&
          (updatedAt == null || !updatedAt.isAfter(previousScheduledFor))) {
        final previousDose =
            dosesByOccurrence[_doseKey(medication.id, previousScheduledFor)];
        final previousState = engine.resolveState(
          scheduledFor: previousScheduledFor,
          dose: previousDose,
          at: instant,
        );
        if (previousState == MedicationDoseState.due ||
            previousState == MedicationDoseState.missed) {
          todayDoses.add(
            MedicationDoseOccurrence(
              medication: medication,
              scheduledFor: previousScheduledFor,
              state: previousState,
              dose: previousDose,
            ),
          );
        }
      }

      // A same-day Taken/Skipped event remains authoritative if the caregiver
      // edits the reminder time later that day. Never invent a second dose.
      final terminalDose = terminalDoseTodayByMedication[medication.id];
      if (terminalDose != null) {
        todayDoses.add(
          MedicationDoseOccurrence(
            medication: medication,
            scheduledFor: terminalDose.scheduledFor,
            state: engine.resolveState(
              scheduledFor: terminalDose.scheduledFor,
              dose: terminalDose,
              at: instant,
            ),
            dose: terminalDose,
          ),
        );
        continue;
      }
      final scheduledFor = engine.todayOccurrence(medication, at: instant);
      if (scheduledFor != null) {
        final dose = dosesByOccurrence[_doseKey(medication.id, scheduledFor)];
        final occurrence = engine.currentDose(
          medication,
          dose: dose,
          at: instant,
        );
        if (occurrence != null) todayDoses.add(occurrence);
      }
    }
    todayDoses.sort(
      (first, second) => first.scheduledFor.compareTo(second.scheduledFor),
    );

    // A background service is intentionally not implied. Missed state is
    // reconciled whenever the signed-in user opens or resumes this UI.
    await Future.wait(
      todayDoses
          .where(
            (occurrence) =>
                occurrence.state == MedicationDoseState.missed &&
                occurrence.dose?.status != MedicationDoseStatus.missed,
          )
          .map((occurrence) async {
            try {
              await markMissed(occurrence);
            } catch (_) {
              // Keep the derived Missed state visible. A later in-app refresh
              // retries persistence instead of hiding otherwise valid data.
            }
          }),
    );

    return MedicationOverview(
      medications: List.unmodifiable(medications),
      todayDoses: List.unmodifiable(todayDoses),
    );
  }

  Future<void> create({
    required String name,
    required String dosage,
    required String purpose,
    required Set<int> scheduleDays,
    required String instructions,
    required String scheduleTime,
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isActive,
  }) async {
    final userId = _userId;
    final days = _validatedScheduleDays(scheduleDays);
    await _client.from('medications').insert({
      'user_id': userId,
      'name': name.trim(),
      'dosage': dosage.trim(),
      'purpose': purpose.trim(),
      'frequency': _frequencyForDays(days),
      'schedule_days': days,
      'instructions': instructions.trim(),
      'schedule_time': scheduleTime,
      'start_date': _dateOnly(startDate),
      'end_date': _dateOnly(endDate),
      'is_active': isActive,
    });
  }

  Future<void> update(
    String id, {
    required String name,
    required String dosage,
    required String purpose,
    required Set<int> scheduleDays,
    required String instructions,
    required String scheduleTime,
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isActive,
  }) async {
    final userId = _userId;
    final days = _validatedScheduleDays(scheduleDays);
    final updated = await _client
        .from('medications')
        .update({
          'name': name.trim(),
          'dosage': dosage.trim(),
          'purpose': purpose.trim(),
          'frequency': _frequencyForDays(days),
          'schedule_days': days,
          'instructions': instructions.trim(),
          'schedule_time': scheduleTime,
          'start_date': _dateOnly(startDate),
          'end_date': _dateOnly(endDate),
          'is_active': isActive,
          if (isActive) 'completed_at': null,
        })
        .eq('id', id)
        .eq('user_id', userId)
        .select('id');
    if (updated.isEmpty) {
      throw StateError('The medication is no longer available.');
    }
  }

  Future<void> markTaken(MedicationDoseOccurrence occurrence) async {
    final userId = _userId;
    if (occurrence.medication.userId != userId) {
      throw StateError(
        'This medication does not belong to the signed-in user.',
      );
    }
    await _client.rpc(
      'record_medication_dose_taken',
      params: {
        'p_medication_id': occurrence.medication.id,
        'p_scheduled_for': occurrence.scheduledFor.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> markMissed(MedicationDoseOccurrence occurrence) async {
    final userId = _userId;
    if (occurrence.medication.userId != userId) return;
    await _client.rpc(
      'record_medication_dose_missed',
      params: {
        'p_medication_id': occurrence.medication.id,
        'p_scheduled_for': occurrence.scheduledFor.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> markCompleted(String id) async {
    if (_client.auth.currentUser?.id == null) {
      throw StateError('Sign in to access medications.');
    }
    await _client.rpc('complete_medication', params: {'p_medication_id': id});
  }

  Future<void> delete(String id) async {
    final userId = _userId;
    final deleted = await _client
        .from('medications')
        .delete()
        .eq('id', id)
        .eq('user_id', userId)
        .select('id');
    if (deleted.isEmpty) {
      throw StateError('The medication is no longer available.');
    }
  }
}

({DateTime start, DateTime end}) _philippineDayRange(DateTime instant) {
  final wallClock = MedicationScheduleEngine.toPhilippineWallClock(instant);
  final wallStart = DateTime.utc(
    wallClock.year,
    wallClock.month,
    wallClock.day,
  );
  final start = wallStart.subtract(
    MedicationScheduleEngine.philippineUtcOffset,
  );
  return (start: start, end: start.add(const Duration(days: 1)));
}

String _doseKey(String medicationId, DateTime scheduledFor) =>
    '$medicationId|${scheduledFor.toUtc().toIso8601String()}';

List<int> _validatedScheduleDays(Set<int> values) {
  final days =
      values
          .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
          .toSet()
          .toList()
        ..sort();
  if (days.isEmpty || days.length != values.length) {
    throw ArgumentError.value(
      values,
      'scheduleDays',
      'Choose one or more valid weekdays.',
    );
  }
  return days;
}

String _frequencyForDays(List<int> days) {
  if (days.length == 7) return 'Every day';
  if (_sameDays(days, const [1, 2, 3, 4, 5])) return 'Weekdays';
  if (_sameDays(days, const [6, 7])) return 'Weekends';
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days.map((day) => labels[day - 1]).join(', ');
}

bool _sameDays(List<int> actual, List<int> expected) {
  if (actual.length != expected.length) return false;
  for (var index = 0; index < actual.length; index++) {
    if (actual[index] != expected[index]) return false;
  }
  return true;
}

String? _dateOnly(DateTime? value) {
  if (value == null) return null;
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
