import 'package:evercare/models/medication.dart';
import 'package:evercare/models/medication_dose.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Medication schedule data', () {
    test('legacy rows without schedule days remain unscheduled', () {
      final medication = Medication.fromJson({
        'id': 'med-1',
        'user_id': 'user-1',
        'name': 'Medicine',
        'dosage': '5 mg',
        'frequency': 'Once daily',
        'schedule_time': '09:00:00',
      });

      expect(medication.scheduleDays, isEmpty);
      expect(medication.hasReminderSchedule, isFalse);
      expect(medication.scheduleDaysLabel, 'No reminder days');
    });

    test('normalizes, validates, sorts, and labels ISO weekdays', () {
      final medication = _medication(scheduleDays: const [7, 3, 1, 3]);
      final decoded = Medication.fromJson({
        'id': medication.id,
        'user_id': medication.userId,
        'name': medication.name,
        'dosage': medication.dosage,
        'schedule_time': medication.scheduleTime,
        'schedule_days': [7, '3', 1, 3, 0, 8, 'invalid'],
      });

      expect(decoded.scheduleDays, [1, 3, 7]);
      expect(decoded.scheduleDaysLabel, 'Mon, Wed, Sun');
      expect(decoded.hasReminderSchedule, isTrue);
      expect(
        () => decoded.scheduleDays.add(DateTime.friday),
        throwsUnsupportedError,
      );
    });

    test('supports PostgreSQL array text and common day labels', () {
      final everyDay = Medication.fromJson({
        'id': 'med-1',
        'user_id': 'user-1',
        'name': 'Medicine',
        'dosage': '5 mg',
        'schedule_time': '09:00:00',
        'schedule_days': '{7,6,5,4,3,2,1}',
      });
      final weekdays = _medication(scheduleDays: const [1, 2, 3, 4, 5]);
      final weekends = _medication(scheduleDays: const [6, 7]);

      expect(everyDay.scheduleDays, [1, 2, 3, 4, 5, 6, 7]);
      expect(everyDay.scheduleDaysLabel, 'Every day');
      expect(weekdays.scheduleDaysLabel, 'Weekdays');
      expect(weekends.scheduleDaysLabel, 'Weekends');
    });

    test('validates reminder time and marks completed records clearly', () {
      final completed = _medication(
        scheduleTime: '23:05:09',
        completedAt: DateTime.utc(2026, 8, 10),
      );

      expect(completed.reminderTime?.hour, 23);
      expect(completed.reminderTime?.minute, 5);
      expect(completed.reminderTime?.second, 9);
      expect(completed.reminderTime?.databaseValue, '23:05:09');
      expect(completed.scheduleLabel, '11:05 PM');
      expect(completed.isCompleted, isTrue);
      expect(completed.statusLabel, 'Completed');
      expect(MedicationScheduleTime.tryParse('24:00'), isNull);
      expect(MedicationScheduleTime.tryParse('09:60'), isNull);
      expect(MedicationScheduleTime.tryParse('not-a-time'), isNull);
    });
  });

  group('MedicationScheduleEngine', () {
    final monday = DateTime.utc(2026, 8, 10);

    test('converts a Philippine wall time to its canonical UTC instant', () {
      final engine = MedicationScheduleEngine();
      final medication = _medication(
        scheduleDays: const [DateTime.monday],
        scheduleTime: '09:15:30',
      );

      expect(
        engine.occurrenceForPhilippineDate(medication, monday),
        DateTime.utc(2026, 8, 10, 1, 15, 30),
      );
    });

    test('uses the Philippine date across the UTC calendar boundary', () {
      final instant = DateTime.utc(2026, 8, 9, 16, 30); // Monday 12:30 AM PH.
      final engine = MedicationScheduleEngine(now: () => instant);
      final medication = _medication(
        scheduleDays: const [DateTime.monday],
        scheduleTime: '09:00:00',
      );

      final wallClock = MedicationScheduleEngine.toPhilippineWallClock(instant);
      expect(wallClock.weekday, DateTime.monday);
      expect(wallClock.day, 10);
      expect(engine.todayOccurrence(medication), DateTime.utc(2026, 8, 10, 1));
      expect(
        engine.currentDose(medication)?.state,
        MedicationDoseState.upcoming,
      );
    });

    test('a late-night dose becomes missed after Philippine midnight', () {
      final engine = MedicationScheduleEngine();
      final medication = _medication(
        scheduleDays: const [DateTime.monday],
        scheduleTime: '23:30:00',
      );
      final scheduled = engine.occurrenceForPhilippineDate(
        medication,
        DateTime.utc(2026, 8, 10),
      );
      final tuesdayAt1230AmPhilippine = DateTime.utc(2026, 8, 10, 16, 30);

      expect(scheduled, DateTime.utc(2026, 8, 10, 15, 30));
      expect(
        engine.previousMidnightCarryover(
          medication,
          at: tuesdayAt1230AmPhilippine,
        ),
        scheduled,
      );
      expect(
        engine.resolveState(
          scheduledFor: scheduled!,
          at: tuesdayAt1230AmPhilippine,
        ),
        MedicationDoseState.missed,
      );

      final earlierMedication = _medication(
        scheduleDays: const [DateTime.monday],
        scheduleTime: '22:30:00',
      );
      expect(
        engine.previousMidnightCarryover(
          earlierMedication,
          at: tuesdayAt1230AmPhilippine,
        ),
        isNull,
      );
    });

    test(
      'does not schedule legacy, invalid, inactive, or finished records',
      () {
        final engine = MedicationScheduleEngine(
          now: () => DateTime.utc(2026, 8, 10, 1),
        );
        final legacy = _medication(scheduleDays: const []);
        final invalidTime = _medication(scheduleTime: '25:00:00');
        final inactive = _medication(isActive: false);
        final finished = _medication(completedAt: DateTime.utc(2026, 8, 9, 12));

        expect(engine.todayOccurrence(legacy), isNull);
        expect(engine.todayOccurrence(invalidTime), isNull);
        expect(engine.todayOccurrence(inactive), isNull);
        expect(engine.todayOccurrence(finished), isNull);
        expect(engine.nextOccurrence(finished), isNull);
      },
    );

    test('applies inclusive start and end date bounds', () {
      final engine = MedicationScheduleEngine();
      final medication = _medication(
        scheduleDays: const [
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
        ],
        startDate: DateTime(2026, 8, 11),
        endDate: DateTime(2026, 8, 11),
      );

      expect(engine.occurrenceForPhilippineDate(medication, monday), isNull);
      expect(
        engine.occurrenceForPhilippineDate(
          medication,
          DateTime.utc(2026, 8, 11),
        ),
        DateTime.utc(2026, 8, 11, 1),
      );
      expect(
        engine.occurrenceForPhilippineDate(
          medication,
          DateTime.utc(2026, 8, 12),
        ),
        isNull,
      );
    });

    test('changes from upcoming to due and missed at exact boundaries', () {
      final engine = MedicationScheduleEngine();
      final scheduled = DateTime.utc(2026, 8, 10, 1);

      expect(
        engine.resolveState(
          scheduledFor: scheduled,
          at: scheduled.subtract(const Duration(microseconds: 1)),
        ),
        MedicationDoseState.upcoming,
      );
      expect(
        engine.resolveState(scheduledFor: scheduled, at: scheduled),
        MedicationDoseState.due,
      );
      expect(
        engine.resolveState(
          scheduledFor: scheduled,
          at: scheduled
              .add(const Duration(hours: 1))
              .subtract(const Duration(microseconds: 1)),
        ),
        MedicationDoseState.due,
      );
      expect(
        engine.resolveState(
          scheduledFor: scheduled,
          at: scheduled.add(const Duration(hours: 1)),
        ),
        MedicationDoseState.missed,
      );
    });

    test('recorded outcomes override the time-derived state', () {
      final engine = MedicationScheduleEngine();
      final scheduled = DateTime.utc(2026, 8, 10, 1);
      final longAfter = scheduled.add(const Duration(days: 1));
      final before = scheduled.subtract(const Duration(hours: 1));

      expect(
        engine.resolveState(
          scheduledFor: scheduled,
          dose: _dose(
            scheduledFor: scheduled,
            status: MedicationDoseStatus.taken,
            takenAt: longAfter,
          ),
          at: longAfter,
        ),
        MedicationDoseState.taken,
      );
      expect(
        engine.resolveState(
          scheduledFor: scheduled,
          dose: _dose(
            scheduledFor: scheduled,
            status: MedicationDoseStatus.missed,
            takenAt: longAfter,
          ),
          at: longAfter,
        ),
        MedicationDoseState.missed,
      );
      expect(
        engine.resolveState(
          scheduledFor: scheduled,
          dose: _dose(
            scheduledFor: scheduled,
            status: MedicationDoseStatus.skipped,
          ),
          at: longAfter,
        ),
        MedicationDoseState.skipped,
      );
      expect(
        engine.resolveState(
          scheduledFor: scheduled,
          dose: _dose(
            scheduledFor: scheduled,
            status: MedicationDoseStatus.missed,
          ),
          at: before,
        ),
        MedicationDoseState.missed,
      );
    });

    test('ignores a dose record belonging to another occurrence', () {
      final scheduled = DateTime.utc(2026, 8, 10, 1);
      final engine = MedicationScheduleEngine(now: () => scheduled);
      final medication = _medication();
      final wrongDose = _dose(
        scheduledFor: scheduled.add(const Duration(days: 1)),
        status: MedicationDoseStatus.taken,
      );

      final occurrence = engine.currentDose(medication, dose: wrongDose);

      expect(occurrence?.dose, isNull);
      expect(occurrence?.state, MedicationDoseState.due);
      expect(occurrence?.canMarkTaken, isTrue);
    });

    test('finds the same-day or next-week occurrence as appropriate', () {
      final engine = MedicationScheduleEngine();
      final medication = _medication(scheduleDays: const [DateTime.monday]);

      expect(
        engine.nextOccurrence(
          medication,
          from: DateTime.utc(2026, 8, 10, 0, 59),
        ),
        DateTime.utc(2026, 8, 10, 1),
      );
      expect(
        engine.nextOccurrence(
          medication,
          from: DateTime.utc(2026, 8, 10, 1, 0, 1),
        ),
        DateTime.utc(2026, 8, 17, 1),
      );
    });

    test('starts searching at a future start date and respects the end', () {
      final engine = MedicationScheduleEngine();
      final available = _medication(
        scheduleDays: const [DateTime.wednesday],
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 3),
      );
      final expired = _medication(
        scheduleDays: const [DateTime.friday],
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 3),
      );

      expect(
        engine.nextOccurrence(available, from: DateTime.utc(2026, 8, 10)),
        DateTime.utc(2026, 9, 2, 1),
      );
      expect(
        engine.nextOccurrence(expired, from: DateTime.utc(2026, 8, 10)),
        isNull,
      );
    });
  });

  group('MedicationDose', () {
    test('decodes persisted UTC timestamps and database status', () {
      final dose = MedicationDose.fromJson({
        'id': 'dose-1',
        'user_id': 'user-1',
        'medication_id': 'med-1',
        'scheduled_for': '2026-08-10T01:00:00+00:00',
        'taken_at': '2026-08-10T01:05:00+00:00',
        'status': 'taken',
      });

      expect(dose.scheduledFor, DateTime.utc(2026, 8, 10, 1));
      expect(dose.takenAt, DateTime.utc(2026, 8, 10, 1, 5));
      expect(dose.status, MedicationDoseStatus.taken);
      expect(dose.isTaken, isTrue);
      expect(dose.status.databaseValue, 'taken');
    });

    test('rejects unknown or internally inconsistent database outcomes', () {
      expect(
        () => MedicationDose.fromJson({
          'id': 'dose-1',
          'user_id': 'user-1',
          'medication_id': 'med-1',
          'scheduled_for': '2026-08-10T01:00:00+00:00',
          'taken_at': null,
          'status': 'future-status',
        }),
        throwsFormatException,
      );
      expect(
        () => MedicationDose.fromJson({
          'id': 'dose-1',
          'user_id': 'user-1',
          'medication_id': 'med-1',
          'scheduled_for': '2026-08-10T01:00:00+00:00',
          'taken_at': '2026-08-10T01:05:00+00:00',
          'status': 'missed',
        }),
        throwsFormatException,
      );
    });
  });
}

Medication _medication({
  List<int> scheduleDays = const [DateTime.monday],
  String? scheduleTime = '09:00:00',
  DateTime? startDate,
  DateTime? endDate,
  bool isActive = true,
  DateTime? completedAt,
}) {
  return Medication(
    id: 'med-1',
    userId: 'user-1',
    name: 'Medicine',
    dosage: '5 mg',
    purpose: '',
    frequency: '',
    instructions: '',
    scheduleTime: scheduleTime,
    startDate: startDate,
    endDate: endDate,
    isActive: isActive,
    scheduleDays: scheduleDays,
    completedAt: completedAt,
  );
}

MedicationDose _dose({
  required DateTime scheduledFor,
  required MedicationDoseStatus status,
  DateTime? takenAt,
}) {
  return MedicationDose(
    id: 'dose-1',
    userId: 'user-1',
    medicationId: 'med-1',
    scheduledFor: scheduledFor,
    status: status,
    takenAt: takenAt,
  );
}
