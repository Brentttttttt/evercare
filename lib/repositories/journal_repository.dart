import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal_entry.dart';
import '../models/journal_photo.dart';

class JournalPhotoStorageException implements Exception {
  const JournalPhotoStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class JournalRepository {
  JournalRepository(this._client);

  static const _photoBucket = 'journal-photos';
  static const _signedUrlLifetimeSeconds = 3600;

  final SupabaseClient _client;
  final Random _random = Random.secure();

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Sign in to use journals.');
    return id;
  }

  Future<List<JournalEntry>> fetchEntries() async {
    final userId = _userId;
    final rows = await _client
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .order('entry_at', ascending: false);
    final photos = await _fetchPhotos(userId);
    final photosByEntry = <String, List<JournalPhoto>>{};
    for (final photo in photos) {
      photosByEntry.putIfAbsent(photo.journalEntryId, () => []).add(photo);
    }
    return rows
        .map(
          (row) => JournalEntry.fromMap(
            row,
            photos: photosByEntry[row['id']] ?? const <JournalPhoto>[],
          ),
        )
        .toList(growable: false);
  }

  Future<JournalEntry> createEntry({
    required DateTime entryAt,
    required String title,
    required String body,
    required String mood,
    required List<String> symptoms,
    required List<String> activities,
    required List<String> tags,
    List<JournalPhotoUpload> newPhotos = const <JournalPhotoUpload>[],
  }) async {
    final userId = _userId;
    final row = await _client
        .from('journal_entries')
        .insert({
          'user_id': userId,
          'entry_at': entryAt.toUtc().toIso8601String(),
          'title': title.trim(),
          'body': body.trim(),
          'mood': mood,
          'symptoms': symptoms,
          'activities': activities,
          'tags': tags,
          'bookmarked': false,
        })
        .select()
        .single();
    final created = JournalEntry.fromMap(row);
    if (newPhotos.isEmpty) return created;

    try {
      final photos = await _uploadPhotos(
        userId: userId,
        entryId: created.id,
        uploads: newPhotos,
        startingOrder: 0,
      );
      return created.copyWith(photos: photos);
    } catch (error, stackTrace) {
      await _bestEffort(() async {
        await _client
            .from('journal_entries')
            .delete()
            .eq('id', created.id)
            .eq('user_id', userId);
      });
      Error.throwWithStackTrace(
        const JournalPhotoStorageException(
          'The journal photos could not be uploaded.',
        ),
        stackTrace,
      );
    }
  }

