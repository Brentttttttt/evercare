class Medication {
  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.purpose,
    required this.frequency,
    required this.instructions,
    required this.scheduleTime,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.scheduleDays = const [],
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: (json['name'] as String?)?.trim() ?? '',
      dosage: (json['dosage'] as String?)?.trim() ?? '',
      purpose: (json['purpose'] as String?)?.trim() ?? '',
      frequency: (json['frequency'] as String?)?.trim() ?? '',
      instructions: (json['instructions'] as String?)?.trim() ?? '',
      scheduleTime: json['schedule_time'] as String?,
      startDate: _dateFromJson(json['start_date']),
      endDate: _dateFromJson(json['end_date']),
      isActive: json['is_active'] as bool? ?? true,
      scheduleDays: _scheduleDaysFromJson(json['schedule_days']),
      completedAt: _dateTimeFromJson(json['completed_at']),
      createdAt: _dateTimeFromJson(json['created_at']),
      updatedAt: _dateTimeFromJson(json['updated_at']),
    );
  }

  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String purpose;
  final String frequency;
  final String instructions;
  final String? scheduleTime;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<int> scheduleDays;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MedicationScheduleTime? get reminderTime =>
      MedicationScheduleTime.tryParse(scheduleTime);

  bool get isCompleted => completedAt != null;

  bool get hasReminderSchedule =>
      scheduleDays.isNotEmpty && reminderTime != null;

  String get scheduleLabel {
    final raw = scheduleTime;
    if (raw == null || raw.isEmpty) return 'No reminder time';
    return reminderTime?.label ?? raw;
  }

  String get scheduleDaysLabel {
    if (scheduleDays.isEmpty) return 'No reminder days';
    if (_sameDays(scheduleDays, const [1, 2, 3, 4, 5, 6, 7])) {
      return 'Every day';
    }
    if (_sameDays(scheduleDays, const [1, 2, 3, 4, 5])) {
      return 'Weekdays';
    }
    if (_sameDays(scheduleDays, const [6, 7])) return 'Weekends';
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return scheduleDays.map((day) => labels[day - 1]).join(', ');
  }

  String get startDateLabel => _formatDate(startDate, fallback: 'Not set');
  String get endDateLabel => _formatDate(endDate, fallback: 'Ongoing');
  String get statusLabel => isCompleted
      ? 'Completed'
      : isActive
      ? 'Active'
      : 'Inactive';
}

/// A validated database `time` value without a dependency on Flutter widgets.
class MedicationScheduleTime {
  const MedicationScheduleTime({
    required this.hour,
    required this.minute,
    this.second = 0,
  });

  static MedicationScheduleTime? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final secondText = parts.length > 2 ? parts[2].split('.').first : '0';
    final second = int.tryParse(secondText);
    if (hour == null ||
        minute == null ||
        second == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59) {
      return null;
    }
    return MedicationScheduleTime(hour: hour, minute: minute, second: second);
  }

  final int hour;
  final int minute;
  final int second;

  String get label {
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} '
        '${hour >= 12 ? 'PM' : 'AM'}';
  }

  String get databaseValue =>
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}:'
      '${second.toString().padLeft(2, '0')}';
}

List<int> _scheduleDaysFromJson(Object? value) {
  final rawValues = switch (value) {
    Iterable<Object?> values => values,
    String text => text.replaceAll(RegExp(r'[{}\[\]\s]'), '').split(','),
    _ => const <Object?>[],
  };
  final days = <int>{};
  for (final value in rawValues) {
    final day = value is int ? value : int.tryParse(value.toString());
    if (day != null && day >= DateTime.monday && day <= DateTime.sunday) {
      days.add(day);
    }
  }
  final sorted = days.toList()..sort();
  return List<int>.unmodifiable(sorted);
}

bool _sameDays(List<int> actual, List<int> expected) {
  if (actual.length != expected.length) return false;
  for (var index = 0; index < actual.length; index++) {
    if (actual[index] != expected[index]) return false;
  }
  return true;
}

DateTime? _dateFromJson(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

DateTime? _dateTimeFromJson(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

String _formatDate(DateTime? value, {required String fallback}) {
  if (value == null) return fallback;
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
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
