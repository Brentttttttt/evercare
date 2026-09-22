import 'dart:async';
import 'dart:convert';

import 'package:evercare/models/appointment.dart';
import 'package:evercare/models/medication.dart';
import 'package:evercare/models/medication_dose.dart';
import 'package:evercare/models/scheduled_reminder.dart';
import 'package:evercare/repositories/appointment_repository.dart';
import 'package:evercare/repositories/medication_repository.dart';
import 'package:evercare/services/auth_service.dart';
import 'package:evercare/services/reminder_changes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;
  late MedicationRepository medications;
  late AppointmentRepository appointments;
  late List<http.Request> requests;
  late List<({String userId, ReminderKind kind, String? resourceId})> changes;
  Future<http.Response> Function(http.Request request)? onRequest;

  setUp(() async {
    requests = [];
    changes = [];
    onRequest = null;
    ReminderChanges.onChanged = (userId, kind, resourceId) async {
      changes.add((userId: userId, kind: kind, resourceId: resourceId));
    };
    ReminderChanges.onSigningOut = null;
    client = SupabaseClient(
      'https://example.test',
      'test-public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        return onRequest != null
            ? onRequest!(request)
            : _response(request, '[{"id":"resource-1"}]');
      }),
    );
    await _recoverUser(client, 'user-1');
    medications = MedicationRepository(client);
    appointments = AppointmentRepository(client);
  });

  tearDown(() async {
    ReminderChanges.onChanged = null;
    ReminderChanges.onSigningOut = null;
    await client.dispose();
  });

  for (final operation in _Operation.values) {
    test(
      '${operation.name} notifies only after its successful write',
      () async {
        onRequest = (request) async {
          expect(changes, isEmpty);
          return _response(request, '[{"id":"resource-1"}]');
        };

        await _run(operation, medications, appointments);

        expect(requests, hasLength(1));
        expect(changes, [
          (
            userId: 'user-1',
            kind: operation.kind,
            resourceId: operation.createsResource ? null : 'resource-1',
          ),
        ]);
      },
    );

    test(
      '${operation.name} retains the original owner during an account switch',
      () async {
        onRequest = (request) async {
          await _recoverUser(client, 'user-2');
          return _response(request, '[{"id":"resource-1"}]');
        };

        await _run(operation, medications, appointments);

        expect(client.auth.currentUser?.id, 'user-2');
        expect(changes.single.userId, 'user-1');
        expect(changes.single.kind, operation.kind);
      },
    );

    test(
      '${operation.name} does not change device reminders after a failed write',
      () async {
        onRequest = (request) async => _response(
          request,
          '{"message":"Write rejected","code":"42501","details":"","hint":""}',
          status: 403,
        );

        await expectLater(
          _run(operation, medications, appointments),
          throwsA(isA<PostgrestException>()),
        );

        expect(changes, isEmpty);
      },
    );
  }

  test(
    'a failed optimistic medication edit does not cancel its reminders',
    () async {
      onRequest = (request) async => _response(request, '[]');

      await expectLater(
        _run(_Operation.medicationUpdate, medications, appointments),
        throwsStateError,
      );

      expect(changes, isEmpty);
    },
  );

  test(
    'a failed optimistic appointment edit does not cancel its reminders',
    () async {
      onRequest = (request) async => _response(request, '[]');

      await expectLater(
        _run(_Operation.appointmentUpdate, medications, appointments),
        throwsStateError,
      );

      expect(changes, isEmpty);
    },
  );

  test(
    'a successful save awaits reconciliation before returning to the UI',
    () async {
      final started = Completer<void>();
      final finish = Completer<void>();
      ReminderChanges.onChanged = (_, _, _) {
        started.complete();
        return finish.future;
      };
      var completed = false;
      final save = _run(
        _Operation.medicationUpdate,
        medications,
        appointments,
      ).then((_) => completed = true);
      await started.future;

      expect(completed, isFalse);
      expect(requests, hasLength(1));
      finish.complete();
      await save;
      expect(completed, isTrue);
    },
  );

  test(
    'notification callback failures do not turn persisted saves into failures',
    () async {
      var attempted = false;
      ReminderChanges.onChanged = (_, _, _) async {
        attempted = true;
        throw StateError('device unavailable');
      };

      await _run(_Operation.medicationUpdate, medications, appointments);

      expect(attempted, isTrue);
      expect(requests, hasLength(1));
    },
  );

  test(
    'repositories remain usable with no notification controller installed',
    () async {
      ReminderChanges.onChanged = null;
      await _run(_Operation.appointmentUpdate, medications, appointments);
      expect(requests, hasLength(1));
    },
  );

  test(
    'cross-account dose actions are rejected before any write or reminder hook',
    () async {
      final occurrence = _occurrence(userId: 'other-user');
      await expectLater(medications.markTaken(occurrence), throwsStateError);
      expect(requests, isEmpty);
      expect(changes, isEmpty);
    },
  );

  test(
    'sign out awaits cancellation before contacting authentication',
    () async {
      final started = Completer<void>();
      final finish = Completer<void>();
      String? cancelledOwner;
      ReminderChanges.onSigningOut = (userId) {
        cancelledOwner = userId;
        started.complete();
        return finish.future;
      };
      onRequest = (request) async => _response(request, '{}');
      final logout = AuthService(client).signOut();
      await started.future;

      expect(cancelledOwner, 'user-1');
      expect(client.auth.currentUser?.id, 'user-1');
      expect(requests, isEmpty);
      finish.complete();
      await logout;
      expect(requests.single.url.path, '/auth/v1/logout');
      expect(client.auth.currentUser, isNull);
    },
  );

  test(
    'a notification cancellation error cannot prevent account sign out',
    () async {
      ReminderChanges.onSigningOut = (_) async =>
          throw StateError('OS unavailable');
      onRequest = (request) async => _response(request, '{}');

      await AuthService(client).signOut();

      expect(requests.single.url.path, '/auth/v1/logout');
      expect(client.auth.currentUser, isNull);
    },
  );
}