  Future<JournalEntry> updateEntry({
    required JournalEntry original,
    required DateTime entryAt,
    required String title,
    required String body,
    required String mood,
    required List<String> symptoms,
    required List<String> activities,
    required List<String> tags,
    List<JournalPhotoUpload> newPhotos = const <JournalPhotoUpload>[],
    Set<String> removedPhotoIds = const <String>{},
  }) async {
    final userId = _userId;
    await _client
        .from('journal_entries')
        .update({
          'entry_at': entryAt.toUtc().toIso8601String(),
          'title': title.trim(),
          'body': body.trim(),
          'mood': mood,
          'symptoms': symptoms,
          'activities': activities,
          'tags': tags,
        })
        .eq('id', original.id)
        .eq('user_id', userId);

    final removedPhotos = original.photos
        .where((photo) => removedPhotoIds.contains(photo.id))
        .toList(growable: false);
    final remainingPhotos = original.photos
        .where((photo) => !removedPhotoIds.contains(photo.id))
        .toList(growable: false);
    final startingOrder = remainingPhotos.fold<int>(
      0,
      (highest, photo) => max(highest, photo.displayOrder + 1),
    );
    var addedPhotos = const <JournalPhoto>[];

    try {
      addedPhotos = await _uploadPhotos(
        userId: userId,
        entryId: original.id,
        uploads: newPhotos,
        startingOrder: startingOrder,
      );
      await _removePhotos(userId, removedPhotos);
      return _fetchEntry(userId, original.id);
    } catch (error, stackTrace) {
      await _deletePhotos(userId, addedPhotos, ignoreErrors: true);
      await _restoreEntry(userId, original);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> setBookmarked(String id, {required bool bookmarked}) async {
    await _client
        .from('journal_entries')
        .update({'bookmarked': bookmarked})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> deleteEntry(String id) async {
    final userId = _userId;
    final photos = await _fetchPhotos(userId, entryId: id);
    if (photos.isNotEmpty) {
      await _client.storage
          .from(_photoBucket)
          .remove(photos.map((photo) => photo.storagePath).toList());
    }
    await _client
        .from('journal_entries')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<JournalEntry> _fetchEntry(String userId, String entryId) async {
    final row = await _client
        .from('journal_entries')
        .select()
        .eq('id', entryId)
        .eq('user_id', userId)
        .single();
    final photos = await _fetchPhotos(userId, entryId: entryId);
    return JournalEntry.fromMap(row, photos: photos);
  }

  Future<List<JournalPhoto>> _fetchPhotos(
    String userId, {
    String? entryId,
  }) async {
    try {
      var query = _client
          .from('journal_entry_photos')
          .select()
          .eq('user_id', userId);
      if (entryId != null) query = query.eq('journal_entry_id', entryId);
      final rows = await query.order('display_order');
      return Future.wait(rows.map(_photoFromRow));
    } on PostgrestException catch (error) {
      if (_photoSchemaIsUnavailable(error)) return const <JournalPhoto>[];
      rethrow;
    }
  }

  Future<JournalPhoto> _photoFromRow(Map<String, dynamic> row) async {
    String? signedUrl;
    try {
      signedUrl = await _client.storage
          .from(_photoBucket)
          .createSignedUrl(
            row['storage_path'] as String,
            _signedUrlLifetimeSeconds,
          );
    } catch (_) {
      signedUrl = null;
    }
    return JournalPhoto.fromMap(row, signedUrl: signedUrl);
  }

  Future<List<JournalPhoto>> _uploadPhotos({
    required String userId,
    required String entryId,
    required List<JournalPhotoUpload> uploads,
    required int startingOrder,
  }) async {
    if (uploads.isEmpty) return const <JournalPhoto>[];
    final storage = _client.storage.from(_photoBucket);
    final uploadedPaths = <String>[];
    try {
      for (var index = 0; index < uploads.length; index++) {
        final upload = uploads[index];
        final path = _newStoragePath(
          userId,
          entryId,
          upload.fileExtension,
          index,
        );
        await storage.uploadBinary(
          path,
          upload.bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            contentType: upload.contentType,
            upsert: false,
          ),
        );
        uploadedPaths.add(path);
      }

      final rows = await _client.from('journal_entry_photos').insert([
        for (var index = 0; index < uploadedPaths.length; index++)
          {
            'user_id': userId,
            'journal_entry_id': entryId,
            'storage_path': uploadedPaths[index],
            'display_order': startingOrder + index,
          },
      ]).select();
      return Future.wait(rows.map(_photoFromRow));
    } catch (error, stackTrace) {
      await _bestEffort(() async {
        if (uploadedPaths.isNotEmpty) await storage.remove(uploadedPaths);
      });
      await _bestEffort(() async {
        if (uploadedPaths.isNotEmpty) {
          await _client
              .from('journal_entry_photos')
              .delete()
              .eq('user_id', userId)
              .inFilter('storage_path', uploadedPaths);
        }
      });
      Error.throwWithStackTrace(
        const JournalPhotoStorageException(
          'The journal photos could not be uploaded.',
        ),
        stackTrace,
      );
    }
  }

  Future<void> _removePhotos(String userId, List<JournalPhoto> photos) async {
    if (photos.isEmpty) return;
    try {
      await _client.storage
          .from(_photoBucket)
          .remove(photos.map((photo) => photo.storagePath).toList());
      await _client
          .from('journal_entry_photos')
          .delete()
          .eq('user_id', userId)
          .inFilter('id', photos.map((photo) => photo.id).toList());
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        const JournalPhotoStorageException(
          'The removed journal photos could not be deleted.',
        ),
        stackTrace,
      );
    }
  }

  Future<void> _deletePhotos(
    String userId,
    List<JournalPhoto> photos, {
    required bool ignoreErrors,
  }) async {
    if (photos.isEmpty) return;
    Future<void> operation() async {
      await _client.storage
          .from(_photoBucket)
          .remove(photos.map((photo) => photo.storagePath).toList());
      await _client
          .from('journal_entry_photos')
          .delete()
          .eq('user_id', userId)
          .inFilter('id', photos.map((photo) => photo.id).toList());
    }

    if (ignoreErrors) {
      await _bestEffort(operation);
    } else {
      await operation();
    }
  }

  Future<void> _restoreEntry(String userId, JournalEntry entry) async {
    await _bestEffort(() async {
      await _client
          .from('journal_entries')
          .update({
            'entry_at': entry.entryAt.toUtc().toIso8601String(),
            'title': entry.title,
            'body': entry.body,
            'mood': entry.mood,
            'symptoms': entry.symptoms,
            'activities': entry.activities,
            'tags': entry.tags,
          })
          .eq('id', entry.id)
          .eq('user_id', userId);
    });
  }

  String _newStoragePath(
    String userId,
    String entryId,
    String extension,
    int index,
  ) {
    final normalizedExtension = switch (extension.toLowerCase()) {
      'jpeg' => 'jpg',
      'png' || 'webp' || 'heic' || 'heif' => extension.toLowerCase(),
      _ => 'jpg',
    };
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final randomPart = _random.nextInt(0x7fffffff).toRadixString(16);
    return '$userId/$entryId/${timestamp}_${index}_$randomPart.$normalizedExtension';
  }

  bool _photoSchemaIsUnavailable(PostgrestException error) =>
      error.code == '42P01' ||
      error.code == 'PGRST204' ||
      error.code == 'PGRST205';

  Future<void> _bestEffort(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      // Preserve the original error while avoiding abandoned uploads where possible.
    }
  }
}
