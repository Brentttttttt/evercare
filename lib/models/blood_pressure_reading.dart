class BloodPressureReading {
  const BloodPressureReading({
    required this.id,
    required this.userId,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.measuredAt,
    required this.source,
    required this.isMedicallyVerified,
    this.monitorName,
    this.decoderName,
    this.rawPacketHex,
    this.notes,
  });

  factory BloodPressureReading.fromMap(Map<String, dynamic> map) {
    return BloodPressureReading(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      systolic: (map['systolic'] as num).toInt(),
      diastolic: (map['diastolic'] as num).toInt(),
      pulse: (map['pulse'] as num).toInt(),
      measuredAt: DateTime.parse(map['measured_at'] as String).toLocal(),
      source: map['source'] as String,
      monitorName: map['monitor_name'] as String?,
      decoderName: map['decoder_name'] as String?,
      rawPacketHex: map['raw_packet_hex'] as String?,
      notes: map['notes'] as String?,
      isMedicallyVerified: map['is_medically_verified'] as bool? ?? false,
    );
  }

  final String id;
  final String userId;
  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime measuredAt;
  final String source;
  final String? monitorName;
  final String? decoderName;
  final String? rawPacketHex;
  final String? notes;
  final bool isMedicallyVerified;

  String get reading => '$systolic/$diastolic mmHg';
  String get statusLabel =>
      isMedicallyVerified ? 'Clinician verified' : 'Not medically verified';
  String get sourceLabel => source == 'ble' ? 'Bluetooth (BLE)' : 'Manual';

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
