import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medication.dart';
import '../models/medication_dose.dart';

class DashboardSummary {
  const DashboardSummary({
    this.fullName,
    this.nextMedicationName,
    this.nextMedicationTime,
    this.nextMedicationDueNow = false,
    this.nextAppointmentTitle,
    this.nextAppointmentAt,
    this.nextAppointmentDueNow = false,
  });

  final String? fullName;
  final String? nextMedicationName;
  final String? nextMedicationTime;
  final bool nextMedicationDueNow;
  final String? nextAppointmentTitle;
  final DateTime? nextAppointmentAt;
  final bool nextAppointmentDueNow;
}

class DashboardRepository {
  const DashboardRepository(this._client);

  final SupabaseClient _client;

  Future<DashboardSummary> load() async {
    final user = _client.auth.currentUser;
    if (user == null) return const DashboardSummary();

    final now = DateTime.now().toUtc();
    try {
      await _client.rpc('reconcile_missed_appointments');
    } catch (_) {
      // A migration/network problem must not hide an otherwise useful Home
      // overview. The Appointments page retries this server-clock sync.
    }
    final wallClock = MedicationScheduleEngine.toPhilippineWallClock(now);
    final wallStart = DateTime.utc(
      wallClock.year,
      wallClock.month,
      wallClock.day,
    );
    final dayStart = wallStart.subtract(
      MedicationScheduleEngine.philippineUtcOffset,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    final results = await Future.wait<dynamic>([
      _client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle(),
      _client
          .from('medications')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('schedule_time'),
      _client
          .from('appointments')
          .select('title,starts_at')
          .eq('user_id', user.id)
          .eq('status', 'upcoming')
          .gt(
            'starts_at',
            now.subtract(const Duration(days: 1)).toIso8601String(),
          )
          .order('starts_at')
          .limit(1)
          .maybeSingle(),
      _client
          .from('medication_dose_events')
          .select()
          .eq('user_id', user.id)
          .gte('scheduled_for', dayStart.toIso8601String())
          .lt('scheduled_for', dayEnd.toIso8601String()),
    ]);

    final profile = results[0] as Map<String, dynamic>?;
    final appointment = results[2] as Map<String, dynamic>?;
    final medications = (results[1] as List<dynamic>)
        .map((row) => Medication.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
    final doses = (results[3] as List<dynamic>)
        .map((row) => MedicationDose.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
    final engine = MedicationScheduleEngine(now: () => now);
    final doseByKey = <String, MedicationDose>{
      for (final dose in doses)
        _doseKey(dose.medicationId, dose.scheduledFor): dose,
    };
    final terminalMedicationIds = doses
        .where(
          (dose) =>
              dose.status == MedicationDoseStatus.taken ||
              dose.status == MedicationDoseStatus.skipped,
        )
        .map((dose) => dose.medicationId)
        .toSet();
    final candidates =
        <({Medication medication, DateTime occurrence, bool dueNow})>[];
    for (final medication in medications) {
      if (terminalMedicationIds.contains(medication.id)) {
        final next = engine.nextOccurrence(medication, from: dayEnd);
        if (next != null) {
          candidates.add((
            medication: medication,
            occurrence: next,
            dueNow: false,
          ));
        }
        continue;
      }
      final today = engine.todayOccurrence(medication, at: now);
      if (today != null) {
        final dose = doseByKey[_doseKey(medication.id, today)];
        final state = engine.resolveState(
          scheduledFor: today,
          dose: dose,
          at: now,
        );
        if (state == MedicationDoseState.upcoming ||
            state == MedicationDoseState.due) {
          candidates.add((
            medication: medication,
            occurrence: today,
            dueNow: state == MedicationDoseState.due,
          ));
          continue;
        }
      }
      final next = engine.nextOccurrence(medication, from: now);
      if (next != null) {
        candidates.add((
          medication: medication,
          occurrence: next,
          dueNow: false,
        ));
      }
    }
    candidates.sort(
      (first, second) => first.occurrence.compareTo(second.occurrence),
    );
    final nextMedication = candidates.firstOrNull;
    final appointmentAt = appointment?['starts_at'] == null
        ? null
        : DateTime.parse(appointment!['starts_at'] as String).toLocal();
    return DashboardSummary(
      fullName: _nonEmpty(profile?['full_name']),
      nextMedicationName: nextMedication?.medication.name,
      nextMedicationTime: nextMedication == null
          ? null
          : _formatPhilippineTime(nextMedication.occurrence),
      nextMedicationDueNow: nextMedication?.dueNow ?? false,
      nextAppointmentTitle: _nonEmpty(appointment?['title']),
      nextAppointmentAt: appointmentAt,
      nextAppointmentDueNow:
          appointmentAt != null && !appointmentAt.toUtc().isAfter(now),
    );
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _formatPhilippineTime(DateTime value) {
    final wallClock = MedicationScheduleEngine.toPhilippineWallClock(value);
    final hour = wallClock.hour;
    final minute = wallClock.minute.toString().padLeft(2, '0');
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute ${hour >= 12 ? 'PM' : 'AM'}';
  }
}

String _doseKey(String medicationId, DateTime scheduledFor) =>
    '$medicationId|${scheduledFor.toUtc().toIso8601String()}';
