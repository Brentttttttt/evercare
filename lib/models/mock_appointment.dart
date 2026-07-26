enum MockAppointmentStatus { upcoming, completed, cancelled }

class MockAppointment {
  const MockAppointment({
    required this.id,
    required this.title,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    required this.clinic,
    required this.address,
    required this.notes,
    required this.status,
  });

  final String id;
  final String title;
  final String doctorName;
  final String specialty;
  final DateTime dateTime;
  final String clinic;
  final String address;
  final String notes;
  final MockAppointmentStatus status;

  String get statusLabel => switch (status) {
    MockAppointmentStatus.upcoming => 'Upcoming',
    MockAppointmentStatus.completed => 'Completed',
    MockAppointmentStatus.cancelled => 'Cancelled',
  };

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
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String get timeLabel {
    final hour = dateTime.hour;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$displayHour:$minute ${hour >= 12 ? 'PM' : 'AM'}';
  }
}
