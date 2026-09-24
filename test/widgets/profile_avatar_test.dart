import 'dart:io';
import 'dart:typed_data';

import 'package:evercare/models/user_profile.dart';
import 'package:evercare/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfile _profile({
  String name = 'Maria Dela Cruz',
  String? avatarPath,
  String? avatarUrl,
  String? googleAvatarUrl,
}) => UserProfile(
  id: 'profile-test',
  email: 'synthetic@example.test',
  fullName: name,
  phoneNumber: '',
  birthDate: null,
  userType: 'senior',
  address: '',
  avatarPath: avatarPath,
  avatarUrl: avatarUrl,
  googleAvatarUrl: googleAvatarUrl,
);

void main() {
  late List<Uri> requested;

  setUp(() {
    requested = [];
  });
  tearDown(() {
    debugNetworkImageHttpClientProvider = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  Future<void> pumpAvatar(
    WidgetTester tester,
    UserProfile profile, {
    Uint8List? preview,
    double textScale = 1,
  }) async {
    debugNetworkImageHttpClientProvider = () => _ImageClient(requested);
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: Center(
                child: ProfileAvatar(profile: profile, previewBytes: preview),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  }

  testWidgets('missing images show initials and have a photo semantic label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpAvatar(tester, _profile());
    expect(find.text('MD'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Profile picture for Maria Dela Cruz'),
      findsOneWidget,
    );
    expect(requested, isEmpty);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('empty name has a person fallback without fake identity', (
    tester,
  ) async {
    await pumpAvatar(tester, _profile(name: ''));
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(requested, isEmpty);
  });

  testWidgets('uploaded image failure shows initials, never the Google photo', (
    tester,
  ) async {
    await pumpAvatar(
      tester,
      _profile(
        avatarPath: 'profile-test/photo.png',
        avatarUrl: 'https://storage.example.test/uploaded.png',
        googleAvatarUrl: 'https://lh3.googleusercontent.com/google-photo',
      ),
    );
    expect(requested.map((uri) => uri.host), ['storage.example.test']);
    expect(find.text('MD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an unresolved uploaded photo does not request a Google fallback',
    (tester) async {
      await pumpAvatar(
        tester,
        _profile(
          avatarPath: 'profile-test/photo.png',
          googleAvatarUrl: 'https://lh3.googleusercontent.com/google-photo',
        ),
      );
      expect(requested, isEmpty);
      expect(find.text('MD'), findsOneWidget);
    },
  );

  testWidgets('Google photo is used only without an uploaded image', (
    tester,
  ) async {
    await pumpAvatar(
      tester,
      _profile(
        googleAvatarUrl: 'https://lh3.googleusercontent.com/google-photo',
      ),
    );
    expect(requested.map((uri) => uri.host), ['lh3.googleusercontent.com']);
    expect(find.text('MD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local preview takes priority and corrupt bytes fail safely', (
    tester,
  ) async {
    await pumpAvatar(
      tester,
      _profile(
        avatarPath: 'profile-test/photo.png',
        avatarUrl: 'https://storage.example.test/uploaded.png',
      ),
      preview: Uint8List.fromList([0, 1, 2]),
    );
    expect(tester.widget<Image>(find.byType(Image)).image, isA<MemoryImage>());
    expect(requested, isEmpty);
    expect(find.text('MD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large accessibility text stays within the avatar', (
    tester,
  ) async {
    await pumpAvatar(tester, _profile(), textScale: 3);
    expect(tester.getSize(find.byType(ProfileAvatar)), const Size(96, 96));
    expect(tester.takeException(), isNull);
  });
}

class _ImageClient extends Fake implements HttpClient {
  _ImageClient(this.requested);
  final List<Uri> requested;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requested.add(url);
    return _ImageRequest();
  }
}

class _ImageRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _ImageResponse();
}

class _ImageResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.notFound;

  @override
  Future<T> drain<T>([T? futureValue]) async => futureValue as T;
}
