import 'dart:async';
import 'dart:convert';

import 'package:evercare/routes/app_routes.dart';
import 'package:evercare/screens/authentication/google_auth_flow.dart';
import 'package:evercare/screens/authentication/google_sign_in_section.dart';
import 'package:evercare/screens/authentication/login_screen.dart';
import 'package:evercare/screens/authentication/registration_screen.dart';
import 'package:evercare/services/auth_service.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:evercare/widgets/primary_button.dart';
import 'package:evercare/widgets/evercare_backend_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> pumpAuthScreen(
  WidgetTester tester,
  Widget screen, {
  double textScale = 1,
  SupabaseClient? client,
  void Function(RouteSettings settings)? onNavigate,
}) async {
  final app = MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child!,
    ),
    onGenerateRoute: (settings) {
      onNavigate?.call(settings);
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(body: Text('Destination: ${settings.name}')),
      );
    },
    home: screen,
  );
  await tester.pumpWidget(
    client == null ? app : EverCareBackendScope(client: client, child: app),
  );
  await tester.pumpAndSettle();
}

Future<void> tapGoogle(WidgetTester tester) async {
  final button = find.text('Continue with Google');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

void main() {
  final screens = <String, Widget Function(GoogleSignInAction)>{
    'login': (action) => LoginScreen(onGoogleSignIn: action),
    'registration': (action) => RegistrationScreen(onGoogleSignIn: action),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} offers Google without requiring email fields', (
      tester,
    ) async {
      var calls = 0;
      final pending = Completer<GoogleAuthResult?>();
      await pumpAuthScreen(
        tester,
        entry.value(() {
          calls++;
          return pending.future;
        }),
      );
      expect(find.byType(GoogleSignInSection), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Continue with Google')).dy,
        greaterThan(tester.getTopLeft(find.byType(PrimaryButton)).dy),
      );
      await tapGoogle(tester);
      expect(calls, 1);
      expect(find.text('Signing in with Google…'), findsOneWidget);
      expect(find.textContaining('is required.'), findsNothing);
      expect(find.text('Select your date of birth.'), findsNothing);
      for (final field in tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      )) {
        expect(field.enabled, isFalse);
      }
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Signing in with Google…'),
            )
            .onPressed,
        isNull,
      );

      pending.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.textContaining('could not sign in'), findsNothing);
      expect(find.textContaining('is required.'), findsNothing);
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('${entry.key} shows safe Google failures and allows retry', (
      tester,
    ) async {
      await pumpAuthScreen(
        tester,
        entry.value(() async {
          throw const GoogleAuthFailure(
            'Google sign-in is not configured yet.',
          );
        }),
      );
      await tapGoogle(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Google sign-in is not configured yet.'),
        findsOneWidget,
      );
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('${entry.key} keeps unexpected provider details private', (
      tester,
    ) async {
      await pumpAuthScreen(
        tester,
        entry.value(
          () async => throw StateError('secret-token-provider-trace'),
        ),
      );
      await tapGoogle(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('EverCare could not sign in with Google. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('secret-token'), findsNothing);
    });

    for (final result in GoogleAuthResult.values) {
      testWidgets('${entry.key} routes ${result.name} after Google sign-in', (
        tester,
      ) async {
        RouteSettings? destination;
        await pumpAuthScreen(
          tester,
          entry.value(() async => result),
          onNavigate: (settings) => destination = settings,
        );
        await tapGoogle(tester);
        await tester.pumpAndSettle();
        final needsProfile = result == GoogleAuthResult.needsProfileSetup;
        expect(
          destination?.name,
          needsProfile ? AppRoutes.editProfile : AppRoutes.home,
        );
        expect(destination?.arguments, needsProfile ? true : null);
        expect(find.byType(GoogleSignInSection), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('${entry.key} Google control wraps at 320px and 3x text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpAuthScreen(tester, entry.value(() async => null), textScale: 3);
      await tester.ensureVisible(find.text('Continue with Google'));
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final state in ['email', 'google incomplete', 'google unavailable']) {
    testWidgets('password login respects profile state: $state', (
      tester,
    ) async {
      var profileRequests = 0;
      RouteSettings? destination;
      late SupabaseClient client;
      // Construct the SDK in the real async zone too: its JSON worker starts
      // during construction and must not wait on the widget test's fake clock.
      await tester.runAsync(() async {
        client = SupabaseClient(
          'https://example.test',
          'synthetic-public-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
            if (request.url.path == '/auth/v1/token') {
              return http.Response(
                jsonEncode(_syntheticSession(linkedGoogle: state != 'email')),
                200,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            if (request.url.path == '/rest/v1/profiles') {
              profileRequests++;
              return http.Response(
                jsonEncode(
                  state == 'google unavailable'
                      ? {'message': 'private provider details'}
                      : {
                          'id': 'test-user',
                          'full_name': 'Test Person',
                          'user_type': null,
                        },
                ),
                state == 'google unavailable' ? 403 : 200,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            return http.Response('{}', 404);
          }),
        );
      });
      addTearDown(() => tester.runAsync(client.dispose));
      await pumpAuthScreen(
        tester,
        const LoginScreen(),
        client: client,
        onNavigate: (settings) => destination = settings,
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.invalid',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'synthetic-password',
      );
      await tester.ensureVisible(find.text('Log In'));
      // Supabase decodes HTTP responses in a worker isolate. Let that work
      // complete in real async time rather than the widget clock.
      final submit =
          tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed!
              as Future<void> Function();
      await tester.runAsync(submit);
      await tester.pumpAndSettle();
      if (state == 'email') {
        expect(profileRequests, 0);
        expect(destination?.name, AppRoutes.home);
      } else if (state == 'google incomplete') {
        expect(profileRequests, 1);
        expect(destination?.name, AppRoutes.editProfile);
        expect(destination?.arguments, true);
      } else {
        expect(profileRequests, 1);
        expect(destination, isNull);
        expect(
          find.textContaining('Your EverCare profile could not be loaded.'),
          findsOneWidget,
        );
        expect(find.textContaining('private provider details'), findsNothing);
      }
    });
  }
}

Map<String, Object?> _syntheticSession({required bool linkedGoogle}) {
  String segment(Map<String, Object?> data) =>
      base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
  final token =
      '${segment({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${segment({'sub': 'test-user', 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.'
      'synthetic-signature';
  return {
    'access_token': token,
    'refresh_token': 'synthetic-refresh',
    'expires_in': 3600,
    'token_type': 'bearer',
    'user': {
      'id': 'test-user',
      'aud': 'authenticated',
      'email': 'test@example.invalid',
      'app_metadata': {
        'provider': 'email',
        'providers': ['email', if (linkedGoogle) 'google'],
      },
      'user_metadata': <String, Object?>{},
      'created_at': '2026-01-01T00:00:00Z',
    },
  };
}
