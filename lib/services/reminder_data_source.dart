import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';
import '../models/medication.dart';
import '../models/medication_dose.dart';

class ReminderSnapshot {
  const ReminderSnapshot({
    required this.medications,
    required this.appointments,
    required this.doseEvents,
  });
  final List<Medication> medications;
  final List<Appointment> appointments;
  final List<MedicationDose> doseEvents;
}

abstract interface class ReminderDataSource {
  String? get currentUserId;
  Stream<String?> get authChanges;
  Future<ReminderSnapshot> load(String userId, DateTime now);
}

/// Read-only snapshot: notification delivery never records a dose as taken or
/// changes appointment attendance. Those remain explicit actions in the app.
class SupabaseReminderDataSource implements ReminderDataSource {
  const SupabaseReminderDataSource(this.client);
  final SupabaseClient client;

  @override
  String? get currentUserId => client.auth.currentUser?.id;

  @override
  Stream<String?> get authChanges => client.auth.onAuthStateChange
      .map((event) => event.session?.user.id)
      .distinct();

  @override
  Future<ReminderSnapshot> load(String userId, DateTime now) async {
    if (currentUserId != userId) throw StateError('Reminder account changed.');
    final start = now.toUtc().subtract(const Duration(days: 1));
    final end = now.toUtc().add(const Duration(days: 31));
    final rows = await Future.wait([
      client.from('medications').select().eq('user_id', userId),
      client
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .eq('status', 'upcoming')
          .gte('starts_at', now.toUtc().toIso8601String()),
      client
          .from('medication_dose_events')
          .select()
          .eq('user_id', userId)
          .gte('scheduled_for', start.toIso8601String())
          .lte('scheduled_for', end.toIso8601String()),
    ]).timeout(const Duration(seconds: 15));
    if (currentUserId != userId) throw StateError('Reminder account changed.');
    return ReminderSnapshot(
      medications: rows[0].map(Medication.fromJson).toList(growable: false),
      appointments: rows[1].map(Appointment.fromJson).toList(growable: false),
      doseEvents: rows[2].map(MedicationDose.fromJson).toList(growable: false),
    );
  }
}