enum _Operation {
  medicationCreate,
  medicationUpdate,
  medicationTaken,
  medicationCompleted,
  medicationDelete,
  appointmentCreate,
  appointmentUpdate,
  appointmentCompleted,
  appointmentCancelled,
  appointmentDelete;

  ReminderKind get kind => name.startsWith('medication')
      ? ReminderKind.medication
      : ReminderKind.appointment;

  bool get createsResource =>
      this == medicationCreate || this == appointmentCreate;
}

Future<void> _run(
  _Operation operation,
  MedicationRepository medications,
  AppointmentRepository appointments,
) => switch (operation) {
  _Operation.medicationCreate => medications.create(
    name: 'Medicine',
    dosage: '5 mg',
    purpose: '',
    scheduleDays: {1, 2, 3, 4, 5, 6, 7},
    instructions: '',
    scheduleTime: '09:00:00',
    startDate: null,
    endDate: null,
    isActive: true,
  ),
  _Operation.medicationUpdate => medications.update(
    'resource-1',
    name: 'Medicine',
    dosage: '5 mg',
    purpose: '',
    scheduleDays: {1, 2, 3, 4, 5, 6, 7},
    instructions: '',
    scheduleTime: '09:00:00',
    startDate: null,
    endDate: null,
    isActive: true,
  ),
  _Operation.medicationTaken => medications.markTaken(_occurrence()),
  _Operation.medicationCompleted => medications.markCompleted('resource-1'),
  _Operation.medicationDelete => medications.delete('resource-1'),
  _Operation.appointmentCreate => appointments.create(
    title: 'Visit',
    doctorName: '',
    specialty: '',
    startsAt: DateTime.utc(2026, 9, 30),
    clinic: '',
    address: '',
    notes: '',
  ),
  _Operation.appointmentUpdate => appointments.update(
    'resource-1',
    title: 'Visit',
    doctorName: '',
    specialty: '',
    startsAt: DateTime.utc(2026, 9, 30),
    clinic: '',
    address: '',
    notes: '',
    status: AppointmentStatus.upcoming,
  ),
  _Operation.appointmentCompleted => appointments.markCompleted('resource-1'),
  _Operation.appointmentCancelled => appointments.setStatus(
    'resource-1',
    AppointmentStatus.cancelled,
  ),
  _Operation.appointmentDelete => appointments.delete('resource-1'),
};

MedicationDoseOccurrence _occurrence({String userId = 'user-1'}) =>
    MedicationDoseOccurrence(
      medication: Medication(
        id: 'resource-1',
        userId: userId,
        name: 'Medicine',
        dosage: '5 mg',
        purpose: '',
        frequency: '',
        instructions: '',
        scheduleTime: '09:00:00',
        startDate: null,
        endDate: null,
        isActive: true,
        scheduleDays: const [1, 2, 3, 4, 5, 6, 7],
      ),
      scheduledFor: DateTime.utc(2026, 9, 22, 1),
      state: MedicationDoseState.due,
    );

http.Response _response(
  http.Request request,
  String body, {
  int status = 200,
}) => http.Response(
  body,
  status,
  headers: {'content-type': 'application/json'},
  request: request,
);

Future<void> _recoverUser(SupabaseClient client, String userId) async {
  // An in-memory SDK session, not a real token or network login.
  String segment(Map<String, Object?> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiresAt =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  final token =
      '${segment({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${segment({'sub': userId, 'exp': expiresAt})}.test-signature';
  await client.auth.recoverSession(
    jsonEncode({
      'access_token': token,
      'refresh_token': 'test-refresh-token',
      'expires_in': 3600,
      'token_type': 'bearer',
      'user': {
        'id': userId,
        'aud': 'authenticated',
        'email': '$userId@example.invalid',
        'app_metadata': {
          'provider': 'email',
          'providers': ['email'],
        },
        'user_metadata': <String, dynamic>{},
        'created_at': '2026-01-01T00:00:00Z',
      },
    }),
  );
}
