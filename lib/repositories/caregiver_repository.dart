import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caregiver_relationship.dart';

class CaregiverRepository {
  CaregiverRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Sign in to see trusted people.');
    return id;
  }

  Future<List<CaregiverRelationship>> fetchRelationships() async {
    final rows = await _client.rpc<List<dynamic>>(
      'get_my_caregiver_relationships',
    );
    return rows
        .map(
          (row) => CaregiverRelationship.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<void> removeRelationship(String id) async {
    await _client
        .from('caregiver_relationships')
        .delete()
        .eq('id', id)
        .eq('older_adult_id', _userId);
  }
}
