import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_auth_config.dart';

enum GoogleAuthResult { ready, needsProfileSetup }

class GoogleAuthFailure implements Exception {
  const GoogleAuthFailure(this.message);
  final String message;
}

/// Transient SDK result only. Never serialize, persist, or log this object.
class GoogleAccountTokens {
  const GoogleAccountTokens({required this.idToken, required this.accessToken});
  final String idToken;
  final String accessToken;
}

abstract interface class GoogleAccountAuthenticator {
  Future<GoogleAccountTokens?> authenticate();
  Future<void> signOut();
}

class NativeGoogleAccountAuthenticator implements GoogleAccountAuthenticator {
  NativeGoogleAccountAuthenticator._();
  static final instance = NativeGoogleAccountAuthenticator._();
  final GoogleSignIn _google = GoogleSignIn.instance;
  Future<void>? _initializing;
  static const _scopes = ['openid', 'email', 'profile'];

  Future<void> _initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const GoogleAuthFailure(
        'Google sign-in is available in the EverCare Android app. You can still sign in with email here.',
      );
    }
    if (!GoogleAuthConfig.isConfigured) {
      throw const GoogleAuthFailure(
        'Google sign-in is not configured in this build yet. Please use email sign-in for now.',
      );
    }
    try {
      await (_initializing ??= _google.initialize(
        serverClientId: GoogleAuthConfig.webClientId.trim(),
      ));
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  @override
  Future<GoogleAccountTokens?> authenticate() async {
    try {
      await _initialize();
      // This clears EverCare's Google session, not an Android device account.
      // Always use the official interactive flow, never silently pick an email.
      await _google.signOut();
      final account = await _google.authenticate(scopeHint: _scopes);
      final idToken = account.authentication.idToken?.trim();
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleAuthFailure(
          'Google could not verify this sign-in. Please select your account again.',
        );
      }
      final authorization =
          await account.authorizationClient.authorizationForScopes(_scopes) ??
          await account.authorizationClient.authorizeScopes(_scopes);
      final accessToken = authorization.accessToken.trim();
      if (accessToken.isEmpty) {
        throw const GoogleAuthFailure(
          'Google could not complete this sign-in. Please try again.',
        );
      }
      return GoogleAccountTokens(idToken: idToken, accessToken: accessToken);
    } on GoogleSignInException catch (error) {
      // The code is an enum, not a message containing provider/token details.
      if (kDebugMode) debugPrint('Google sign-in result: ${error.code.name}');
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const GoogleAuthFailure(
          'Google sign-in is not configured correctly for this app. Please use email sign-in for now.',
        );
      }
      throw const GoogleAuthFailure(
        "We couldn't sign you in with Google. Please check your internet connection and try again.",
      );
    } on GoogleAuthFailure {
      rethrow;
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Google sign-in failed before session creation.');
      }
      throw const GoogleAuthFailure(
        "We couldn't sign you in with Google. Please check your internet connection and try again.",
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        !GoogleAuthConfig.isConfigured) {
      return;
    }
    await _initialize();
    await _google.signOut();
  }
}
