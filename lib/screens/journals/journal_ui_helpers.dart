import 'package:flutter/material.dart';

IconData journalMoodIcon(String mood) => switch (mood) {
  'Happy' => Icons.sentiment_very_satisfied_rounded,
  'Calm' => Icons.spa_outlined,
  'Tired' => Icons.bedtime_outlined,
  'Sad' => Icons.sentiment_dissatisfied_rounded,
  'Worried' => Icons.sentiment_neutral_rounded,
  _ => Icons.healing_outlined,
};

String journalDateLabel(DateTime value, {bool includeTime = false}) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final date = '${months[value.month - 1]} ${value.day}, ${value.year}';
  if (!includeTime) return date;
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$date · $hour:$minute $period';
}
