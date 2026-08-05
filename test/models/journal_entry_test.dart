import 'package:evercare/models/journal_entry.dart';
import 'package:evercare/models/journal_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy journal rows load without photo metadata', () {
    final entry = JournalEntry.fromMap({
      'id': 'entry-1',
      'entry_at': '2026-08-05T08:30:00.000Z',
      'title': 'A quiet morning',
      'body': 'We shared breakfast together.',
      'mood': 'Calm',
      'symptoms': <String>[],
      'activities': <String>['Reading'],
      'tags': <String>['Favorite meal'],
      'bookmarked': true,
    });

    expect(entry.tags, ['Favorite meal']);
    expect(entry.photos, isEmpty);
    expect(entry.bookmarked, isTrue);
  });

  test('journal rows retain photo metadata and runtime signed URLs', () {
    final photo = JournalPhoto.fromMap({
      'id': 'photo-1',
      'journal_entry_id': 'entry-1',
      'storage_path': 'user-1/entry-1/photo.jpg',
      'display_order': 0,
      'created_at': '2026-08-05T08:31:00.000Z',
    }, signedUrl: 'https://signed.example/photo');
    final entry = JournalEntry.fromMap(
      {
        'id': 'entry-1',
        'entry_at': '2026-08-05T08:30:00.000Z',
        'title': 'A quiet morning',
        'body': 'We shared breakfast together.',
        'mood': 'Happy',
        'symptoms': <String>['No symptoms'],
        'activities': <String>[],
        'tags': <String>[],
        'bookmarked': false,
      },
      photos: [photo],
    );

    expect(entry.photos.single.storagePath, 'user-1/entry-1/photo.jpg');
    expect(entry.photos.single.signedUrl, 'https://signed.example/photo');
  });
}
