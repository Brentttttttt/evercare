class MockJournalEntry {
  const MockJournalEntry({
    required this.title,
    required this.dateLabel,
    required this.body,
    required this.mood,
    required this.tags,
    this.bookmarked = false,
  });

  final String title;
  final String dateLabel;
  final String body;
  final String mood;
  final List<String> tags;
  final bool bookmarked;
}
