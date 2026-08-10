import 'medication.dart';

enum MedicationDoseStatus {
  scheduled,
  taken,
  skipped,
  missed;

  factory MedicationDoseStatus.fromDatabase(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return MedicationDoseStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => throw FormatException(
        'Unknown medication dose status: ${value ?? 'null'}.',
      ),
    );
  }

  String get databaseValue => name;
}

/// The time-dependent state shown to the caregiver.
///
/// `due` is intentionally derived rather than stored because it changes as
/// time passes. A scheduled dose becomes missed exactly one hour after its
/// scheduled time unless a taken or skipped record overrides the clock.
enum MedicationDoseState { upcoming, due, taken, skipped, missed }

class MedicationDose {
  const MedicationDose({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.scheduledFor,
    required this.status,
    this.takenAt,
    this.createdAt,
    this.updatedAt,
  });

  factory MedicationDose.fromJson(Map<String, dynamic> json) {
    final status = MedicationDoseStatus.fromDatabase(json['status']);
    final takenAt = _dateTimeFromJson(json['taken_at']);
    if ((status == MedicationDoseStatus.taken) != (takenAt != null)) {
      throw const FormatException(
        'Medication dose status and taken time are inconsistent.',
      );
    }
    return MedicationDose(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      medicationId: json['medication_id'] as String,
      scheduledFor: _requiredDateTime(json['scheduled_for']),
      status: status,
      takenAt: takenAt,
      createdAt: _dateTimeFromJson(json['created_at']),
      updatedAt: _dateTimeFromJson(json['updated_at']),
    );
  }

  final String id;
  final String userId;
  final String medicationId;

  /// The canonical occurrence instant. Repository values should be UTC.
  final DateTime scheduledFor;
  final MedicationDoseStatus status;
  final DateTime? takenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isTaken => status == MedicationDoseStatus.taken;
}

class MedicationDoseOccurrence {
  const MedicationDoseOccurrence({
    required this.medication,
    required this.scheduledFor,
    required this.state,
    this.dose,
  });

  final Medication medication;
  final DateTime scheduledFor;
  final MedicationDoseState state;
  final MedicationDose? dose;

  DateTime get missedAt =>
      scheduledFor.add(MedicationScheduleEngine.missedAfter);

  /// A missed record can still be corrected honestly as a late taken dose.
  bool get canMarkTaken =>
      state == MedicationDoseState.due || state == MedicationDoseState.missed;
}

typedef MedicationClock = DateTime Function();

/// Pure scheduling rules for one reminder time on each selected weekday.
///
/// Medication wall-clock times use Philippine time (UTC+8). This keeps a
/// patient's schedule stable if a device changes time zone. Returned
/// occurrence instants are always UTC and are safe to store in `timestamptz`.
class MedicationScheduleEngine {
  MedicationScheduleEngine({MedicationClock? now}) : _now = now ?? DateTime.now;

  static const philippineUtcOffset = Duration(hours: 8);
  static const missedAfter = Duration(hours: 1);

  final MedicationClock _now;

  DateTime get nowUtc => _now().toUtc();

