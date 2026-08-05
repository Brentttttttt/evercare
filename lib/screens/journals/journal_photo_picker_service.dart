import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/journal_photo.dart';

enum JournalPhotoSource { camera, gallery }

class JournalPhotoPickResult {
  const JournalPhotoPickResult({
    this.uploads = const <JournalPhotoUpload>[],
    this.error,
  });

  final List<JournalPhotoUpload> uploads;
  final String? error;
}

class JournalPhotoPickerService {
  JournalPhotoPickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  static const _maximumPhotoBytes = 8 * 1024 * 1024;

  final ImagePicker _picker;

  Future<JournalPhotoPickResult> pick(
    JournalPhotoSource source, {
    required int limit,
  }) async {
    if (limit <= 0) return const JournalPhotoPickResult();
    try {
      if (source == JournalPhotoSource.camera &&
          defaultTargetPlatform == TargetPlatform.android) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          return JournalPhotoPickResult(
            error: permission.isPermanentlyDenied
                ? 'Camera access is disabled. Enable it in Android Settings to take a journal photo.'
                : 'Camera permission was denied. Your journal was not changed.',
          );
        }
      }

      final List<XFile> files;
      if (source == JournalPhotoSource.camera) {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 82,
          requestFullMetadata: false,
        );
        files = file == null ? const <XFile>[] : <XFile>[file];
      } else {
        files = await _picker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 82,
          limit: limit,
          requestFullMetadata: false,
        );
      }
      if (files.isEmpty) return const JournalPhotoPickResult();

      final uploads = <JournalPhotoUpload>[];
      var unavailableFiles = 0;
      for (final file in files.take(limit)) {
        try {
          final bytes = await file.readAsBytes();
          if (bytes.isEmpty || bytes.length > _maximumPhotoBytes) {
            unavailableFiles++;
            continue;
          }
          final extension = _fileExtension(file.name, file.mimeType);
          uploads.add(
            JournalPhotoUpload(
              bytes: bytes,
              fileExtension: extension,
              contentType: _contentType(extension, file.mimeType),
            ),
          );
        } catch (_) {
          unavailableFiles++;
        }
      }
      return JournalPhotoPickResult(
        uploads: uploads,
        error: unavailableFiles == 0
            ? null
            : '$unavailableFiles selected photo${unavailableFiles == 1 ? '' : 's'} could not be prepared. Try another image.',
      );
    } on PlatformException catch (error) {
      final denied =
          error.code.toLowerCase().contains('permission') ||
          error.message?.toLowerCase().contains('permission') == true;
      return JournalPhotoPickResult(
        error: denied
            ? 'Photo access was denied. Your journal was not changed.'
            : 'EverCare could not open the photo picker. Please try again.',
      );
    } catch (_) {
      return const JournalPhotoPickResult(
        error: 'The selected photo is unavailable. Your writing is still safe.',
      );
    }
  }

  String _fileExtension(String name, String? mimeType) {
    final dot = name.lastIndexOf('.');
    if (dot >= 0 && dot < name.length - 1) {
      return name.substring(dot + 1).toLowerCase();
    }
    return switch (mimeType?.toLowerCase()) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => 'jpg',
    };
  }

  String _contentType(String extension, String? mimeType) {
    if (mimeType?.startsWith('image/') == true) return mimeType!;
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }
}
