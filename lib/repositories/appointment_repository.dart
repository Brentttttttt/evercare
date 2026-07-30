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
    final rows = await _client
        .from('appointments')
        .select()
        .eq('user_id', _userId)
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
    await _client
        .from('appointments')
        .update({
          'title': title.trim(),
          'doctor_name': doctorName.trim(),
          'specialty': specialty.trim(),
          'starts_at': startsAt.toUtc().toIso8601String(),
          'clinic': clinic.trim(),
          'address': address.trim(),
          'notes': notes.trim(),
          'status': status.name,
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> setStatus(String id, AppointmentStatus status) async {
    await _client
        .from('appointments')
        .update({'status': status.name})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) async {
    await _client
        .from('appointments')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
