/// Public OAuth client identifier, using the same build-time configuration
/// strategy as SupabaseConfig. Never bundle supabase/functions/.env in Flutter.
abstract final class GoogleAuthConfig {
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static bool get isConfigured =>
      RegExp(
        r'^[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$',
      ).hasMatch(webClientId.trim()) &&
      !webClientId.contains('YOUR_');
}
