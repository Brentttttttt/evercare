import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_photo.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;
  static const photoBucket = 'profile-pictures';

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

    _checkUser(user.id);

    if (data == null) {
      // Account metadata is real data supplied during registration. It also
      // gives a newly registered user a usable edit form while the database
      // trigger creates their profile row.
      return UserProfile.fromAccount(user);
    }
    return _withPhoto(UserProfile.fromMap(data, user));
  }

  Future<UserProfile> save(
    UserProfile profile, {
    ProfilePhotoUpload? photo,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || user.id != profile.id) {
      throw const AuthException('Your session expired. Please sign in again.');
    }

    String? uploadedPath;
    Map<String, dynamic> data;
    try {
      if (photo != null) {
        final bytes = photo.bytes;
        const pngHeader = [137, 80, 78, 71, 13, 10, 26, 10];
        if (bytes.length < pngHeader.length ||
            bytes.length > ProfilePhotoUpload.maximumBytes ||
            Iterable.generate(
              pngHeader.length,
            ).any((i) => bytes[i] != pngHeader[i])) {
          throw const ProfilePhotoFailure(
            'Choose the photo again before saving.',
          );
        }
        final random = Random.secure();
        final name = List.generate(
          16,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
        uploadedPath = '${user.id}/$name.png';
        await _client.storage
            .from(photoBucket)
            .uploadBinary(
              uploadedPath,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/png',
                upsert: false,
                cacheControl: '3600',
              ),
            );
        _checkUser(user.id);
      }
      final fields = profile.toDatabaseJson()..remove('avatar_path');
      // An ordinary text edit must not overwrite a newer photo from another
      // device with a stale cached path. Only an explicit selection changes it.
      if (uploadedPath != null) fields['avatar_path'] = uploadedPath;
      data = await _client.from('profiles').upsert(fields).select().single();
      _checkUser(user.id);
    } catch (_) {
      if (uploadedPath != null && _client.auth.currentUser?.id == user.id) {
        // A lost response can hide a committed save. Only remove an uploaded
        // object after a successful read proves that it is not the current one.
        try {
          final row = await _client
              .from('profiles')
              .select('avatar_path')
              .eq('id', user.id)
              .maybeSingle();
          _checkUser(user.id);
          if (row?['avatar_path'] != uploadedPath) {
            await _client.storage.from(photoBucket).remove([uploadedPath]);
          }
        } catch (_) {
          // Keep a private orphan rather than breaking an existing avatar.
        }
      }
      rethrow;
    }
    final saved = UserProfile.fromMap(data, user);
    final previous = profile.avatarPath;
    if (uploadedPath != null &&
        saved.avatarPath == uploadedPath &&
        previous != null &&
        previous != uploadedPath &&
        _ownsPath(user.id, previous)) {
      try {
        await _client.storage.from(photoBucket).remove([previous]);
      } catch (_) {
        // The new profile is committed. Cleanup failure must not claim it failed.
      }
    }
    _checkUser(user.id);
    return _withPhoto(saved);
  }

  Future<UserProfile> _withPhoto(UserProfile profile) async {
    final path = profile.avatarPath;
    if (path == null || !_ownsPath(profile.id, path)) return profile;
    try {
      final url = await _client.storage
          .from(photoBucket)
          .createSignedUrl(path, 3600)
          .timeout(const Duration(seconds: 8));
      _checkUser(profile.id);
      return profile.copyWith(avatarUrl: url);
    } catch (_) {
      _checkUser(profile.id);
      // An unavailable photo must never hide otherwise valid profile details.
      return profile;
    }
  }

  void _checkUser(String id) {
    if (_client.auth.currentUser?.id != id) {
      throw const AuthException('Your session changed. Please sign in again.');
    }
  }

  static bool _ownsPath(String id, String path) {
    final parts = path.split('/');
    return parts.length == 2 &&
        parts.first == id &&
        RegExp(r'^[A-Za-z0-9_-]+\.(png|jpg|jpeg|webp)$').hasMatch(parts.last);
  }
}
