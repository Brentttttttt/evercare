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
  });

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
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

  JournalEntry copyWith({bool? bookmarked}) {
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
    );
  }
}

List<String> _strings(dynamic value) => switch (value) {
  List<dynamic> values => values.whereType<String>().toList(growable: false),
  _ => const <String>[],
};
