import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../models/profile_photo.dart';
import '../theme/app_colors.dart';

/// Cropping only creates a temporary local draft; saving is handled separately.
abstract interface class ProfilePhotoCropper {
  Future<XFile?> crop(XFile photo);
}

class DeviceProfilePhotoCropper implements ProfilePhotoCropper {
  DeviceProfilePhotoCropper({ImageCropper? cropper})
    : _cropper = cropper ?? ImageCropper();

  final ImageCropper _cropper;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static void requireSupportedPlatform() {
    if (!isSupported) {
      throw const ProfilePhotoFailure(
        'Please use the EverCare Android or iPhone app to choose and crop your profile photo.',
      );
    }
  }

  @override
  Future<XFile?> crop(XFile photo) async {
    requireSupportedPlatform();
    try {
      final result = await _cropper.cropImage(
        sourcePath: photo.path,
        maxWidth: 1024,
        maxHeight: 1024,
        compressFormat: ImageCompressFormat.png,
        // Do not pass aspectRatio: that would lock the user's crop shape.
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop profile photo',
            toolbarColor: AppColors.darkGreen,
            toolbarWidgetColor: Colors.white,
            statusBarLight: false,
            navBarLight: true,
            backgroundColor: AppColors.background,
            activeControlsWidgetColor: AppColors.primaryGreen,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio3x2,
            ],
          ),
          IOSUiSettings(
            title: 'Crop profile photo',
            doneButtonTitle: 'Use photo',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: false,
            aspectRatioPickerButtonHidden: false,
            resetAspectRatioEnabled: true,
            rotateButtonsHidden: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
        ],
      );
      // Native Android keeps the last crop for process-death recovery. Do not
      // retain or later restore a crop without the original account-bound flow.
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await _cropper.recoverImage();
        } catch (_) {
          // Cache cleanup is best-effort; this app never consumes cached crops.
        }
      }
      return result == null ? null : XFile(result.path);
    } on PlatformException {
      throw const ProfilePhotoFailure(
        'The photo editor could not open this image. Please try another photo.',
      );
    } on MissingPluginException {
      throw const ProfilePhotoFailure(
        'The photo editor is unavailable. Please restart the updated EverCare app and try again.',
      );
    } catch (_) {
      throw const ProfilePhotoFailure(
        'We could not crop this photo. Please choose it again.',
      );
    }
  }
}
