class CareBookChapter {
  const CareBookChapter({
    required this.number,
    required this.title,
    required this.readingTime,
    required this.iconName,
    required this.paragraphs,
    this.tips = const [],
    this.checklist = const [],
    this.highlight,
    this.disclaimer,
  });

  final int number;
  final String title;
  final String readingTime;
  final String iconName;
  final List<String> paragraphs;
  final List<String> tips;
  final List<String> checklist;
  final String? highlight;
  final String? disclaimer;
}
