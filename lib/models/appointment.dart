enum AppointmentStatus { upcoming, completed, missed, cancelled }

/// The caregiver-facing state of a visit at a specific point in time.
///
/// `due` is intentionally derived instead of stored. A saved upcoming visit
/// becomes due at its scheduled time and missed 24 hours later unless it was
/// completed or cancelled.
enum AppointmentVisitState { upcoming, due, completed, missed, cancelled }

class Appointment {
  const Appointment({
    required this.id,
    required this.userId,
    required this.title,
    required this.doctorName,
    required this.specialty,
    required this.startsAt,
    required this.clinic,
    required this.address,
    required this.notes,
    required this.status,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: (json['title'] as String?)?.trim() ?? '',
      doctorName: (json['doctor_name'] as String?)?.trim() ?? '',
      specialty: (json['specialty'] as String?)?.trim() ?? '',
      startsAt:
          DateTime.tryParse(json['starts_at'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      clinic: (json['clinic'] as String?)?.trim() ?? '',
      address: (json['address'] as String?)?.trim() ?? '',
      notes: (json['notes'] as String?)?.trim() ?? '',
      status: AppointmentStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => AppointmentStatus.upcoming,
      ),
      completedAt: _optionalDateTime(json['completed_at']),
      createdAt: _optionalDateTime(json['created_at']),
      updatedAt: _optionalDateTime(json['updated_at']),
    );
  }

  final String id;
  final String userId;
  final String title;
  final String doctorName;
  final String specialty;
  final DateTime startsAt;
  final String clinic;
  final String address;
  final String notes;
  final AppointmentStatus status;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Appointment copyWith({
    DateTime? startsAt,
    AppointmentStatus? status,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Appointment(
      id: id,
      userId: userId,
      title: title,
      doctorName: doctorName,
      specialty: specialty,
      startsAt: startsAt ?? this.startsAt,
      clinic: clinic,
      address: address,
      notes: notes,
      status: status ?? this.status,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get statusLabel => switch (status) {
    AppointmentStatus.upcoming => 'Upcoming',
    AppointmentStatus.completed => 'Completed',
    AppointmentStatus.missed => 'Missed',
    AppointmentStatus.cancelled => 'Cancelled',
  };

  AppointmentVisitState visitStateAt(DateTime value) {
    return switch (status) {
      AppointmentStatus.completed => AppointmentVisitState.completed,
      AppointmentStatus.cancelled => AppointmentVisitState.cancelled,
      AppointmentStatus.missed => AppointmentVisitState.missed,
      AppointmentStatus.upcoming => _scheduledStateAt(value),
    };
  }

  AppointmentVisitState _scheduledStateAt(DateTime value) {
    final now = value.toUtc();
    final scheduled = startsAt.toUtc();
    if (now.isBefore(scheduled)) return AppointmentVisitState.upcoming;
    if (now.isBefore(scheduled.add(const Duration(days: 1)))) {
      return AppointmentVisitState.due;
    }
    return AppointmentVisitState.missed;
  }

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
    return '${months[startsAt.month - 1]} ${startsAt.day}, ${startsAt.year}';
  }

  String get timeLabel {
    final hour = startsAt.hour;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minute = startsAt.minute.toString().padLeft(2, '0');
    return '$displayHour:$minute ${hour >= 12 ? 'PM' : 'AM'}';
  }
}

DateTime? _optionalDateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
