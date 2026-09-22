import 'dart:async';
import 'dart:convert';

import 'package:evercare/services/auth_service.dart';
import 'package:evercare/services/google_account_authenticator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late _Google google;
  late AuthService service;
  late List<http.Request> requests;
  late FutureOr<http.Response> Function(http.Request) profileResponse;
  var rejectToken = false;
  var provider = 'google';

  setUp(() {
    requests = [];
    google = _Google();
    rejectToken = false;
    provider = 'google';
    profileResponse = (_) => _json(_profile());
    client = SupabaseClient(
      'https://evercare-auth.test',
      'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/auth/v1/token') {
          return rejectToken
              ? _json({'msg': 'private provider details'}, status: 400)
              : _json(_session(provider));
        }
        if (request.url.path == '/auth/v1/logout') {
          return http.Response('', 204);
        }
        if (request.url.path == '/rest/v1/profiles') {
          final response = await profileResponse(request);
          return http.Response(
            response.body,
            response.statusCode,
            headers: response.headers,
            request: request,
          );
        }
        throw StateError('Unexpected test request path');
      }),
    );
    service = AuthService(client, googleAuthenticator: google);
  });

  tearDown(() async => client.dispose());

  test('cancellation creates no Supabase request or session', () async {
    google.tokens = null;
    expect(await service.signInWithGoogle(), isNull);
    expect(requests, isEmpty);
    expect(client.auth.currentSession, isNull);
    expect(google.signOuts, 1);
  });

  test('missing credentials are rejected before contacting Supabase', () async {
    google.tokens = const GoogleAccountTokens(idToken: '', accessToken: 'test');
    await expectLater(
      service.signInWithGoogle(),
      throwsA(isA<GoogleAuthFailure>()),
    );
    expect(requests, isEmpty);
  });

  test('existing profile is read by UID and never overwritten', () async {
    expect(await service.signInWithGoogle(), GoogleAuthResult.ready);
    expect(client.auth.currentSession, isNotNull);
    final exchange = requests.first;
    expect(exchange.url.queryParameters['grant_type'], 'id_token');
    final body = jsonDecode(exchange.body) as Map<String, dynamic>;
    expect(body['provider'], 'google');
    expect(body['id_token'], 'test-google-id');
    expect(body['access_token'], 'test-google-access');
    final profiles = requests.where((r) => r.url.path.endsWith('/profiles'));
    expect(profiles.length, 1);
    expect(profiles.single.method, 'GET');
    expect(profiles.single.url.queryParameters['id'], 'eq.test-user');
    expect(profiles.single.url.queryParameters.containsKey('email'), isFalse);
    expect(google.signOuts, 0);
  });

  test('incomplete trigger-created profile enters existing setup', () async {
    profileResponse = (_) => _json(_profile(complete: false));
    expect(
      await service.signInWithGoogle(),
      GoogleAuthResult.needsProfileSetup,
    );
    expect(client.auth.currentSession, isNotNull);
    expect(requests.where((r) => r.method == 'POST').length, 1);
  });

  test(
    'absent profile uses conflict-ignore and no invented role or DOB',
    () async {
      var reads = 0;
      profileResponse = (request) {
        if (request.method == 'GET') {
          reads++;
          return _json(reads == 1 ? null : _profile(complete: false));
        }
        expect(request.method, 'POST');
        expect(
          request.headers['prefer'],
          contains('resolution=ignore-duplicates'),
        );
        expect(request.url.queryParameters['on_conflict'], 'id');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['id'], 'test-user');
        expect(body['full_name'], 'Google Display Name');
        expect(body['birth_date'], isNull);
        expect(body['user_type'], isNull);
        expect(body.containsKey('email'), isFalse);
        return http.Response('', 201);
      };
      expect(
        await service.signInWithGoogle(),
        GoogleAuthResult.needsProfileSetup,
      );
      expect(reads, 2);
    },
  );

  test(
    'a concurrent profile insert is re-read rather than overwritten',
    () async {
      var reads = 0;
      profileResponse = (request) {
        if (request.method == 'POST') return http.Response('', 201);
        reads++;
        return _json(reads == 1 ? null : _profile());
      };
      expect(await service.signInWithGoogle(), GoogleAuthResult.ready);
      expect(reads, 2);
    },
  );

  test(
    'profile lookup failure clears session and hides backend details',
    () async {
      profileResponse = (_) => _json({
        'message': 'private SQL details',
        'code': 'XX000',
      }, status: 500);
      await expectLater(
        service.signInWithGoogle(),
        throwsA(
          isA<GoogleAuthFailure>().having(
            (e) => e.message,
            'friendly message',
            isNot(contains('private')),
          ),
        ),
      );
      expect(client.auth.currentSession, isNull);
      expect(google.signOuts, 1);
    },
  );

  test(
    'profile creation failure clears session rather than entering home',
    () async {
      profileResponse = (request) => request.method == 'GET'
          ? _json(null)
          : _json({'message': 'insert rejected', 'code': '42501'}, status: 403);
      await expectLater(
        service.signInWithGoogle(),
        throwsA(isA<GoogleAuthFailure>()),
      );
      expect(client.auth.currentSession, isNull);
    },
  );

  test('Supabase rejection does not expose provider response', () async {
    rejectToken = true;
    await expectLater(
      service.signInWithGoogle(),
      throwsA(
        isA<GoogleAuthFailure>().having(
          (e) => e.message,
          'friendly message',
          isNot(contains('private')),
        ),
      ),
    );
    expect(client.auth.currentSession, isNull);
    expect(google.signOuts, 1);
  });

  test('restored incomplete Google session remains gated', () async {
    await client.auth.recoverSession(jsonEncode(_session('google')));
    profileResponse = (_) => _json(_profile(complete: false));
    expect(await service.needsGoogleProfileSetup(), isTrue);
  });

  test(
    'ordinary email sessions retain their existing startup behavior',
    () async {
      await client.auth.recoverSession(jsonEncode(_session('email')));
      expect(await service.needsGoogleProfileSetup(), isFalse);
      expect(requests, isEmpty);
    },
  );

  test('logout clears ordinary Supabase and Google SDK state', () async {
    await service.signInWithGoogle();
    await service.signOut();
    expect(client.auth.currentSession, isNull);
    expect(google.signOuts, 1);
  });
}

