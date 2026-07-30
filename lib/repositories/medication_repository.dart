import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/medication.dart';

class MedicationRepository {
  const MedicationRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Sign in to access medications.');
    return id;
  }

  Future<List<Medication>> fetchAll() async {
    final rows = await _client
        .from('medications')
        .select()
        .eq('user_id', _userId)
        .order('is_active', ascending: false)
        .order('schedule_time');
    return rows.map(Medication.fromJson).toList(growable: false);
  }

  Future<void> create({
    required String name,
    required String dosage,
    required String purpose,
    required String frequency,
    required String instructions,
    required String? scheduleTime,
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isActive,
  }) async {
    await _client.from('medications').insert({
      'user_id': _userId,
      'name': name.trim(),
      'dosage': dosage.trim(),
      'purpose': purpose.trim(),
      'frequency': frequency.trim(),
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
    required String frequency,
    required String instructions,
    required String? scheduleTime,
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isActive,
  }) async {
    await _client
        .from('medications')
        .update({
          'name': name.trim(),
          'dosage': dosage.trim(),
          'purpose': purpose.trim(),
          'frequency': frequency.trim(),
          'instructions': instructions.trim(),
          'schedule_time': scheduleTime,
          'start_date': _dateOnly(startDate),
          'end_date': _dateOnly(endDate),
          'is_active': isActive,
        })
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) async {
    await _client
        .from('medications')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}

String? _dateOnly(DateTime? value) {
  if (value == null) return null;
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
