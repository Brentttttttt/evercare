import 'package:evercare/models/profile_photo.dart';
import 'package:evercare/services/profile_photo_cropper.dart';
import 'package:evercare/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test(
    'native Android editor starts square but allows free crop and controls',
    () async {
      final native = _NativeCropper()
        ..result = CroppedFile('/temporary/cropped.png');
      final photo = await DeviceProfilePhotoCropper(
        cropper: native,
      ).crop(XFile('/temporary/source.png'));
      expect(photo?.path, '/temporary/cropped.png');
      expect(native.sourcePath, '/temporary/source.png');
      expect(native.aspectRatio, isNull);
      expect(native.format, ImageCompressFormat.png);
      expect(native.maxWidth, 1024);
      expect(native.maxHeight, 1024);
      final android = native.settings!.whereType<AndroidUiSettings>().single;
      expect(android.initAspectRatio, CropAspectRatioPreset.square);
      expect(android.lockAspectRatio, isFalse);
      expect(android.hideBottomControls, isFalse);
      expect(android.showCropGrid, isTrue);
      expect(android.toolbarColor, AppColors.darkGreen);
      expect(native.recoveryCalls, 1);
    },
  );

  test('native cancellation returns null without an error', () async {
    final native = _NativeCropper();
    expect(
      await DeviceProfilePhotoCropper(
        cropper: native,
      ).crop(XFile('/temporary/source.png')),
      isNull,
    );
  });

  test(
    'native error details do not leak into the friendly UI message',
    () async {
      final native = _NativeCropper()
        ..error = PlatformException(
          code: 'crop_error',
          message: 'private file path',
        );
      await expectLater(
        DeviceProfilePhotoCropper(
          cropper: native,
        ).crop(XFile('/temporary/source.png')),
        throwsA(
          isA<ProfilePhotoFailure>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('photo editor'),
              isNot(contains('private file path')),
            ),
          ),
        ),
      );
    },
  );

  test('missing native plugin gives an update/restart message', () async {
    final native = _NativeCropper()..error = MissingPluginException();
    await expectLater(
      DeviceProfilePhotoCropper(
        cropper: native,
      ).crop(XFile('/temporary/source.png')),
      throwsA(
        isA<ProfilePhotoFailure>().having(
          (error) => error.message,
          'message',
          contains('restart'),
        ),
      ),
    );
  });

  test('iOS editor retains crop shape and rotation controls', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final native = _NativeCropper();
    await DeviceProfilePhotoCropper(
      cropper: native,
    ).crop(XFile('/temporary/source.png'));
    final ios = native.settings!.whereType<IOSUiSettings>().single;
    expect(ios.aspectRatioLockEnabled, isFalse);
    expect(ios.aspectRatioPickerButtonHidden, isFalse);
    expect(ios.rotateButtonsHidden, isFalse);
    expect(ios.doneButtonTitle, 'Use photo');
    expect(native.recoveryCalls, 0);
  });

  test('unsupported desktop never invokes the native cropper', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final native = _NativeCropper();
    await expectLater(
      DeviceProfilePhotoCropper(
        cropper: native,
      ).crop(XFile('/temporary/source.png')),
      throwsA(isA<ProfilePhotoFailure>()),
    );
    expect(native.sourcePath, isNull);
  });
}

class _NativeCropper extends ImageCropper {
  Object? error;
  CroppedFile? result;
  String? sourcePath;
  CropAspectRatio? aspectRatio;
  ImageCompressFormat? format;
  int? maxWidth;
  int? maxHeight;
  List<PlatformUiSettings>? settings;
  int recoveryCalls = 0;

  @override
  Future<CroppedFile?> recoverImage() async {
    recoveryCalls++;
    return null;
  }

  @override
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    int? maxWidth,
    int? maxHeight,
    CropAspectRatio? aspectRatio,
    ImageCompressFormat compressFormat = ImageCompressFormat.jpg,
    int compressQuality = 90,
    List<PlatformUiSettings>? uiSettings,
  }) async {
    this.sourcePath = sourcePath;
    this.aspectRatio = aspectRatio;
    format = compressFormat;
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;
    settings = uiSettings;
    if (error != null) throw error!;
    return result;
  }
}
