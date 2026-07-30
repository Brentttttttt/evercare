import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/blood_pressure_reading.dart';
import '../models/bp_monitor_result.dart';

class BloodPressureRepository {
  const BloodPressureRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Sign in to access health records.');
    return id;
  }

  Future<List<BloodPressureReading>> list({int limit = 100}) async {
    final rows = await _client
        .from('blood_pressure_readings')
        .select()
        .eq('user_id', _userId)
        .order('measured_at', ascending: false)
        .limit(limit);
    return rows
        .map((row) => BloodPressureReading.fromMap(row))
        .toList(growable: false);
  }

  Future<BloodPressureReading> saveBleResult(BpMonitorResult result) async {
    final row = await _client
        .from('blood_pressure_readings')
        .upsert({
          'user_id': _userId,
          'systolic': result.systolic,
          'diastolic': result.diastolic,
          'pulse': result.pulse,
          'measured_at': result.receivedAt.toUtc().toIso8601String(),
          'source': 'ble',
          'monitor_name': result.deviceName,
          'decoder_name': result.decoderVersion,
          'raw_packet_hex': result.rawHex,
          'capture_metadata': {
            'packetIndex': result.packetIndex,
            'validationStatus': result.validationStatus,
            'deviceIdentifier': result.deviceIdentifier,
            'metadataBytes': result.metadataBytes,
          },
          'is_medically_verified': false,
        }, onConflict: 'user_id,source,measured_at,raw_packet_hex')
        .select()
        .single();
    return BloodPressureReading.fromMap(row);
  }

  Future<BloodPressureReading> saveManual({
    required int systolic,
    required int diastolic,
    required int pulse,
    required DateTime measuredAt,
    String? notes,
  }) async {
    final row = await _client
        .from('blood_pressure_readings')
        .insert({
          'user_id': _userId,
          'systolic': systolic,
          'diastolic': diastolic,
          'pulse': pulse,
          'measured_at': measuredAt.toUtc().toIso8601String(),
          'source': 'manual',
          'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
          'is_medically_verified': false,
        })
        .select()
        .single();
    return BloodPressureReading.fromMap(row);
  }

  Future<void> updateNotes(String id, String notes) async {
    await _client
        .from('blood_pressure_readings')
        .update({'notes': notes.trim().isEmpty ? null : notes.trim()})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> delete(String id) async {
    await _client
        .from('blood_pressure_readings')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
