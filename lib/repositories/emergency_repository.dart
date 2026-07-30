import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_contact.dart';

class EmergencyRepository {
  EmergencyRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthException('Sign in to use emergency information.');
    }
    return id;
  }

  Future<List<EmergencyContact>> fetchContacts() async {
    final rows = await _client
        .from('emergency_contacts')
        .select()
        .eq('user_id', _userId)
        .order('is_primary', ascending: false)
        .order('created_at');
    return rows.map(EmergencyContact.fromMap).toList(growable: false);
  }

  Future<EmergencyContact> saveContact({
    String? id,
    required String name,
    required String relationship,
    required String phoneNumber,
    required bool isPrimary,
  }) async {
    if (isPrimary) {
      await _client
          .from('emergency_contacts')
          .update({'is_primary': false})
          .eq('user_id', _userId)
          .eq('is_primary', true);
    }
    final values = <String, dynamic>{
      'user_id': _userId,
      'name': name.trim(),
      'relationship': relationship.trim(),
      'phone_number': phoneNumber.trim(),
      'is_primary': isPrimary,
    };
    final row = id == null
        ? await _client
              .from('emergency_contacts')
              .insert(values)
              .select()
              .single()
        : await _client
              .from('emergency_contacts')
              .update(values)
              .eq('id', id)
              .eq('user_id', _userId)
              .select()
              .single();
    return EmergencyContact.fromMap(row);
  }

  Future<void> deleteContact(String id) async {
    await _client
        .from('emergency_contacts')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<EmergencyMedicalProfile> fetchMedicalProfile() async {
    final userId = _userId;
    final results = await Future.wait([
      _client
          .from('profiles')
          .select('full_name,birth_date')
          .eq('id', userId)
          .maybeSingle(),
      _client
          .from('medical_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle(),
    ]);
    return EmergencyMedicalProfile.fromMaps(
      profile: results[0],
      medicalProfile: results[1],
    );
  }

  Future<void> saveMedicalProfile({
    required String bloodType,
    required List<String> allergies,
    required List<String> conditions,
    required String preferredHospital,
    required String medicalNotes,
  }) async {
    await _client.from('medical_profiles').upsert({
      'user_id': _userId,
      'blood_type': bloodType.trim(),
      'allergies': allergies,
      'conditions': conditions,
      'preferred_hospital': preferredHospital.trim(),
      'medical_notes': medicalNotes.trim(),
    }, onConflict: 'user_id');
  }
}