  /// Returns Philippine calendar components in a UTC-tagged [DateTime].
  ///
  /// This value is a wall-clock representation, not the original instant. Use
  /// it for its year, month, day, and weekday components only.
  static DateTime toPhilippineWallClock(DateTime instant) {
    final shifted = instant.toUtc().add(philippineUtcOffset);
    return DateTime.utc(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  /// Builds the UTC occurrence for a Philippine calendar date.
  ///
  /// The year, month, and day components of [philippineDate] are interpreted
  /// as a Philippine calendar date regardless of that object's time-zone flag.
  DateTime? occurrenceForPhilippineDate(
    Medication medication,
    DateTime philippineDate,
  ) {
    if (!_canSchedule(medication)) return null;
    final date = DateTime.utc(
      philippineDate.year,
      philippineDate.month,
      philippineDate.day,
    );
    if (!medication.scheduleDays.contains(date.weekday) ||
        !_isWithinDateBounds(medication, date)) {
      return null;
    }
    final time = medication.reminderTime!;
    final philippineWallTime = DateTime.utc(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      time.second,
    );
    return philippineWallTime.subtract(philippineUtcOffset);
  }

  DateTime? todayOccurrence(Medication medication, {DateTime? at}) {
    final instant = (at ?? _now()).toUtc();
    return occurrenceForPhilippineDate(
      medication,
      toPhilippineWallClock(instant),
    );
  }

  /// Returns a previous-day late-night occurrence whose one-hour window
  /// reaches the current Philippine day.
  DateTime? previousMidnightCarryover(Medication medication, {DateTime? at}) {
    final instant = (at ?? _now()).toUtc();
    final wallNow = toPhilippineWallClock(instant);
    final todayWallDate = DateTime.utc(
      wallNow.year,
      wallNow.month,
      wallNow.day,
    );
    final todayStartUtc = todayWallDate.subtract(philippineUtcOffset);
    final previous = occurrenceForPhilippineDate(
      medication,
      todayWallDate.subtract(const Duration(days: 1)),
    );
    if (previous == null || previous.add(missedAfter).isBefore(todayStartUtc)) {
      return null;
    }
    return previous;
  }

  /// Returns the first scheduled occurrence at or after [from].
  DateTime? nextOccurrence(Medication medication, {DateTime? from}) {
    if (!_canSchedule(medication)) return null;
    final fromUtc = (from ?? _now()).toUtc();
    final wallFrom = toPhilippineWallClock(fromUtc);
    var date = DateTime.utc(wallFrom.year, wallFrom.month, wallFrom.day);

    final startDate = medication.startDate;
    if (startDate != null) {
      final normalizedStart = _calendarDate(startDate);
      if (normalizedStart.isAfter(date)) date = normalizedStart;
    }

    // A valid non-empty weekday set always has a match within seven days.
    for (var offset = 0; offset <= 7; offset++) {
      final candidateDate = date.add(Duration(days: offset));
      final endDate = medication.endDate;
      if (endDate != null && candidateDate.isAfter(_calendarDate(endDate))) {
        return null;
      }
      final occurrence = occurrenceForPhilippineDate(medication, candidateDate);
      if (occurrence != null && !occurrence.isBefore(fromUtc)) {
        return occurrence;
      }
    }
    return null;
  }

  MedicationDoseState resolveState({
    required DateTime scheduledFor,
    MedicationDose? dose,
    DateTime? at,
  }) {
    if (dose?.isTaken ?? false) return MedicationDoseState.taken;
    if (dose?.status == MedicationDoseStatus.skipped) {
      return MedicationDoseState.skipped;
    }
    if (dose?.status == MedicationDoseStatus.missed) {
      return MedicationDoseState.missed;
    }

    final instant = (at ?? _now()).toUtc();
    final scheduledUtc = scheduledFor.toUtc();
    if (instant.isBefore(scheduledUtc)) return MedicationDoseState.upcoming;
    if (instant.isBefore(scheduledUtc.add(missedAfter))) {
      return MedicationDoseState.due;
    }
    return MedicationDoseState.missed;
  }

  MedicationDoseOccurrence? currentDose(
    Medication medication, {
    MedicationDose? dose,
    DateTime? at,
  }) {
    final instant = (at ?? _now()).toUtc();
    final scheduledFor = todayOccurrence(medication, at: instant);
    if (scheduledFor == null) return null;
    final matchingDose =
        dose != null &&
            dose.medicationId == medication.id &&
            dose.scheduledFor.toUtc().isAtSameMomentAs(scheduledFor)
        ? dose
        : null;
    return MedicationDoseOccurrence(
      medication: medication,
      scheduledFor: scheduledFor,
      dose: matchingDose,
      state: resolveState(
        scheduledFor: scheduledFor,
        dose: matchingDose,
        at: instant,
      ),
    );
  }

  bool _canSchedule(Medication medication) =>
      medication.isActive &&
      !medication.isCompleted &&
      medication.hasReminderSchedule;

  bool _isWithinDateBounds(Medication medication, DateTime date) {
    final startDate = medication.startDate;
    if (startDate != null && date.isBefore(_calendarDate(startDate))) {
      return false;
    }
    final endDate = medication.endDate;
    if (endDate != null && date.isAfter(_calendarDate(endDate))) return false;
    return true;
  }
}

DateTime _calendarDate(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

DateTime _requiredDateTime(Object? value) {
  final parsed = _dateTimeFromJson(value);
  if (parsed == null) {
    throw const FormatException('A medication dose timestamp is required.');
  }
  return parsed;
}

DateTime? _dateTimeFromJson(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}
