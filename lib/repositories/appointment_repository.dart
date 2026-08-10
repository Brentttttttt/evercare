import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';

class AppointmentRepository {
  const AppointmentRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Sign in to access appointments.');
    return id;
  }

  Future<List<Appointment>> fetchAll() async {
    final userId = _userId;
    try {
      // This uses the database clock, so a changed or inaccurate phone clock
      // cannot prematurely mark a medical visit as missed. A failed sync must
      // never hide appointments that can still be displayed honestly using
      // the model's derived state.
      await _client.rpc('reconcile_missed_appointments');
    } catch (_) {
      // Best-effort in-app reconciliation retries on the next refresh/resume.
    }
    final rows = await _client
        .from('appointments')
        .select()
        .eq('user_id', userId)
        .order('starts_at');
    return rows.map(Appointment.fromJson).toList(growable: false);
  }

  Future<void> create({
    required String title,
    required String doctorName,
    required String specialty,
    required DateTime startsAt,
    required String clinic,
    required String address,
    required String notes,
  }) async {
    await _client.from('appointments').insert({
      'user_id': _userId,
      'title': title.trim(),
      'doctor_name': doctorName.trim(),
      'specialty': specialty.trim(),
      'starts_at': startsAt.toUtc().toIso8601String(),
      'clinic': clinic.trim(),
      'address': address.trim(),
      'notes': notes.trim(),
      'status': AppointmentStatus.upcoming.name,
    });
  }

  Future<void> update(
    String id, {
    required String title,
    required String doctorName,
    required String specialty,
    required DateTime startsAt,
    required String clinic,
    required String address,
    required String notes,
    required AppointmentStatus status,
  }) async {
    if (status != AppointmentStatus.upcoming) {
      throw StateError('Only an upcoming appointment can be edited.');
    }
    // `status` remains in this public method for compatibility with the
    // existing form callers, but ordinary detail edits must never overwrite a
    // newer server outcome such as Completed or Missed.
    final updated = await _client
        .from('appointments')
        .update({
          'title': title.trim(),
          'doctor_name': doctorName.trim(),
          'specialty': specialty.trim(),
          'starts_at': startsAt.toUtc().toIso8601String(),
          'clinic': clinic.trim(),
          'address': address.trim(),
          'notes': notes.trim(),
        })
        .eq('id', id)
        .eq('user_id', _userId)
        .eq('status', AppointmentStatus.upcoming.name)
        .select('id');
    if (updated.isEmpty) {
      throw StateError(
        'This appointment changed. Refresh it before editing again.',
      );
    }
  }

  Future<void> setStatus(String id, AppointmentStatus status) async {
    if (status == AppointmentStatus.completed) {
      await markCompleted(id);
      return;
    }
    if (status == AppointmentStatus.cancelled) {
      await _client.rpc('cancel_appointment', params: {'p_appointment_id': id});
      return;
    }
    throw ArgumentError.value(
      status,
      'status',
      'Only completion and cancellation are supported outcome transitions.',
    );
  }

  Future<void> markCompleted(String id) async {
    if (_client.auth.currentUser?.id == null) {
      throw StateError('Sign in to access appointments.');
    }
    await _client.rpc('complete_appointment', params: {'p_appointment_id': id});
  }

  Future<void> delete(String id) async {
    await _client
        .from('appointments')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
