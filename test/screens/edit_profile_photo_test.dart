import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:evercare/models/profile_photo.dart';
import 'package:evercare/routes/app_routes.dart';
import 'package:evercare/screens/authentication/login_screen.dart';
import 'package:evercare/screens/authentication/registration_screen.dart';
import 'package:evercare/screens/profile/edit_profile_screen.dart';
import 'package:evercare/screens/profile/profile_photo_card.dart';
import 'package:evercare/screens/profile/profile_screen.dart';
import 'package:evercare/services/profile_photo_picker.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:evercare/widgets/evercare_backend_scope.dart';
import 'package:evercare/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_EVERCARE_UI')) {
      const fontPath = String.fromEnvironment('UI_REVIEW_FONT');
      if (fontPath.isNotEmpty) {
        final font = FontLoader('Roboto')
          ..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView));
        await font.load();
        // Widget tests use Ahem for an unspecified font (including button
        // styles); use the review font there too, only in optional captures.
        final defaultFont = FontLoader('Ahem')
          ..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView));
        await defaultFont.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final googleFont = FontLoader('GoogleSansAuth')
        ..addFont(rootBundle.load('assets/fonts/google_sans_auth_medium.ttf'));
      await googleFont.load();
    }
  });
  late SupabaseClient client;
  late _Picker picker;
  late Map<String, dynamic> profile;
  late Uint8List photoBytes;
  late List<http.Request> requests;
  var rejectUpload = false;

  setUp(() async {
    photoBytes = await _png();
    picker = _Picker()..result = ProfilePhotoUpload(photoBytes);
    rejectUpload = false;
    requests = [];
    profile = {
      'id': 'photo-user',
      'full_name': 'Maria Dela Cruz',
      'birth_date': '1960-05-03',
      'user_type': 'senior',
      'phone_number': '',
      'address': '',
      'avatar_path': null,
    };
    client = SupabaseClient(
      'https://photo-ui.test',
      'test-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        Object? body;
        var status = 200;
        if (request.url.path == '/rest/v1/profiles') {
          if (request.method == 'POST') {
            profile.addAll(jsonDecode(request.body) as Map<String, dynamic>);
          }
          body = profile;
        } else if (request.url.path.startsWith('/storage/v1/object/sign/')) {
          status = 403;
          body = {'message': 'test deliberately uses an initials fallback'};
        } else if (request.url.path.startsWith(
          '/storage/v1/object/profile-pictures/',
        )) {
          status = rejectUpload ? 403 : 200;
          body = rejectUpload
              ? {'message': 'synthetic private failure', 'error': 'Forbidden'}
              : {'Key': 'profile-pictures/test.png'};
        } else if (request.method == 'DELETE') {
          body = [];
        } else {
          throw StateError('Unexpected test route');
        }
        return http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    final expiry =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000;
    final claims = base64Url
        .encode(utf8.encode(jsonEncode({'sub': 'photo-user', 'exp': expiry})))
        .replaceAll('=', '');
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': 'eyJhbGciOiJIUzI1NiJ9.$claims.test',
        'refresh_token': 'test-refresh',
        'token_type': 'bearer',
        'user': {
          'id': 'photo-user',
          'aud': 'authenticated',
          'email': 'maria@example.test',
          'created_at': '2026-01-01T00:00:00Z',
          'app_metadata': {'provider': 'email'},
          'user_metadata': {},
        },
      }),
    );
  });
  tearDown(() async => client.dispose());

  Future<void> pumpEditor(
    WidgetTester tester, {
    bool setup = false,
    double scale = 1,
    double keyboard = 0,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      EverCareBackendScope(
        client: client,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: child!,
          ),
          routes: {
            AppRoutes.home: (_) => const Scaffold(body: Text('Saved home')),
          },
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => EditProfileScreen(
                      requireSetup: setup,
                      photoPicker: picker,
                    ),
                  ),
                ),
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }

  Future<void> choosePhoto(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Add Photo'));
    await tester.tap(find.text('Add Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from Gallery'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.byType(PrimaryButton);
    await tester.ensureVisible(button);
    final action =
        tester.widget<PrimaryButton>(button).onPressed!
            as Future<void> Function();
    await tester.runAsync(action);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'selection previews without upload and can keep the previous photo',
    (tester) async {
      await pumpEditor(tester);
      await choosePhoto(tester);
      expect(
        tester.widget<ProfilePhotoCard>(find.byType(ProfilePhotoCard)).preview,
        photoBytes,
      );
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
      await tester.tap(find.text('Keep previous photo'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfilePhotoCard>(find.byType(ProfilePhotoCard)).preview,
        isNull,
      );
    },
  );

  testWidgets('cancelled gallery selection leaves picture and form intact', (
    tester,
  ) async {
    picker.result = null;
    await pumpEditor(tester);
    await choosePhoto(tester);
    expect(
      tester.widget<ProfilePhotoCard>(find.byType(ProfilePhotoCard)).preview,
      isNull,
    );
    expect(find.text('Maria Dela Cruz'), findsOneWidget);
    expect(requests.where((r) => r.method != 'GET'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'avatar action opens selection and cancelling a new crop keeps the draft',
    (tester) async {
      await pumpEditor(tester);
      await tester.tap(find.byKey(const ValueKey('edit-profile-photo-button')));
      await tester.pumpAndSettle();
      expect(find.text('Choose from Gallery'), findsOneWidget);
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfilePhotoCard>(find.byType(ProfilePhotoCard)).preview,
        photoBytes,
      );

      picker.result =
          null; // Picker/cropper cancellation is represented by null.
      await tester.tap(find.byKey(const ValueKey('edit-profile-photo-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfilePhotoCard>(find.byType(ProfilePhotoCard)).preview,
        photoBytes,
      );
      expect(requests.where((r) => r.method != 'GET'), isEmpty);
    },
  );

  testWidgets(
    'recovering an interactive crop disables pick and save until it finishes',
    (tester) async {
      final pending = Completer<ProfilePhotoUpload?>();
      picker.pendingRecovery = pending.future;
      await pumpEditor(tester);
      expect(
        tester.widget<ProfilePhotoCard>(find.byType(ProfilePhotoCard)).busy,
        isTrue,
      );
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
      expect(requests.where((r) => r.method != 'GET'), isEmpty);
      pending.complete(ProfilePhotoUpload(photoBytes));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfilePhotoCard>(find.byType(ProfilePhotoCard)).busy,
        isFalse,
      );
      expect(
        tester.widget<ProfilePhotoCard>(find.byType(ProfilePhotoCard)).preview,
        photoBytes,
      );
    },
  );

  testWidgets(
    'saving a photo persists its owner-scoped path and returns to profile',
    (tester) async {
      await pumpEditor(tester);
      await choosePhoto(tester);
      await save(tester);
      expect(profile['avatar_path'], startsWith('photo-user/'));
      expect(profile['avatar_path'], endsWith('.png'));
      expect(profile['full_name'], 'Maria Dela Cruz');
      expect(find.text('Open editor'), findsOneWidget);
    },
  );

  testWidgets('failed upload keeps draft text and selected preview for retry', (
    tester,
  ) async {
    rejectUpload = true;
    await pumpEditor(tester);
    await choosePhoto(tester);
    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.enterText(find.byType(TextFormField).first, 'Maria Updated');
    await save(tester);
    expect(find.text('Maria Updated'), findsOneWidget);
    expect(profile['avatar_path'], isNull);
    expect(profile['full_name'], 'Maria Dela Cruz');
    expect(
      tester.widget<ProfilePhotoCard>(find.byType(ProfilePhotoCard)).preview,
      photoBytes,
    );
    expect(find.textContaining('could not be saved'), findsOneWidget);
    expect(find.textContaining('synthetic private failure'), findsNothing);
  });

  testWidgets('Google setup still requires birthday and role, never a photo', (
    tester,
  ) async {
    profile['birth_date'] = null;
    profile['user_type'] = null;
    await pumpEditor(tester, setup: true);
    await save(tester);
    expect(find.text('Select your date of birth.'), findsOneWidget);
    expect(find.text('Select how you use EverCare.'), findsOneWidget);
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
    expect(find.text('Complete your profile'), findsOneWidget);
  });

  testWidgets('completed setup saves without a photo and enters EverCare', (
    tester,
  ) async {
    await pumpEditor(tester, setup: true);
    await save(tester);
    expect(find.text('Saved home'), findsOneWidget);
    final body =
        jsonDecode(requests.singleWhere((r) => r.method == 'POST').body) as Map;
    expect(body.containsKey('avatar_path'), isFalse);
  });

  testWidgets(
    'recovered Android selection remains a preview until explicit save',
    (tester) async {
      picker.recovered = ProfilePhotoUpload(photoBytes);
      await pumpEditor(tester);
      expect(
        tester.widget<ProfilePhotoCard>(find.byType(ProfilePhotoCard)).preview,
        photoBytes,
      );
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
    },
  );

  testWidgets('edit profile remains scrollable with large text and keyboard', (
    tester,
  ) async {
    await pumpEditor(tester, scale: 3, keyboard: 280);
    await tester.binding.setSurfaceSize(const Size(320, 720));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(PrimaryButton));
    expect(find.byType(PrimaryButton).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  if (const bool.fromEnvironment('CAPTURE_EVERCARE_UI')) {
    for (final page in [
      'login',
      'register',
      'profile',
      'edit-profile',
      'logout',
    ]) {
      testWidgets('visual capture $page uses synthetic data', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final boundaryKey = GlobalKey();
        final screen = switch (page) {
          'login' => const LoginScreen(),
          'register' => const RegistrationScreen(),
          'profile' || 'logout' => const Scaffold(body: ProfileScreen()),
          _ => EditProfileScreen(photoPicker: picker),
        };
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: EverCareBackendScope(
              client: client,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: _reviewTheme(),
                home: screen,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)),
        );
        await tester.pumpAndSettle();
        if (page == 'logout') {
          await tester.ensureVisible(find.text('Log Out'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('tmp/ui-review/$page.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}

// Only optional visual captures load a real font. Explicit button-theme
// families prevent the widget-test Ahem fallback from obscuring their labels.
ThemeData _reviewTheme() {
  final base = AppTheme.light;
  TextStyle label(ButtonStyle? style) =>
      (style?.textStyle?.resolve({}) ?? const TextStyle()).copyWith(
        fontFamily: 'Roboto',
      );
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(label(base.filledButtonTheme.style)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(
          label(base.outlinedButtonTheme.style),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        textStyle: WidgetStatePropertyAll(label(base.textButtonTheme.style)),
      ),
    ),
  );
}

class _Picker implements ProfilePhotoPicker {
  ProfilePhotoUpload? result;
  ProfilePhotoUpload? recovered;
  Future<ProfilePhotoUpload?>? pendingRecovery;
  @override
  Future<ProfilePhotoUpload?> pick(ProfilePhotoSource source) async => result;
  @override
  Future<ProfilePhotoUpload?> recoverLostPhoto() async =>
      pendingRecovery == null ? recovered : await pendingRecovery;
}

Future<Uint8List> _png() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xFF21835B), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(8, 8);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}
