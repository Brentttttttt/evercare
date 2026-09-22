import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  /// The auth trigger normally creates this row. If it is absent, bootstrap
  /// only known account metadata. ON CONFLICT DO NOTHING makes a concurrent
  /// trigger/device insert safe and never overwrites an existing profile.
  Future<UserProfile> ensureCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Please sign in first.');
    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (_client.auth.currentUser?.id != user.id) {
      throw const AuthException('Your session changed.');
    }
    if (existing != null) return UserProfile.fromMap(existing, user);
    final metadataProfile = UserProfile.fromAccount(user);
    final knownRole =
        const {
          'senior',
          'caregiver',
          'family_member',
        }.contains(metadataProfile.userType)
        ? metadataProfile.userType
        : '';
    await _client
        .from('profiles')
        .upsert(
          metadataProfile.copyWith(userType: knownRole).toDatabaseJson(),
          onConflict: 'id',
          ignoreDuplicates: true,
        );
    final created = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    if (_client.auth.currentUser?.id != user.id) {
      throw const AuthException('Your session changed.');
    }
    return UserProfile.fromMap(created, user);
  }

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
