import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_photo.dart';
import 'profile_photo_cropper.dart';

enum ProfilePhotoSource { gallery, camera }

abstract interface class ProfilePhotoPicker {
  Future<ProfilePhotoUpload?> pick(ProfilePhotoSource source);
  Future<ProfilePhotoUpload?> recoverLostPhoto();
}

class DeviceProfilePhotoPicker implements ProfilePhotoPicker {
  DeviceProfilePhotoPicker({
    required String? Function() currentUserId,
    ImagePicker? picker,
    ProfilePhotoCropper? cropper,
  }) : _currentUserId = currentUserId,
       _picker = picker ?? ImagePicker(),
       _cropper = cropper ?? DeviceProfilePhotoCropper();
  final ImagePicker _picker;
  final ProfilePhotoCropper _cropper;
  final String? Function() _currentUserId;
  static const pendingOwnerKey = 'evercare.profile_photo.pending_owner.v1';

  @override
  Future<ProfilePhotoUpload?> pick(ProfilePhotoSource source) async {
    final owner = _currentUserId();
    if (owner == null) {
      throw const ProfilePhotoFailure(
        'Please sign in before choosing a profile photo.',
      );
    }
    DeviceProfilePhotoCropper.requireSupportedPlatform();
    SharedPreferences? preferences;
    try {
      preferences = await SharedPreferences.getInstance();
      if (_currentUserId() != owner) return null;
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          source == ProfilePhotoSource.camera) {
        final status = await Permission.camera.request();
        if (_currentUserId() != owner) return null;
        if (!status.isGranted) {
          throw const ProfilePhotoFailure(
            'Camera access is off. Allow it in phone settings or choose a photo from your gallery.',
          );
        }
      }
      // Remember only the owner, never images or credentials. A different
      // account must not inherit an interrupted Android picker selection.
      await preferences.setString(pendingOwnerKey, owner);
      if (_currentUserId() != owner) return null;
      final file = await _picker.pickImage(
        source: source == ProfilePhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (_currentUserId() != owner) return null;
      return file == null ? null : await _cropAndPrepare(file, owner);
    } on ProfilePhotoFailure {
      rethrow;
    } on PlatformException {
      throw const ProfilePhotoFailure(
        'The photo picker could not open. Check photo permissions in phone settings and try again.',
      );
    } catch (_) {
      throw const ProfilePhotoFailure(
        'This photo could not be opened. Please choose another image.',
      );
    } finally {
      if (preferences?.getString(pendingOwnerKey) == owner) {
        await preferences!.remove(pendingOwnerKey);
      }
    }
  }

  @override
  Future<ProfilePhotoUpload?> recoverLostPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final owner = _currentUserId();
    if (owner == null) return null;
    final preferences = await SharedPreferences.getInstance();
    if (_currentUserId() != owner) return null;
    if (preferences.getString(pendingOwnerKey) != owner) return null;
    try {
      final result = await _picker.retrieveLostData();
      if (_currentUserId() != owner) return null;
      if (result.isEmpty) return null;
      if (result.files?.isNotEmpty == true) {
        return await _cropAndPrepare(result.files!.first, owner);
      }
      throw const ProfilePhotoFailure(
        'Your photo selection was interrupted. Please choose it again.',
      );
    } on ProfilePhotoFailure {
      rethrow;
    } catch (_) {
      throw const ProfilePhotoFailure(
        'Your photo selection was interrupted. Please choose it again.',
      );
    } finally {
      if (preferences.getString(pendingOwnerKey) == owner) {
        await preferences.remove(pendingOwnerKey);
      }
    }
  }

  Future<ProfilePhotoUpload?> _cropAndPrepare(XFile file, String owner) async {
    if (_currentUserId() != owner) return null;
    // Reject disguised/non-image files and oversized sources before opening a
    // native decoder. The user chooses the crop; normalization happens after it.
    await validateSource(file);
    if (_currentUserId() != owner) return null;
    final cropped = await _cropper.crop(file);
    if (_currentUserId() != owner || cropped == null) return null;
    final prepared = await prepare(cropped);
    return _currentUserId() == owner ? prepared : null;
  }

  @visibleForTesting
  static Future<void> validateSource(XFile file) async {
    final bytes = await _readSource(file);
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      _validateDimensions(descriptor);
    } on ProfilePhotoFailure {
      rethrow;
    } catch (_) {
      throw const ProfilePhotoFailure(
        'Choose a supported image, such as a JPEG, PNG, or WebP photo.',
      );
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  static void _validateDimensions(ui.ImageDescriptor descriptor) {
    if (descriptor.width <= 0 ||
        descriptor.height <= 0 ||
        descriptor.width * descriptor.height > 40000000) {
      throw const ProfilePhotoFailure(
        'This image is too large to prepare. Please choose a smaller photo.',
      );
    }
  }

  static Future<Uint8List> _readSource(XFile file) async {
    // Bound memory before reading the selected file; never trust its extension.
    if (await file.length() > 12 * 1024 * 1024) {
      throw const ProfilePhotoFailure(
        'This photo is too large. Please choose a smaller image.',
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 12 * 1024 * 1024) {
      throw const ProfilePhotoFailure(
        'This photo is empty or too large. Please choose another image.',
      );
    }
    return bytes;
  }

  @visibleForTesting
  static Future<ProfilePhotoUpload> prepare(XFile file) async {
    final bytes = await _readSource(file);
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      _validateDimensions(descriptor);
      final scale = math.min(
        1.0,
        768 / math.max(descriptor.width, descriptor.height),
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * scale).round()),
        targetHeight: math.max(1, (descriptor.height * scale).round()),
      );
      image = (await codec.getNextFrame()).image;
      final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
      if (encoded == null ||
          encoded.lengthInBytes > ProfilePhotoUpload.maximumBytes) {
        throw const ProfilePhotoFailure(
          'This image could not be reduced safely. Please choose another photo.',
        );
      }
      // Re-encoding strips source EXIF/GPS metadata and normalizes the MIME type.
      return ProfilePhotoUpload(
        encoded.buffer.asUint8List(
          encoded.offsetInBytes,
          encoded.lengthInBytes,
        ),
      );
    } on ProfilePhotoFailure {
      rethrow;
    } catch (_) {
      throw const ProfilePhotoFailure(
        'Choose a supported image, such as a JPEG, PNG, or WebP photo.',
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}
