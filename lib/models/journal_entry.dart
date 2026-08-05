import 'journal_photo.dart';

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.entryAt,
    required this.title,
    required this.body,
    required this.mood,
    required this.symptoms,
    required this.activities,
    required this.tags,
    required this.bookmarked,
    this.photos = const <JournalPhoto>[],
  });

  factory JournalEntry.fromMap(
    Map<String, dynamic> map, {
    List<JournalPhoto> photos = const <JournalPhoto>[],
  }) {
    return JournalEntry(
      id: map['id'] as String,
      entryAt: DateTime.parse(map['entry_at'] as String).toLocal(),
      title: (map['title'] as String?)?.trim() ?? '',
      body: (map['body'] as String?)?.trim() ?? '',
      mood: (map['mood'] as String?)?.trim() ?? '',
      symptoms: _strings(map['symptoms']),
      activities: _strings(map['activities']),
      tags: _strings(map['tags']),
      bookmarked: map['bookmarked'] as bool? ?? false,
      photos: photos,
    );
  }

  final String id;
  final DateTime entryAt;
  final String title;
  final String body;
  final String mood;
  final List<String> symptoms;
  final List<String> activities;
  final List<String> tags;
  final bool bookmarked;
  final List<JournalPhoto> photos;

  JournalEntry copyWith({bool? bookmarked, List<JournalPhoto>? photos}) {
    return JournalEntry(
      id: id,
      entryAt: entryAt,
      title: title,
      body: body,
      mood: mood,
      symptoms: symptoms,
      activities: activities,
      tags: tags,
      bookmarked: bookmarked ?? this.bookmarked,
      photos: photos ?? this.photos,
    );
  }
}

List<String> _strings(dynamic value) => switch (value) {
  List<dynamic> values => values.whereType<String>().toList(growable: false),
  _ => const <String>[],
};
