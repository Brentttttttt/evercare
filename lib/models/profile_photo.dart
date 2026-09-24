import 'dart:typed_data';

/// A decoded, resized, metadata-free PNG, ready for preview and private upload.
class ProfilePhotoUpload {
  const ProfilePhotoUpload(this.bytes);
  static const maximumBytes = 5 * 1024 * 1024;
  final Uint8List bytes;
}

class ProfilePhotoFailure implements Exception {
  const ProfilePhotoFailure(this.message);
  final String message;
}
