import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/evercare_backend_scope.dart';

typedef GoogleSignInAction = Future<GoogleAuthResult?> Function();

Future<GoogleAuthResult?> startGoogleSignIn(
  BuildContext context, {
  GoogleSignInAction? signIn,
}) {
  if (signIn != null) return signIn();
  final client = EverCareBackendScope.maybeClient(context);
  if (client == null) {
    throw StateError('Account services are unavailable.');
  }
  return AuthService(client).signInWithGoogle();
}

String googleSignInErrorMessage(Object error) => error is GoogleAuthFailure
    ? error.message
    : 'EverCare could not sign in with Google. Please try again.';

void finishGoogleSignIn(BuildContext context, GoogleAuthResult result) {
  final needsProfile = result == GoogleAuthResult.needsProfileSetup;
  Navigator.pushNamedAndRemoveUntil(
    context,
    needsProfile ? AppRoutes.editProfile : AppRoutes.home,
    (route) => false,
    arguments: needsProfile ? true : null,
  );
}
