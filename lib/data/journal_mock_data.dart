import '../models/mock_journal_entry.dart';

abstract final class JournalMockData {
  static const moods = ['Happy', 'Calm', 'Tired', 'Sad', 'Worried', 'Unwell'];

  static const symptoms = [
    'Headache',
    'Dizziness',
    'Body pain',
    'Low energy',
    'Poor sleep',
    'No symptoms',
  ];

  static const activities = [
    'Walking',
    'Gardening',
    'Family visit',
    'Reading',
    'Exercise',
    'Resting',
  ];

  static const filters = [
    'All Entries',
    'Happy Moments',
    'Health Notes',
    'Symptoms',
    'Activities',
    'Bookmarked',
  ];

  static const entries = [
    MockJournalEntry(
      title: 'A Peaceful Morning',
      dateLabel: 'Today, 9:20 AM',
      body:
          'I took a short walk in the garden after breakfast. I felt calm and had enough energy throughout the morning.',
      mood: 'Calm',
      tags: ['Walking', 'Good energy'],
      bookmarked: true,
    ),
    MockJournalEntry(
      title: 'Family Visit',
      dateLabel: 'Yesterday, 4:30 PM',
      body:
          'My daughter visited me this afternoon. We talked, looked at old pictures, and had merienda together.',
      mood: 'Happy',
      tags: ['Family visit'],
    ),
    MockJournalEntry(
      title: 'Feeling a Little Tired',
      dateLabel: 'July 18, 7:10 PM',
      body:
          'I felt more tired than usual today, so I rested after lunch. I did not feel dizzy or experience any pain.',
      mood: 'Tired',
      tags: ['Low energy', 'Resting'],
    ),
  ];
}
