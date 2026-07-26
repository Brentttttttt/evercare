class MockBloodPressureRecord {
  const MockBloodPressureRecord({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.measuredAt,
    required this.status,
    required this.source,
    required this.deviceName,
    required this.notes,
  });

  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime measuredAt;
  final String status;
  final String source;
  final String deviceName;
  final String notes;

  String get reading => '$systolic/$diastolic mmHg';

  String get dateLabel {
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
    return '${months[measuredAt.month - 1]} ${measuredAt.day}, '
        '${measuredAt.year}';
  }

  String get timeLabel {
    final hour = measuredAt.hour;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minute = measuredAt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$displayHour:$minute $period';
  }
}
