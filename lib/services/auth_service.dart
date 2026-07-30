import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin account service around Supabase Auth.
///
/// Keeping these calls out of widgets makes every successful account action
/// represent a real response from the configured Supabase project.
class AuthService {
  const AuthService(this._client);

  final SupabaseClient _client;

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

  Future<void> signOut() => _client.auth.signOut();

  static String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
