import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<UserProfile> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in to view your profile.');
    }

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      // Account metadata is real data supplied during registration. It also
      // gives a newly registered user a usable edit form while the database
      // trigger creates their profile row.
      return UserProfile.fromAccount(user);
    }
    return UserProfile.fromMap(data, user);
  }

  Future<UserProfile> save(UserProfile profile) async {
    final user = _client.auth.currentUser;
    if (user == null || user.id != profile.id) {
      throw const AuthException('Your session expired. Please sign in again.');
    }

    final data = await _client
        .from('profiles')
        .upsert(profile.toDatabaseJson())
        .select()
        .single();

    return UserProfile.fromMap(data, user);
  }
}
