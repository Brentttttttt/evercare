import 'dart:convert';

import 'package:evercare/routes/app_routes.dart';
import 'package:evercare/screens/profile/profile_screen.dart';
import 'package:evercare/screens/profile/logout_action_tile.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:evercare/widgets/evercare_backend_scope.dart';
import 'package:evercare/widgets/profile_avatar.dart';
import 'package:evercare/widgets/app_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  late String fullName;
  late int profileReads;

  setUp(() async {
    fullName = 'Maria Isabel Dela Cruz';
    profileReads = 0;
    client = SupabaseClient(
      'https://evercare-profile.test',
      'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path == '/rest/v1/profiles') {
          profileReads++;
          return http.Response(
            jsonEncode({
              'id': 'profile-test',
              'full_name': fullName,
              'phone_number': '0917 000 1234',
              'birth_date': '1955-05-03',
              'user_type': 'senior',
              'address': 'A synthetic address in Bulacan, Philippines',
              'avatar_path': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path == '/auth/v1/logout') {
          return http.Response('', 204);
        }
        throw StateError('Unexpected request: ${request.url.path}');
      }),
    );
    await client.auth.recoverSession(jsonEncode(_session()));
  });
  tearDown(() async => client.dispose());

  Future<void> pumpProfile(
    WidgetTester tester, {
    double textScale = 1,
    void Function(String? route)? onNavigate,
  }) async {
    await tester.pumpWidget(
      EverCareBackendScope(
        client: client,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          onGenerateRoute: (settings) {
            onNavigate?.call(settings.name);
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Return updated profile'),
                  ),
                ),
              ),
            );
          },
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows actual identity and birthday without placeholder health data',
    (tester) async {
      await pumpProfile(tester);
      expect(find.byType(ProfileAvatar), findsOneWidget);
      expect(find.text(fullName), findsOneWidget);
      expect(find.text('Senior'), findsOneWidget);
      expect(find.text('synthetic.long.email@example.test'), findsOneWidget);
      expect(find.textContaining('1955'), findsOneWidget);
      expect(find.text('0917 000 1234'), findsOneWidget);
      expect(
        find.text('A synthetic address in Bulacan, Philippines'),
        findsOneWidget,
      );
      expect(profileReads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('edit profile keeps navigation and reloads returned changes', (
    tester,
  ) async {
    String? destination;
    await pumpProfile(tester, onNavigate: (route) => destination = route);
    await tester.ensureVisible(find.text('Edit profile'));
    final edit = find.widgetWithText(FilledButton, 'Edit profile');
    expect(tester.getSize(edit).height, greaterThanOrEqualTo(48));
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(destination, AppRoutes.editProfile);
    fullName = 'Maria Updated';
    await tester.tap(find.text('Return updated profile'));
    await tester.pumpAndSettle();
    expect(find.text('Maria Updated'), findsOneWidget);
    expect(profileReads, 2);
  });

  testWidgets('profile shows fewer care menus and retains emergency support', (
    tester,
  ) async {
    await pumpProfile(tester);
    expect(find.text('Medical Information'), findsNothing);
    expect(find.text('Family and Caregivers'), findsNothing);
    expect(find.text('Family / Caregivers'), findsNothing);
    expect(find.text('Safety and sharing'), findsNothing);
    expect(find.text('Your account'), findsOneWidget);
    expect(find.text('Emergency support'), findsOneWidget);
    expect(find.text('Emergency Contacts'), findsOneWidget);
  });

  testWidgets('avatar is an accessible editor action and refreshes on return', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    String? destination;
    await pumpProfile(tester, onNavigate: (route) => destination = route);
    final avatarAction = find.byKey(const ValueKey('profile-photo-edit'));
    expect(tester.getSize(avatarAction).shortestSide, greaterThanOrEqualTo(48));
    try {
      expect(
        tester.getSemantics(avatarAction),
        matchesSemantics(
          label: 'Change profile photo',
          hint: 'Opens Edit Profile to choose and crop a photo.',
          isButton: true,
          hasTapAction: true,
        ),
      );
    } finally {
      semantics.dispose();
    }
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    await tester.tap(avatarAction);
    await tester.pumpAndSettle();
    expect(destination, AppRoutes.editProfile);
    fullName = 'Maria After Photo Save';
    await tester.tap(find.text('Return updated profile'));
    await tester.pumpAndSettle();
    expect(find.text(fullName), findsOneWidget);
    expect(profileReads, 2);
  });

  const menuRoutes = {
    'Personal Information': AppRoutes.editProfile,
    'Emergency Contacts': AppRoutes.emergencyContacts,
    'Accessibility': AppRoutes.accessibility,
    'Settings': AppRoutes.settings,
    'Help and Support': AppRoutes.helpSupport,
    'About EverCare': AppRoutes.about,
  };
  for (final entry in menuRoutes.entries) {
    testWidgets('${entry.key} retains its destination and a large tap target', (
      tester,
    ) async {
      String? destination;
      await pumpProfile(tester, onNavigate: (route) => destination = route);
      final label = find.text(entry.key);
      await tester.ensureVisible(label);
      final tap = find
          .ancestor(of: label, matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(tap).height, greaterThanOrEqualTo(48));
      await tester.tap(label);
      await tester.pumpAndSettle();
      expect(destination, entry.value);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 px with 3x text remains scrollable without overflow', (
    tester,
  ) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpProfile(tester, textScale: 3);
    expect(find.text(fullName), findsOneWidget);
    await tester.ensureVisible(find.text('About EverCare'));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Log Out'));
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out of EverCare?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'logout uses a dedicated flat action instead of a shadowed AppCard',
    (tester) async {
      await pumpProfile(tester);
      await tester.ensureVisible(find.byType(LogoutActionTile));
      expect(
        find.ancestor(
          of: find.byType(LogoutActionTile),
          matching: find.byType(AppCard),
        ),
        findsNothing,
      );
      final surface = tester.widget<Material>(
        find.byKey(const ValueKey('logout-tile-surface')),
      );
      expect(surface.color!.a, 1);
      expect(surface.elevation, 0);
    },
  );

  testWidgets(
    'logout confirmation can be cancelled without ending the session',
    (tester) async {
      await pumpProfile(tester);
      await tester.ensureVisible(find.text('Log Out'));
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(client.auth.currentSession, isNotNull);
      expect(find.text('Log out of EverCare?'), findsNothing);
    },
  );
}

Map<String, dynamic> _session() {
  final expiry =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  final claims = base64Url
      .encode(utf8.encode(jsonEncode({'sub': 'profile-test', 'exp': expiry})))
      .replaceAll('=', '');
  return {
    'access_token': 'eyJhbGciOiJIUzI1NiJ9.$claims.test-signature',
    'refresh_token': 'test-refresh',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': expiry,
    'user': {
      'id': 'profile-test',
      'aud': 'authenticated',
      'email': 'synthetic.long.email@example.test',
      'created_at': '2026-01-01T00:00:00Z',
      'app_metadata': {
        'provider': 'email',
        'providers': ['email'],
      },
      'user_metadata': <String, dynamic>{},
    },
  };
}
