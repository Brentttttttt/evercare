import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:evercare/models/profile_photo.dart';
import 'package:evercare/models/user_profile.dart';
import 'package:evercare/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  late ProfileRepository repository;
  late List<http.Request> requests;
  late Map<String, dynamic> row;
  FutureOr<http.Response?> Function(http.Request request)? overrideResponse;

  setUp(() async {
    requests = [];
    row = _row();
    overrideResponse = null;
    client = SupabaseClient(
      'https://evercare-profile.test',
      'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final overridden = await overrideResponse?.call(request);
        if (overridden != null) return overridden;
        if (_isProfile(request)) {
          if (request.method == 'POST') {
            row = {...row, ...jsonDecode(request.body) as Map<String, dynamic>};
          }
          return _json(row, request: request);
        }
        if (_isUpload(request)) {
          return _json({
            'Key': request.url.path.substring('/storage/v1/object/'.length),
          }, request: request);
        }
        if (_isDelete(request)) return _json([], request: request);
        if (_isSign(request)) {
          return _json({
            'signedURL':
                '${request.url.path.substring('/storage/v1'.length)}?token=test-signed-url',
          }, request: request);
        }
        throw StateError(
          'Unexpected mocked request: ${request.method} ${request.url.path}',
        );
      }),
    );
    await _recoverUser(client, 'user-1');
    repository = ProfileRepository(client);
  });

  tearDown(() async => client.dispose());

  UserProfile profile({String? avatarPath}) => UserProfile.fromMap({
    ..._row(),
    'avatar_path': avatarPath,
  }, client.auth.currentUser!);

  test(
    'uploads a unique owner path with PNG content type and no overwrite',
    () async {
      final upload = _photo();
      final saved = await repository.save(profile(), photo: upload);
      final request = requests.singleWhere(_isUpload);

      expect(
        request.url.path,
        matches(
          r'^/storage/v1/object/profile-pictures/user-1/[a-f0-9]{32}\.png$',
        ),
      );
      expect(request.headers['x-upsert'], 'false');
      expect(
        latin1.decode(request.bodyBytes).toLowerCase(),
        contains('content-type: image/png'),
      );
      expect(
        saved.avatarPath,
        request.url.path.substring(
          '/storage/v1/object/profile-pictures/'.length,
        ),
      );
      expect(row['avatar_path'], saved.avatarPath);
      expect(
        saved.avatarUrl,
        startsWith('https://evercare-profile.test/storage/v1/object/sign/'),
      );
      expect(saved.toDatabaseJson().containsKey('avatar_url'), isFalse);
      expect(
        saved.toDatabaseJson().toString(),
        isNot(contains('test-signed-url')),
      );
      final sign = requests.singleWhere(_isSign);
      expect(jsonDecode(sign.body), {'expiresIn': 3600});
    },
  );

  test(
    'replacement confirms profile save before deleting only the former photo',
    () async {
      row['avatar_path'] = 'user-1/old.png';
      final saved = await repository.save(
        profile(avatarPath: 'user-1/old.png'),
        photo: _photo(),
      );

      final mutation = requests.indexWhere(
        (request) => _isProfile(request) && request.method == 'POST',
      );
      final deletion = requests.indexWhere(_isDelete);
      expect(deletion, greaterThan(mutation));
      expect(jsonDecode(requests[deletion].body), {
        'prefixes': ['user-1/old.png'],
      });
      expect(saved.avatarPath, isNot('user-1/old.png'));
      expect(row['avatar_path'], saved.avatarPath);
    },
  );

  test('each replacement uses a fresh random filename', () async {
    final first = await repository.save(profile(), photo: _photo());
    final second = await repository.save(first, photo: _photo());

    expect(second.avatarPath, isNot(first.avatarPath));
    expect(requests.where(_isUpload), hasLength(2));
  });

  test(
    'text-only save omits a stale avatar path and retains the newer server photo',
    () async {
      row['avatar_path'] = 'user-1/newer-device-photo.png';
      final edited = profile(
        avatarPath: 'user-1/stale.png',
      ).copyWith(fullName: 'Updated Name');
      final saved = await repository.save(edited);
      final body =
          jsonDecode(
                requests
                    .firstWhere(
                      (request) =>
                          request.method == 'POST' && _isProfile(request),
                    )
                    .body,
              )
              as Map<String, dynamic>;

      expect(body.containsKey('avatar_path'), isFalse);
      expect(body['full_name'], 'Updated Name');
      expect(saved.avatarPath, 'user-1/newer-device-photo.png');
      expect(requests.where(_isUpload), isEmpty);
      expect(requests.where(_isDelete), isEmpty);
    },
  );

  for (final invalid in <String, Uint8List>{
    'empty': Uint8List(0),
    'truncated': Uint8List.fromList([137, 80, 78]),
    'wrong format': Uint8List.fromList(utf8.encode('not a PNG image')),
    'over 5 MiB': Uint8List(ProfilePhotoUpload.maximumBytes + 1)
      ..setAll(0, [137, 80, 78, 71, 13, 10, 26, 10]),
  }.entries) {
    test('rejects ${invalid.key} upload before any HTTP request', () async {
      await expectLater(
        repository.save(profile(), photo: ProfilePhotoUpload(invalid.value)),
        throwsA(isA<ProfilePhotoFailure>()),
      );
      expect(requests, isEmpty);
    });
  }

  test(
    'storage rejection never mutates the profile or deletes its existing photo',
    () async {
      row['avatar_path'] = 'user-1/old.png';
      overrideResponse = (request) => _isUpload(request)
          ? _json(
              {'message': 'upload rejected', 'error': 'Forbidden'},
              status: 403,
              request: request,
            )
          : null;

      await expectLater(
        repository.save(profile(avatarPath: 'user-1/old.png'), photo: _photo()),
        throwsA(isA<StorageException>()),
      );

      expect(row['avatar_path'], 'user-1/old.png');
      expect(
        requests.where(
          (request) => _isProfile(request) && request.method != 'GET',
        ),
        isEmpty,
      );
      for (final request in requests.where(_isDelete)) {
        expect(
          jsonDecode(request.body)['prefixes'],
          isNot(contains('user-1/old.png')),
        );
      }
    },
  );

  test(
    'confirmed failed profile write deletes only the unreferenced uploaded object',
    () async {
      row['avatar_path'] = 'user-1/old.png';
      overrideResponse = (request) =>
          _isProfile(request) && request.method == 'POST'
          ? _json(
              {'message': 'save rejected', 'code': '42501'},
              status: 403,
              request: request,
            )
          : null;

      await expectLater(
        repository.save(profile(avatarPath: 'user-1/old.png'), photo: _photo()),
        throwsA(isA<PostgrestException>()),
      );

      final uploadedPath = requests
          .singleWhere(_isUpload)
          .url
          .path
          .substring('/storage/v1/object/profile-pictures/'.length);
      expect(jsonDecode(requests.singleWhere(_isDelete).body), {
        'prefixes': [uploadedPath],
      });
      expect(row['avatar_path'], 'user-1/old.png');
      final verification = requests.singleWhere(
        (request) => _isProfile(request) && request.method == 'GET',
      );
      expect(verification.url.queryParameters, containsPair('id', 'eq.user-1'));
      expect(
        verification.url.queryParameters,
        containsPair('select', 'avatar_path'),
      );
    },
  );

  test(
    'lost profile response never deletes a photo already committed as current',
    () async {
      row['avatar_path'] = 'user-1/old.png';
      overrideResponse = (request) {
        if (_isProfile(request) && request.method == 'POST') {
          row = {...row, ...jsonDecode(request.body) as Map<String, dynamic>};
          throw http.ClientException('response lost after commit');
        }
        return null;
      };

      await expectLater(
        repository.save(profile(avatarPath: 'user-1/old.png'), photo: _photo()),
        throwsA(anything),
      );

      expect(row['avatar_path'], isNot('user-1/old.png'));
      expect(requests.where(_isDelete), isEmpty);
    },
  );

  test(
    'failed verification preserves private upload when commit outcome is unknown',
    () async {
      overrideResponse = (request) {
        if (_isProfile(request)) throw http.ClientException('connection lost');
        return null;
      };

      await expectLater(
        repository.save(profile(), photo: _photo()),
        throwsA(anything),
      );

      expect(requests.where(_isUpload), hasLength(1));
      expect(requests.where(_isDelete), isEmpty);
    },
  );

  test(
    'old-object cleanup failure does not undo a successful replacement',
    () async {
      row['avatar_path'] = 'user-1/old.png';
      overrideResponse = (request) => _isDelete(request)
          ? _json(
              {'message': 'cleanup unavailable', 'error': 'Forbidden'},
              status: 403,
              request: request,
            )
          : null;

      final saved = await repository.save(
        profile(avatarPath: 'user-1/old.png'),
        photo: _photo(),
      );

      expect(saved.avatarPath, row['avatar_path']);
      expect(saved.avatarPath, isNot('user-1/old.png'));
      expect(saved.avatarUrl, isNotNull);
    },
  );

  test(
    'never attempts cleanup of a former path belonging to another user',
    () async {
      final saved = await repository.save(
        profile(avatarPath: 'user-2/old.png'),
        photo: _photo(),
      );

      expect(saved.avatarPath, startsWith('user-1/'));
      expect(requests.where(_isDelete), isEmpty);
    },
  );

  test(
    'a different profile owner is rejected before upload or database writes',
    () async {
      final other = UserProfile.fromMap(_row(), _user('user-2'));
      await expectLater(
        repository.save(other, photo: _photo()),
        throwsA(isA<AuthException>()),
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'account switch during upload prevents profile writes and cross-account cleanup',
    () async {
      overrideResponse = (request) async {
        if (_isUpload(request)) await _recoverUser(client, 'user-2');
        return null;
      };

      await expectLater(
        repository.save(profile(), photo: _photo()),
        throwsA(isA<AuthException>()),
      );

      expect(requests.where(_isProfile), isEmpty);
      expect(requests.where(_isDelete), isEmpty);
      expect(requests.where(_isSign), isEmpty);
    },
  );

  test(
    'account switch during cleanup verification prevents any delete under the new user',
    () async {
      overrideResponse = (request) async {
        if (_isProfile(request) && request.method == 'POST') {
          return _json(
            {'message': 'save rejected', 'code': '42501'},
            status: 403,
            request: request,
          );
        }
        if (_isProfile(request) && request.method == 'GET') {
          await _recoverUser(client, 'user-2');
        }
        return null;
      };

      await expectLater(
        repository.save(profile(), photo: _photo()),
        throwsA(anything),
      );

      expect(requests.where(_isDelete), isEmpty);
    },
  );

  test(
    'signed URL failure returns otherwise valid profile without a fabricated image',
    () async {
      row['avatar_path'] = 'user-1/existing.png';
      overrideResponse = (request) => _isSign(request)
          ? _json(
              {'message': 'image unavailable', 'error': 'Forbidden'},
              status: 403,
              request: request,
            )
          : null;

      final loaded = await repository.fetchCurrentProfile();

      expect(loaded.fullName, 'Existing Person');
      expect(loaded.avatarPath, 'user-1/existing.png');
      expect(loaded.avatarUrl, isNull);
    },
  );

  test(
    'account switch during signed-URL lookup rejects the old profile',
    () async {
      row['avatar_path'] = 'user-1/existing.png';
      overrideResponse = (request) async {
        if (_isSign(request)) await _recoverUser(client, 'user-2');
        return null;
      };

      await expectLater(
        repository.fetchCurrentProfile(),
        throwsA(isA<AuthException>()),
      );
    },
  );

  for (final path in [
    'user-2/photo.png',
    'user-1/../photo.png',
    'https://example.test/photo.png',
    'user-1/photo.svg',
    'user-1/a/b.png',
  ]) {
    test(
      'does not request a signed URL for an unsafe avatar path: $path',
      () async {
        row['avatar_path'] = path;
        final loaded = await repository.fetchCurrentProfile();
        expect(loaded.avatarUrl, isNull);
        expect(requests.where(_isSign), isEmpty);
      },
    );
  }

  group('Google avatar metadata', () {
    test('uses trusted HTTPS Google metadata without serializing the URL', () {
      final user = _user(
        'user-1',
        google: true,
        metadata: {
          'avatar_url': 'https://lh3.googleusercontent.com/a/photo=s96-c',
        },
      );
      final model =
          UserProfile.fromMap({
            ..._row(),
            'avatar_path': 'user-1/chosen.png',
          }, user).copyWith(
            avatarUrl: 'https://evercare-profile.test/private?token=secret',
          );

      expect(
        model.googleAvatarUrl,
        'https://lh3.googleusercontent.com/a/photo=s96-c',
      );
      expect(model.avatarPath, 'user-1/chosen.png');
      expect(model.toDatabaseJson()['avatar_path'], 'user-1/chosen.png');
      expect(
        model.toDatabaseJson().toString(),
        isNot(contains('googleusercontent')),
      );
      expect(model.toDatabaseJson().toString(), isNot(contains('token=')));
    });

    test('Google metadata is ignored for a non-Google account', () {
      final user = _user(
        'user-1',
        metadata: {'picture': 'https://lh3.googleusercontent.com/photo'},
      );
      expect(UserProfile.fromAccount(user).googleAvatarUrl, isNull);
    });

    test(
      'falls back to a valid picture field when avatar_url is untrusted',
      () {
        final user = _user(
          'user-1',
          google: true,
          metadata: {
            'avatar_url': 'https://attacker.test/photo',
            'picture': 'https://lh3.googleusercontent.com/photo',
          },
        );
        expect(
          UserProfile.fromAccount(user).googleAvatarUrl,
          'https://lh3.googleusercontent.com/photo',
        );
      },
    );

    for (final url in [
      'http://lh3.googleusercontent.com/photo',
      'https://googleusercontent.com.attacker.test/photo',
      'https://evilgoogleusercontent.com/photo',
      'https://name:password@lh3.googleusercontent.com/photo',
      'https://lh3.googleusercontent.com:8443/photo',
      'file:///private/photo.png',
      'data:image/png;base64,AAAA',
      'not a URL',
      'https://lh3.googleusercontent.com/${'x' * 2048}',
    ]) {
      test(
        'rejects unsafe metadata URL ${url.length > 120 ? '(oversized)' : url}',
        () {
          final user = _user(
            'user-1',
            google: true,
            metadata: {'avatar_url': url},
          );
          expect(UserProfile.fromAccount(user).googleAvatarUrl, isNull);
        },
      );
    }
  });
}

bool _isProfile(http.Request request) =>
    request.url.path == '/rest/v1/profiles';
bool _isUpload(http.Request request) =>
    request.method == 'POST' &&
    request.url.path.startsWith('/storage/v1/object/profile-pictures/');
bool _isSign(http.Request request) =>
    request.url.path.startsWith('/storage/v1/object/sign/');
bool _isDelete(http.Request request) =>
    request.method == 'DELETE' &&
    request.url.path == '/storage/v1/object/profile-pictures';

Map<String, dynamic> _row() => {
  'id': 'user-1',
  'full_name': 'Existing Person',
  'phone_number': '',
  'birth_date': '1960-01-01',
  'user_type': 'senior',
  'address': '',
  'avatar_path': null,
};

ProfilePhotoUpload _photo() => ProfilePhotoUpload(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aEfcAAAAASUVORK5CYII=',
  ),
);

http.Response _json(Object? value, {int status = 200, http.Request? request}) =>
    http.Response(
      jsonEncode(value),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );

User _user(
  String id, {
  bool google = false,
  Map<String, dynamic> metadata = const {},
}) => User(
  id: id,
  appMetadata: {
    'provider': google ? 'google' : 'email',
    'providers': [google ? 'google' : 'email'],
  },
  userMetadata: metadata,
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
  email: '$id@example.invalid',
);

Future<void> _recoverUser(SupabaseClient client, String id) async {
  String segment(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiry =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  await client.auth.recoverSession(
    jsonEncode({
      'access_token':
          '${segment({'alg': 'HS256', 'typ': 'JWT'})}.${segment({'sub': id, 'exp': expiry})}.test-signature',
      'refresh_token': 'test-refresh-token',
      'token_type': 'bearer',
      'user': _user(id).toJson(),
    }),
  );
}
