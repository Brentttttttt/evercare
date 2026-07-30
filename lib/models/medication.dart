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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get scheduleLabel {
    final raw = scheduleTime;
    if (raw == null || raw.isEmpty) return 'No reminder time';
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return raw;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} '
        '${hour >= 12 ? 'PM' : 'AM'}';
  }

  String get startDateLabel => _formatDate(startDate, fallback: 'Not set');
  String get endDateLabel => _formatDate(endDate, fallback: 'Ongoing');
  String get statusLabel => isActive ? 'Active' : 'Inactive';
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
