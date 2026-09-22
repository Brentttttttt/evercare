import 'dart:convert';

import 'package:evercare/models/appointment.dart';
import 'package:evercare/models/medication.dart';
import 'package:evercare/models/medication_dose.dart';
import 'package:evercare/models/scheduled_reminder.dart';
import 'package:evercare/services/reminder_schedule_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const planner = ReminderSchedulePlanner();
  // Monday, 10 August 2026, 8 AM Philippine time.
  final now = DateTime.utc(2026, 8, 10);

  List<ScheduledReminder> plan({
    DateTime? at,
    List<Medication> medications = const [],
    List<Appointment> appointments = const [],
    List<MedicationDose> doses = const [],
    int horizonDays = 30,
    int maxNotifications = 400,
  }) => planner.plan(
    userId: 'user-1',
    now: at ?? now,
    medications: medications,
    appointments: appointments,
    doseEvents: doses,
    horizonDays: horizonDays,
    maxNotifications: maxNotifications,
  );

  group('medication notification occurrences', () {
    test('uses Philippine wall time, including seconds, and selected days', () {
      final reminders = plan(
        medications: [
          _medication(
            scheduleDays: [DateTime.monday],
            scheduleTime: '09:15:30',
          ),
        ],
        horizonDays: 8,
      );

      expect(reminders.map((reminder) => reminder.scheduledForUtc), [
        DateTime.utc(2026, 8, 10, 1, 15, 30),
        DateTime.utc(2026, 8, 17, 1, 15, 30),
      ]);
      expect(
        reminders.every((reminder) => reminder.scheduledForUtc.isUtc),
        isTrue,
      );
      expect(
        reminders.every((reminder) => reminder.kind == ReminderKind.medication),
        isTrue,
      );
      expect(reminders.first.occurrenceUtc, reminders.first.scheduledForUtc);
    });

    test('rolls the Philippine date across the UTC midnight boundary', () {
      final reminders = plan(
        at: DateTime.utc(2026, 8, 9, 15, 59, 59),
        medications: [
          _medication(
            scheduleDays: [DateTime.monday],
            scheduleTime: '00:00:00',
          ),
        ],
        horizonDays: 1,
      );

      expect(reminders.single.scheduledForUtc, DateTime.utc(2026, 8, 9, 16));
    });

    test(
      'device-local now and equivalent offset instant produce same plan',
      () {
        final medication = _medication();
        final first = plan(at: now.toLocal(), medications: [medication]);
        final second = plan(
          at: DateTime.parse('2026-08-10T08:00:00+08:00'),
          medications: [medication],
        );

        expect(
          first.map((value) => value.payload),
          second.map((value) => value.payload),
        );
        expect(first.map((value) => value.id), second.map((value) => value.id));
      },
    );

    test('never creates a burst of past or exactly-due reminders', () {
      final reminders = plan(
        at: DateTime.utc(2026, 8, 10, 1),
        medications: [_medication()],
        horizonDays: 1,
      );

      expect(reminders.single.scheduledForUtc, DateTime.utc(2026, 8, 11, 1));
      expect(
        plan(
          at: DateTime.utc(2026, 8, 10, 2),
          medications: [_medication()],
          horizonDays: 1,
        ).single.scheduledForUtc,
        DateTime.utc(2026, 8, 11, 1),
      );
    });

    test('respects inclusive start and end calendar dates', () {
      final reminders = plan(
        medications: [
          _medication(
            startDate: DateTime(2026, 8, 12),
            endDate: DateTime(2026, 8, 13),
          ),
        ],
      );

      expect(reminders.map((value) => value.scheduledForUtc), [
        DateTime.utc(2026, 8, 12, 1),
        DateTime.utc(2026, 8, 13, 1),
      ]);
    });

    test('includes a medication starting later within the planning window', () {
      final reminders = plan(
        medications: [_medication(startDate: DateTime(2026, 8, 30))],
      );

      expect(reminders.first.scheduledForUtc, DateTime.utc(2026, 8, 30, 1));
      expect(reminders.last.scheduledForUtc, DateTime.utc(2026, 9, 8, 1));
    });

    test('does not extend beyond the end date or planning horizon', () {
      final reminders = plan(medications: [_medication()], horizonDays: 2);

      expect(reminders.map((value) => value.scheduledForUtc), [
        DateTime.utc(2026, 8, 10, 1),
        DateTime.utc(2026, 8, 11, 1),
      ]);
      expect(
        plan(medications: [_medication(endDate: DateTime(2026, 8, 9))]),
        isEmpty,
      );
      expect(
        plan(medications: [_medication(startDate: DateTime(2026, 10, 1))]),
        isEmpty,
      );
      expect(
        plan(
          medications: [
            _medication(
              startDate: DateTime(2026, 8, 12),
              endDate: DateTime(2026, 8, 11),
            ),
          ],
        ),
        isEmpty,
      );
    });

    test('does not schedule inactive or completed medications', () {
      expect(
        plan(
          medications: [
            _medication(id: 'inactive', isActive: false),
            _medication(id: 'completed', completedAt: now),
          ],
        ),
        isEmpty,
      );
    });

    test(
      'does not invent a schedule from frequency text or invalid values',
      () {
        for (final medication in [
          _medication(scheduleDays: []),
          _medication(scheduleDays: [0, 8]),
          _medication(scheduleTime: null),
          _medication(scheduleTime: ''),
          _medication(scheduleTime: '24:00'),
          _medication(scheduleTime: '09:60'),
          _medication(scheduleTime: 'not-a-time'),
        ]) {
          expect(plan(medications: [medication]), isEmpty);
        }
      },
    );

    test(
      'duplicate weekday entries and duplicate rows do not duplicate alarms',
      () {
        final medication = _medication(scheduleDays: [1, 1, 1]);
        final reminders = plan(
          medications: [medication, medication],
          horizonDays: 1,
        );

        expect(reminders, hasLength(1));
      },
    );

    for (final status in [
      MedicationDoseStatus.taken,
      MedicationDoseStatus.skipped,
    ]) {
      test('$status suppresses the Philippine day even after a time edit', () {
        final reminders = plan(
          medications: [_medication(scheduleTime: '17:00:00')],
          doses: [
            _dose(scheduledFor: DateTime.utc(2026, 8, 10, 1), status: status),
          ],
          horizonDays: 2,
        );

        expect(reminders.map((value) => value.scheduledForUtc), [
          DateTime.utc(2026, 8, 11, 9),
        ]);
      });
    }

    test('terminal suppression uses Philippine day rather than UTC day', () {
      final reminders = plan(
        medications: [_medication()],
        doses: [
          _dose(
            scheduledFor: DateTime.utc(2026, 8, 9, 17), // Monday 1 AM PH.
            status: MedicationDoseStatus.taken,
          ),
        ],
        horizonDays: 2,
      );

      expect(reminders.single.scheduledForUtc, DateTime.utc(2026, 8, 11, 1));
    });

    test('previous Philippine day terminal event does not hide today', () {
      final reminders = plan(
        medications: [_medication()],
        doses: [
          _dose(
            scheduledFor: DateTime.utc(2026, 8, 9, 15), // Sunday 11 PM PH.
            status: MedicationDoseStatus.taken,
          ),
        ],
        horizonDays: 1,
      );

      expect(reminders.single.scheduledForUtc, DateTime.utc(2026, 8, 10, 1));
    });

    test('scheduled events do not suppress the planned reminder', () {
      final reminders = plan(
        medications: [_medication()],
        doses: [
          _dose(
            scheduledFor: DateTime.utc(2026, 8, 10, 1),
            status: MedicationDoseStatus.scheduled,
          ),
        ],
        horizonDays: 1,
      );

      expect(reminders, hasLength(1));
    });

    test(
      'missed events suppress only their exact occurrence, not a changed time',
      () {
        final missed = _dose(
          scheduledFor: DateTime.utc(2026, 8, 10, 1),
          status: MedicationDoseStatus.missed,
        );

        expect(
          plan(medications: [_medication()], doses: [missed], horizonDays: 1),
          isEmpty,
        );
        expect(
          plan(
            medications: [_medication(scheduleTime: '17:00')],
            doses: [missed],
            horizonDays: 1,
          ),
          hasLength(1),
        );
      },
    );
  });

  group('appointment notification occurrences', () {
    test('schedules one day before, one hour before, and the visit start', () {
      final start = DateTime.utc(2026, 8, 12, 3);
      final reminders = plan(appointments: [_appointment(startsAt: start)]);

      expect(reminders.map((value) => value.scheduledForUtc), [
        DateTime.utc(2026, 8, 11, 3),
        DateTime.utc(2026, 8, 12, 2),
        start,
      ]);
      expect(reminders.every((value) => value.occurrenceUtc == start), isTrue);
      expect(
        reminders.every((value) => value.kind == ReminderKind.appointment),
        isTrue,
      );
      expect(reminders.map((value) => value.id).toSet(), hasLength(3));
    });

    test(
      'keeps the absolute appointment instant regardless of zone representation',
      () {
        final utc = plan(
          appointments: [_appointment(startsAt: DateTime.utc(2026, 8, 12, 3))],
        );
        final offset = plan(
          appointments: [
            _appointment(startsAt: DateTime.parse('2026-08-12T11:00:00+08:00')),
          ],
        );
        final local = plan(
          appointments: [
            _appointment(startsAt: DateTime.utc(2026, 8, 12, 3).toLocal()),
          ],
        );

        expect(
          utc.map((value) => value.payload),
          offset.map((value) => value.payload),
        );
        expect(
          utc.map((value) => value.payload),
          local.map((value) => value.payload),
        );
      },
    );

    test('skips past lead times instead of firing them immediately', () {
      final reminders = plan(
        appointments: [
          _appointment(startsAt: now.add(const Duration(minutes: 30))),
        ],
      );

      expect(reminders, hasLength(1));
      expect(
        reminders.single.scheduledForUtc,
        now.add(const Duration(minutes: 30)),
      );
    });

    test('skips a lead time exactly at now but keeps later visit start', () {
      final reminders = plan(
        appointments: [
          _appointment(startsAt: now.add(const Duration(hours: 1))),
        ],
      );

      expect(reminders, hasLength(1));
      expect(
        reminders.single.scheduledForUtc,
        now.add(const Duration(hours: 1)),
      );
    });

    test('past and exactly-starting visits produce no catch-up reminders', () {
      expect(
        plan(
          appointments: [
            _appointment(
              id: 'past',
              startsAt: now.subtract(const Duration(days: 1)),
            ),
            _appointment(id: 'now', startsAt: now),
          ],
        ),
        isEmpty,
      );
    });

    test(
      'completed, missed, cancelled, and completion-stamped visits do not notify',
      () {
        final start = now.add(const Duration(days: 2));
        expect(
          plan(
            appointments: [
              for (final status in [
                AppointmentStatus.completed,
                AppointmentStatus.missed,
                AppointmentStatus.cancelled,
              ])
                _appointment(id: status.name, startsAt: start, status: status),
              _appointment(
                id: 'completion-stamped',
                startsAt: start,
                completedAt: now,
              ),
            ],
          ),
          isEmpty,
        );
      },
    );

    test('window includes lead reminders even if the visit is beyond it', () {
      final reminders = plan(
        appointments: [
          _appointment(startsAt: now.add(const Duration(days: 31))),
        ],
      );

      expect(
        reminders.single.scheduledForUtc,
        now.add(const Duration(days: 30)),
      );
    });

    test('edited visit start changes every scheduled identity', () {
      final before = plan(
        appointments: [
          _appointment(startsAt: now.add(const Duration(days: 2))),
        ],
      );
      final after = plan(
        appointments: [
          _appointment(startsAt: now.add(const Duration(days: 3))),
        ],
      );

      expect(
        before
            .map((value) => value.id)
            .toSet()
            .intersection(after.map((value) => value.id).toSet()),
        isEmpty,
      );
    });
  });

  group('isolation, stable identities, and device limits', () {
    test('filters medications, visits, and dose events by signed-in user', () {
      final reminders = plan(
        medications: [
          _medication(),
          _medication(id: 'other-med', userId: 'other-user'),
        ],
        appointments: [
          _appointment(
            userId: 'other-user',
            startsAt: now.add(const Duration(days: 2)),
          ),
        ],
        doses: [
          _dose(
            userId: 'other-user',
            scheduledFor: DateTime.utc(2026, 8, 10, 1),
            status: MedicationDoseStatus.taken,
          ),
        ],
        horizonDays: 1,
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.resourceId, 'med-1');
      expect(reminders.single.userId, 'user-1');
    });

    test(
      'one medication terminal event does not suppress another medication',
      () {
        final reminders = plan(
          medications: [_medication(id: 'med-2')],
          doses: [
            _dose(
              scheduledFor: DateTime.utc(2026, 8, 10, 1),
              status: MedicationDoseStatus.taken,
            ),
          ],
          horizonDays: 1,
        );

        expect(reminders, hasLength(1));
      },
    );

    test('ID is stable across input order, plan renewal, and text edits', () {
      final medications = [_medication(id: 'z'), _medication(id: 'a')];
      final first = plan(medications: medications, horizonDays: 2);
      final second = plan(
        medications: medications.reversed.toList(),
        horizonDays: 2,
      );
      final renewed = plan(
        at: now.add(const Duration(minutes: 30)),
        medications: medications,
        horizonDays: 2,
      );
      final renamed = plan(
        medications: [
          _medication(id: 'z', name: 'Changed health-sensitive name'),
          _medication(id: 'a'),
        ],
        horizonDays: 2,
      );

      expect(first.map((value) => value.id), second.map((value) => value.id));
      expect(first.map((value) => value.id), renewed.map((value) => value.id));
      expect(first.map((value) => value.id), renamed.map((value) => value.id));
      expect(
        first.every((value) => value.id >= 1 && value.id <= 2147483646),
        isTrue,
      );
    });

    test('deterministic probing resolves an actual rolling-hash collision', () {
      // "Aa" and "BB" collide in the explicit multiply-by-31 hash.
      final first = plan(
        medications: [
          _medication(id: 'Aa'),
          _medication(id: 'BB'),
        ],
        horizonDays: 1,
      );
      final second = plan(
        medications: [
          _medication(id: 'BB'),
          _medication(id: 'Aa'),
        ],
        horizonDays: 1,
      );

      expect(first, hasLength(2));
      expect(first[1].id, first[0].id + 1);
      expect(first.map((value) => value.id), second.map((value) => value.id));
    });

    test('resource types with the same opaque ID have separate identities', () {
      final reminders = plan(
        medications: [_medication(id: 'same-id')],
        appointments: [
          _appointment(
            id: 'same-id',
            startsAt: now.add(const Duration(hours: 1)),
          ),
        ],
        horizonDays: 1,
      );

      expect(reminders.map((value) => value.id).toSet(), hasLength(2));
    });

    test(
      'merges chronological order before the cap so appointments are not starved',
      () {
        final reminders = plan(
          medications: List.generate(
            410,
            (index) => _medication(id: 'med-$index'),
          ),
          appointments: [
            _appointment(startsAt: now.add(const Duration(minutes: 15))),
          ],
        );

        expect(reminders, hasLength(400));
        expect(reminders.first.kind, ReminderKind.appointment);
        for (var index = 1; index < reminders.length; index++) {
          expect(
            reminders[index].scheduledForUtc.isBefore(
              reminders[index - 1].scheduledForUtc,
            ),
            isFalse,
          );
        }
      },
    );

    test(
      'can use a smaller platform limit or zero without mutating inputs',
      () {
        final medication = _medication();
        expect(
          plan(medications: [medication], maxNotifications: 2),
          hasLength(2),
        );
        expect(plan(medications: [medication], maxNotifications: 0), isEmpty);
        expect(medication.scheduleDays, [1, 2, 3, 4, 5, 6, 7]);
        final reminders = plan(medications: [medication]);
        expect(() => reminders.clear(), throwsUnsupportedError);
      },
    );

    test('rejects invalid windows and missing users rather than guessing', () {
      expect(() => plan(horizonDays: 0), throwsRangeError);
      expect(() => plan(horizonDays: 367), throwsRangeError);
      expect(() => plan(maxNotifications: -1), throwsRangeError);
      expect(() => plan(maxNotifications: 10001), throwsRangeError);
      expect(
        () => planner.plan(
          userId: ' ',
          now: now,
          medications: [],
          appointments: [],
        ),
        throwsArgumentError,
      );
    });
  });

  group('privacy-safe notification payloads', () {
    test(
      'states the original scheduled PHT time even if delivery is delayed',
      () {
        final medication = plan(medications: [_medication()]).first;
        final appointment = plan(
          appointments: [_appointment(startsAt: DateTime.utc(2026, 8, 12, 3))],
        ).first;

        expect(medication.body, contains('2026-08-10 09:00 PHT'));
        expect(appointment.body, contains('2026-08-12 11:00 PHT'));
        expect(medication.body.toLowerCase(), isNot(contains('take now')));
        expect(appointment.body, isNot(contains('in 1 day')));
      },
    );

    test(
      'generic lock-screen text and payload do not expose health details',
      () {
        final reminders = plan(
          medications: [_medication()],
          appointments: [
            _appointment(startsAt: now.add(const Duration(days: 2))),
          ],
        );

        for (final reminder in reminders) {
          final exposed =
              '${reminder.title} ${reminder.body} ${reminder.payload}';
          for (final secret in [
            'Sensitive medicine',
            '7 mg',
            'Sensitive condition',
            'Sensitive doctor',
            'Sensitive clinic',
            'Sensitive visit',
            'Sensitive notes',
          ]) {
            expect(exposed, isNot(contains(secret)));
          }
          final target = ReminderNotificationTarget.tryParse(reminder.payload)!;
          expect(target.userId, reminder.userId);
          expect(target.resourceId, reminder.resourceId);
          expect(target.kind, reminder.kind);
          expect(target.occurrenceUtc, reminder.occurrenceUtc);
          expect(target.scheduledForUtc, reminder.scheduledForUtc);
        }
      },
    );

    test(
      'rejects malformed, unknown, incomplete, or unbounded tap payloads',
      () {
        final valid =
            jsonDecode(plan(medications: [_medication()]).first.payload)
                as Map<String, dynamic>;
        for (final payload in [
          null,
          '',
          'not-json',
          '[]',
          'null',
          '{}',
          'x' * 2049,
          jsonEncode({...valid, 'version': 2}),
          jsonEncode({...valid, 'kind': 'external-link'}),
          jsonEncode({...valid, 'userId': ''}),
          jsonEncode({...valid, 'resourceId': 10}),
          jsonEncode({...valid, 'resourceId': 'x' * 129}),
          jsonEncode({...valid, 'occurrenceUtc': 'invalid'}),
          jsonEncode({...valid, 'scheduledForUtc': '2026-08-10T09:00:00'}),
          jsonEncode({...valid, 'scheduledForUtc': null}),
        ]) {
          expect(
            ReminderNotificationTarget.tryParse(payload),
            isNull,
            reason: payload,
          );
        }
      },
    );
  });
}