class _Google implements GoogleAccountAuthenticator {
  GoogleAccountTokens? tokens = const GoogleAccountTokens(
    idToken: 'test-google-id',
    accessToken: 'test-google-access',
  );
  int signOuts = 0;
  @override
  Future<GoogleAccountTokens?> authenticate() async => tokens;
  @override
  Future<void> signOut() async {
    signOuts++;
  }
}

http.Response _json(Object? value, {int status = 200}) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _profile({bool complete = true}) => {
  'id': 'test-user',
  'full_name': 'Existing Chosen Name',
  'birth_date': complete ? '1960-01-01' : null,
  'user_type': complete ? 'caregiver' : null,
};

Map<String, dynamic> _session(String provider) {
  final expiry =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  final claims = base64Url
      .encode(utf8.encode(jsonEncode({'sub': 'test-user', 'exp': expiry})))
      .replaceAll('=', '');
  return {
    'access_token': 'eyJhbGciOiJIUzI1NiJ9.$claims.test-signature',
    'refresh_token': 'test-refresh',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': expiry,
    'user': {
      'id': 'test-user',
      'aud': 'authenticated',
      'email': 'synthetic@example.test',
      'created_at': '2026-01-01T00:00:00Z',
      'app_metadata': {
        'provider': provider,
        'providers': [provider],
      },
      'user_metadata': {'name': 'Google Display Name'},
    },
  };
}
