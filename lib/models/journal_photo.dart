import 'dart:typed_data';

class JournalPhoto {
  const JournalPhoto({
    required this.id,
    required this.journalEntryId,
    required this.storagePath,
    required this.displayOrder,
    required this.createdAt,
    this.signedUrl,
  });

  factory JournalPhoto.fromMap(Map<String, dynamic> map, {String? signedUrl}) {
    return JournalPhoto(
      id: map['id'] as String,
      journalEntryId: map['journal_entry_id'] as String,
      storagePath: map['storage_path'] as String,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      signedUrl: signedUrl,
    );
  }

  final String id;
  final String journalEntryId;
  final String storagePath;
  final int displayOrder;
  final DateTime createdAt;

  /// A short-lived URL generated from the private Supabase Storage path.
  /// This value is intentionally never serialized back to the database.
  final String? signedUrl;
}

class JournalPhotoUpload {
  const JournalPhotoUpload({
    required this.bytes,
    required this.fileExtension,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileExtension;
  final String contentType;
}