Medication _medication({
  String id = 'med-1',
  String userId = 'user-1',
  String name = 'Sensitive medicine',
  String? scheduleTime = '09:00:00',
  List<int> scheduleDays = const [1, 2, 3, 4, 5, 6, 7],
  DateTime? startDate,
  DateTime? endDate,
  bool isActive = true,
  DateTime? completedAt,
}) => Medication(
  id: id,
  userId: userId,
  name: name,
  dosage: '7 mg',
  purpose: 'Sensitive condition',
  frequency: 'Twice daily', // Intentionally ignored: not an actual schedule.
  instructions: 'Sensitive notes',
  scheduleTime: scheduleTime,
  scheduleDays: scheduleDays,
  startDate: startDate,
  endDate: endDate,
  isActive: isActive,
  completedAt: completedAt,
);

Appointment _appointment({
  String id = 'appointment-1',
  String userId = 'user-1',
  required DateTime startsAt,
  AppointmentStatus status = AppointmentStatus.upcoming,
  DateTime? completedAt,
}) => Appointment(
  id: id,
  userId: userId,
  title: 'Sensitive visit',
  doctorName: 'Sensitive doctor',
  specialty: 'Sensitive specialty',
  startsAt: startsAt,
  clinic: 'Sensitive clinic',
  address: 'Sensitive address',
  notes: 'Sensitive notes',
  status: status,
  completedAt: completedAt,
);

MedicationDose _dose({
  String userId = 'user-1',
  String medicationId = 'med-1',
  required DateTime scheduledFor,
  required MedicationDoseStatus status,
}) => MedicationDose(
  id: 'dose-1',
  userId: userId,
  medicationId: medicationId,
  scheduledFor: scheduledFor,
  status: status,
  takenAt: status == MedicationDoseStatus.taken ? scheduledFor : null,
);
