import 'package:evercare/models/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Appointment visit state', () {
    final scheduled = DateTime.utc(2026, 8, 10, 1);

    test('is upcoming before the scheduled instant', () {
      final appointment = _appointment(startsAt: scheduled);

      expect(
        appointment.visitStateAt(
          scheduled.subtract(const Duration(seconds: 1)),
        ),
        AppointmentVisitState.upcoming,
      );
    });

    test('becomes due at the scheduled instant', () {
      final appointment = _appointment(startsAt: scheduled);

      expect(appointment.visitStateAt(scheduled), AppointmentVisitState.due);
      expect(
        appointment.visitStateAt(
          scheduled.add(const Duration(hours: 23, minutes: 59)),
        ),
        AppointmentVisitState.due,
      );
    });

    test('becomes missed at exactly 24 hours', () {
      final appointment = _appointment(startsAt: scheduled);

      expect(
        appointment.visitStateAt(scheduled.add(const Duration(days: 1))),
        AppointmentVisitState.missed,
      );
    });

    test('saved terminal outcomes override the clock', () {
      expect(
        _appointment(
          startsAt: scheduled,
          status: AppointmentStatus.completed,
        ).visitStateAt(scheduled.add(const Duration(days: 30))),
        AppointmentVisitState.completed,
      );
      expect(
        _appointment(
          startsAt: scheduled,
          status: AppointmentStatus.cancelled,
        ).visitStateAt(scheduled.add(const Duration(days: 30))),
        AppointmentVisitState.cancelled,
      );
      expect(
        _appointment(
          startsAt: scheduled,
          status: AppointmentStatus.missed,
        ).visitStateAt(scheduled),
        AppointmentVisitState.missed,
      );
    });

    test('loads missed and completed Supabase outcomes', () {
      final missed = Appointment.fromJson({
        'id': 'appointment-1',
        'user_id': 'user-1',
        'title': 'Follow-up',
        'starts_at': scheduled.toIso8601String(),
        'status': 'missed',
      });
      final completed = Appointment.fromJson({
        'id': 'appointment-2',
        'user_id': 'user-1',
        'title': 'Check-up',
        'starts_at': scheduled.toIso8601String(),
        'status': 'completed',
        'completed_at': '2026-08-11T02:00:00Z',
      });

      expect(missed.status, AppointmentStatus.missed);
      expect(missed.statusLabel, 'Missed');
      expect(missed.completedAt, isNull);
      expect(completed.status, AppointmentStatus.completed);
      expect(completed.completedAt, isNotNull);
    });
  });
}

Appointment _appointment({
  required DateTime startsAt,
  AppointmentStatus status = AppointmentStatus.upcoming,
}) {
  return Appointment(
    id: 'appointment-1',
    userId: 'user-1',
    title: 'General Check-up',
    doctorName: 'Dr. Reyes',
    specialty: 'Family Medicine',
    startsAt: startsAt,
    clinic: 'Community Hospital',
    address: 'Guiguinto, Bulacan',
    notes: '',
    status: status,
  );
}
