import 'dart:ui' as ui;

import 'package:evercare/models/profile_photo.dart';
import 'package:evercare/services/profile_photo_cropper.dart';
import 'package:evercare/services/profile_photo_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('lost photos from another account are never recovered', () async {
    SharedPreferences.setMockInitialValues({
      DeviceProfilePhotoPicker.pendingOwnerKey: 'other-user',
    });
    final picker = _Picker();
    expect(
      await DeviceProfilePhotoPicker(
        picker: picker,
        currentUserId: () => 'test-user',
      ).recoverLostPhoto(),
      isNull,
    );
    expect(picker.recoveryCalls, 0);
  });

  test(
    'unrelated picker data is not consumed without a profile owner marker',
    () async {
      final picker = _Picker();
      expect(
        await DeviceProfilePhotoPicker(
          picker: picker,
          currentUserId: () => 'test-user',
        ).recoverLostPhoto(),
        isNull,
      );
      expect(picker.recoveryCalls, 0);
    },
  );

  test(
    'matching owner may recover and interrupted SDK errors stay friendly',
    () async {
      SharedPreferences.setMockInitialValues({
        DeviceProfilePhotoPicker.pendingOwnerKey: 'test-user',
      });
      final picker = _Picker();
      await expectLater(
        DeviceProfilePhotoPicker(
          picker: picker,
          currentUserId: () => 'test-user',
        ).recoverLostPhoto(),
        throwsA(isA<ProfilePhotoFailure>()),
      );
      expect(picker.recoveryCalls, 1);
      expect(
        (await SharedPreferences.getInstance()).getString(
          DeviceProfilePhotoPicker.pendingOwnerKey,
        ),
        isNull,
      );
    },
  );

  test('gallery cancellation keeps the profile unchanged', () async {
    final picker = _Picker();
    expect(
      await DeviceProfilePhotoPicker(
        picker: picker,
        currentUserId: () => 'test-user',
      ).pick(ProfilePhotoSource.gallery),
      isNull,
    );
    expect(picker.source, ImageSource.gallery);
    expect(picker.metadata, isFalse);
    expect(picker.quality, 85);
    expect(
      (await SharedPreferences.getInstance()).getString(
        DeviceProfilePhotoPicker.pendingOwnerKey,
      ),
      isNull,
    );
  });

  test(
    'cancelled cropping discards the new draft without changing a photo',
    () async {
      final cropper = _Cropper();
      final picker = _Picker()..file = XFile.fromData(await _png(80, 40));
      final photo = await DeviceProfilePhotoPicker(
        currentUserId: () => 'test-user',
        picker: picker,
        cropper: cropper,
      ).pick(ProfilePhotoSource.gallery);
      expect(photo, isNull);
      expect(cropper.calls, 1);
      expect(
        (await SharedPreferences.getInstance()).getString(
          DeviceProfilePhotoPicker.pendingOwnerKey,
        ),
        isNull,
      );
    },
  );

  test('only the user cropped image becomes the normalized preview', () async {
    final source = XFile.fromData(await _png(400, 200));
    final cropper = _Cropper()..result = XFile.fromData(await _png(60, 40));
    final photo = await DeviceProfilePhotoPicker(
      currentUserId: () => 'test-user',
      picker: _Picker()..file = source,
      cropper: cropper,
    ).pick(ProfilePhotoSource.gallery);
    expect(cropper.input, same(source));
    final codec = await ui.instantiateImageCodec(photo!.bytes);
    final image = (await codec.getNextFrame()).image;
    expect(image.width, 60);
    expect(image.height, 40);
    image.dispose();
    codec.dispose();
  });

  test('invalid image sources never reach the native cropper', () async {
    final cropper = _Cropper();
    final picker = _Picker()
      ..file = XFile.fromData(Uint8List.fromList([1, 2, 3]));
    await expectLater(
      DeviceProfilePhotoPicker(
        currentUserId: () => 'test-user',
        picker: picker,
        cropper: cropper,
      ).pick(ProfilePhotoSource.gallery),
      throwsA(isA<ProfilePhotoFailure>()),
    );
    expect(cropper.calls, 0);
  });

  test('account switch while choosing never opens the photo editor', () async {
    var owner = 'test-user';
    final cropper = _Cropper();
    final picker = _Picker()
      ..file = XFile.fromData(await _png(80, 40))
      ..afterPick = () => owner = 'other-user';
    expect(
      await DeviceProfilePhotoPicker(
        currentUserId: () => owner,
        picker: picker,
        cropper: cropper,
      ).pick(ProfilePhotoSource.gallery),
      isNull,
    );
    expect(cropper.calls, 0);
  });

  test('account switch while cropping discards the crop result', () async {
    var owner = 'test-user';
    final image = XFile.fromData(await _png(80, 40));
    final cropper = _Cropper()
      ..result = image
      ..onCrop = () => owner = 'other-user';
    expect(
      await DeviceProfilePhotoPicker(
        currentUserId: () => owner,
        picker: _Picker()..file = image,
        cropper: cropper,
      ).pick(ProfilePhotoSource.gallery),
      isNull,
    );
    expect(cropper.calls, 1);
  });

  test('crop failures remain friendly and release the pending owner', () async {
    final cropper = _Cropper()
      ..error = const ProfilePhotoFailure('Please choose another photo.');
    await expectLater(
      DeviceProfilePhotoPicker(
        currentUserId: () => 'test-user',
        picker: _Picker()..file = XFile.fromData(await _png(80, 40)),
        cropper: cropper,
      ).pick(ProfilePhotoSource.gallery),
      throwsA(
        isA<ProfilePhotoFailure>().having(
          (error) => error.message,
          'message',
          'Please choose another photo.',
        ),
      ),
    );
    expect(
      (await SharedPreferences.getInstance()).getString(
        DeviceProfilePhotoPicker.pendingOwnerKey,
      ),
      isNull,
    );
  });

  test(
    'recovered owner-bound gallery images still require user cropping',
    () async {
      SharedPreferences.setMockInitialValues({
        DeviceProfilePhotoPicker.pendingOwnerKey: 'test-user',
      });
      final source = XFile.fromData(await _png(80, 40));
      final cropper = _Cropper()..result = XFile.fromData(await _png(30, 30));
      final photo = await DeviceProfilePhotoPicker(
        currentUserId: () => 'test-user',
        picker: _Picker()..lostFiles = [source],
        cropper: cropper,
      ).recoverLostPhoto();
      expect(photo, isNotNull);
      expect(cropper.calls, 1);
      expect(cropper.input, same(source));
    },
  );

  test(
    'desktop users get a friendly message before any picker opens',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final picker = _Picker();
      await expectLater(
        DeviceProfilePhotoPicker(
          currentUserId: () => 'test-user',
          picker: picker,
        ).pick(ProfilePhotoSource.gallery),
        throwsA(
          isA<ProfilePhotoFailure>().having(
            (error) => error.message,
            'message',
            contains('Android or iPhone'),
          ),
        ),
      );
      expect(picker.source, isNull);
    },
  );

  test('picker permissions use a friendly credential-free error', () async {
    final picker = _Picker()
      ..error = PlatformException(code: 'photo_access_denied');
    await expectLater(
      DeviceProfilePhotoPicker(
        picker: picker,
        currentUserId: () => 'test-user',
      ).pick(ProfilePhotoSource.gallery),
      throwsA(
        isA<ProfilePhotoFailure>().having(
          (e) => e.message,
          'message',
          contains('permissions'),
        ),
      ),
    );
  });

  test('actual decoding rejects a fake image filename', () async {
    final file = XFile.fromData(
      Uint8List.fromList([1, 2, 3, 4]),
      name: 'photo.jpg',
      mimeType: 'image/jpeg',
    );
    await expectLater(
      DeviceProfilePhotoPicker.prepare(file),
      throwsA(isA<ProfilePhotoFailure>()),
    );
  });

  test('source uploads are memory bounded before decoding', () async {
    final file = XFile.fromData(
      Uint8List(12 * 1024 * 1024 + 1),
      name: 'large.png',
    );
    await expectLater(
      DeviceProfilePhotoPicker.prepare(file),
      throwsA(isA<ProfilePhotoFailure>()),
    );
  });

  test(
    'a real image is normalized to PNG, resized and aspect-preserving',
    () async {
      final bytes = await _png(1600, 800);
      final photo = await DeviceProfilePhotoPicker.prepare(
        XFile.fromData(bytes, name: 'untrusted-name.txt'),
      );
      expect(photo.bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(photo.bytes.length, lessThan(ProfilePhotoUpload.maximumBytes));
      final codec = await ui.instantiateImageCodec(photo.bytes);
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 768);
      expect(image.height, 384);
      image.dispose();
      codec.dispose();
    },
  );

  test('small valid photos are not unnecessarily enlarged', () async {
    final photo = await DeviceProfilePhotoPicker.prepare(
      XFile.fromData(await _png(32, 16)),
    );
    final codec = await ui.instantiateImageCodec(photo.bytes);
    final image = (await codec.getNextFrame()).image;
    expect(image.width, 32);
    expect(image.height, 16);
    image.dispose();
    codec.dispose();
  });
}

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xFF21835B), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

class _Picker extends ImagePicker {
  int recoveryCalls = 0;
  XFile? file;
  List<XFile>? lostFiles;
  VoidCallback? afterPick;
  @override
  Future<LostDataResponse> retrieveLostData() async {
    recoveryCalls++;
    if (lostFiles != null) return LostDataResponse(files: lostFiles);
    throw PlatformException(code: 'interrupted');
  }

  Object? error;
  ImageSource? source;
  bool? metadata;
  int? quality;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    metadata = requestFullMetadata;
    quality = imageQuality;
    if (error != null) throw error!;
    afterPick?.call();
    return file;
  }
}

class _Cropper implements ProfilePhotoCropper {
  int calls = 0;
  XFile? input;
  XFile? result;
  Object? error;
  VoidCallback? onCrop;

  @override
  Future<XFile?> crop(XFile photo) async {
    calls++;
    input = photo;
    onCrop?.call();
    if (error != null) throw error!;
    return result;
  }
}
