abstract final class GoogleMapsConfig {
  /// Supplied at build time so a Google Maps key is never committed to Git.
  /// Restrict this key to EverCare's Android package and signing certificate.
  static const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
