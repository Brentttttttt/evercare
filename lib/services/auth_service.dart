import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../repositories/profile_repository.dart';
import 'google_account_authenticator.dart';
import 'reminder_changes.dart';

export 'google_account_authenticator.dart'
    show GoogleAuthFailure, GoogleAuthResult;

/// Thin account service around Supabase Auth.
///
/// Keeping these calls out of widgets makes every successful account action
/// represent a real response from the configured Supabase project.
class AuthService {
  const AuthService(
    this._client, {
    GoogleAccountAuthenticator? googleAuthenticator,
  }) : _googleAuthenticator = googleAuthenticator;

  final SupabaseClient _client;
  final GoogleAccountAuthenticator? _googleAuthenticator;
  static bool _googleBusy = false;
  GoogleAccountAuthenticator get _google =>
      _googleAuthenticator ?? NativeGoogleAccountAuthenticator.instance;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required DateTime? birthDate,
    required String userType,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: <String, dynamic>{
        'full_name': fullName.trim(),
        'phone_number': phoneNumber.trim(),
        'birth_date': birthDate == null ? null : _dateOnly(birthDate),
        'user_type': userType,
      },
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<bool> needsGoogleProfileSetup() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final providers = user.appMetadata['providers'];
    final isGoogle =
        user.appMetadata['provider'] == 'google' ||
        (providers is List && providers.contains('google')) ||
        (user.identities?.any((identity) => identity.provider == 'google') ??
            false);
    if (!isGoogle) return false;
    return !(await ProfileRepository(
      _client,
    ).ensureCurrentProfile()).isComplete;
  }

  /// Both Google buttons use this same native flow and the ordinary Supabase
  /// session. Supabase owns identity linking; no email-based merging happens here.
  Future<GoogleAuthResult?> signInWithGoogle() async {
    if (_googleBusy) {
      throw const GoogleAuthFailure('Google sign-in is already in progress.');
    }
    _googleBusy = true;
    var createdSession = false;
    try {
      final tokens = await _google.authenticate();
      if (tokens == null) return null;
      if (tokens.idToken.trim().isEmpty || tokens.accessToken.trim().isEmpty) {
        throw const GoogleAuthFailure(
          'Google could not verify this sign-in. Please try again.',
        );
      }
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
      if (response.session == null || response.user == null) {
        throw const GoogleAuthFailure(
          'Google sign-in did not complete. Please try again.',
        );
      }
      createdSession = true;
      try {
        final profile = await ProfileRepository(_client).ensureCurrentProfile();
        return profile.isComplete
            ? GoogleAuthResult.ready
            : GoogleAuthResult.needsProfileSetup;
      } catch (_) {
        // Do not leave a half-finished session able to bypass setup on restart.
        createdSession = false;
        try {
          await _client.auth.signOut(scope: SignOutScope.local);
        } catch (_) {
          // Startup also checks profile completeness if SDK cleanup is offline.
        }
        throw const GoogleAuthFailure(
          'Your EverCare profile could not be loaded. Please check your connection and try signing in again.',
        );
      }
    } on GoogleAuthFailure {
      rethrow;
    } on AuthException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Supabase Google sign-in failed (${error.code ?? 'auth_error'}).',
        );
      }
      throw const GoogleAuthFailure(
        "EverCare couldn't complete Google sign-in. Please try again or use your email and password.",
      );
    } catch (_) {
      if (kDebugMode) debugPrint('EverCare Google sign-in failed.');
      throw const GoogleAuthFailure(
        "We couldn't sign you in with Google. Please check your internet connection and try again.",
      );
    } finally {
      if (!createdSession) {
        try {
          await _google.signOut();
        } catch (_) {
          /* SDK cleanup is best-effort. */
        }
      }
      _googleBusy = false;
    }
  }

  Future<void> signOut() async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) await ReminderChanges.signingOut(userId);
    await _client.auth.signOut();
    try {
      await _google.signOut();
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          'Google session cleanup was unavailable; Supabase is signed out.',
        );
      }
    }
  }

  static String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
