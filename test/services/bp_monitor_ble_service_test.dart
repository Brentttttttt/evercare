import 'package:evercare/services/bp_monitor_ble_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _confirmedResultPacket = <int>[
  0x81,
  0x46,
  0x24,
  0x32,
  0x00,
  0x00,
  0x19,
  0x03,
  0x15,
  0x0A,
  0x11,
  0x00,
  0x00,
  0x00,
  0x00,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts without a fallback hardware result', () async {
    final service = BpMonitorBleService();
    addTearDown(service.close);

    expect(service.currentResult, isNull);
    expect(service.hasFinalResult, isFalse);
    expect(service.measurementStartedAt, isNull);
    expect(service.measurementCompletedAt, isNull);
    expect(service.latestProgressPressure, isNull);
  });

  test('0x80 starts a measurement session and updates raw progress', () async {
    final service = BpMonitorBleService();
    addTearDown(service.close);
    final receivedAt = DateTime.utc(2026, 7, 30, 9, 0, 0, 125);

    service.processNotificationForTesting(const <int>[
      0x80,
      0x01,
      0x2C,
    ], receivedAt: receivedAt);

    expect(service.measurementState, BpMonitorMeasurementState.inProgress);
    expect(service.isMeasurementInProgress, isTrue);
    expect(service.measurementStartedAt, receivedAt);
    expect(service.measurementCompletedAt, isNull);
    expect(service.latestProgressPressure, 300);
    expect(service.currentResult, isNull);
  });

  testWidgets('an incomplete connected measurement eventually fails safely', (
    tester,
  ) async {
    final service = BpMonitorBleService();
    addTearDown(service.close);

    service.processNotificationForTesting(const <int>[0x80, 0x00, 0x78]);
    await tester.pump(
      BpMonitorBleService.measurementResultTimeout +
          const Duration(milliseconds: 1),
    );

    expect(service.measurementState, BpMonitorMeasurementState.failed);
    expect(service.currentResult, isNull);
    expect(service.measurementFailureMessage, contains('No final 0x81 result'));
  });

  test(
    'raw capture retains duplicate 0x81 packets while visible result is deduplicated',
    () async {
      final service = BpMonitorBleService();
      addTearDown(service.close);
      final firstAt = DateTime.utc(2026, 7, 30, 9, 5, 0, 100);
      final duplicateAt = firstAt.add(const Duration(seconds: 10));

      service.startNewCapture();
      service.processNotificationForTesting(
        _confirmedResultPacket,
        receivedAt: firstAt,
      );
      final acceptedResult = service.currentResult;
      final originalCompletionTime = service.measurementCompletedAt;

      service.processNotificationForTesting(
        _confirmedResultPacket,
        receivedAt: duplicateAt,
      );

      expect(service.totalPacketCount, 2);
      expect(service.packets.map((packet) => packet.bytes), <List<int>>[
        _confirmedResultPacket,
        _confirmedResultPacket,
      ]);
      expect(service.packets.map((packet) => packet.receivedAt), <DateTime>[
        firstAt,
        duplicateAt,
      ]);
      expect(service.currentResult, same(acceptedResult));
      expect(service.measurementCompletedAt, originalCompletionTime);
      expect(service.measurementCompletedAt, firstAt);
      expect(service.currentResult!.receivedAt, firstAt);
      expect(service.currentResult!.systolic, 70);
      expect(service.currentResult!.diastolic, 36);
      expect(service.currentResult!.pulse, 50);
    },
  );

  test(
    'a later 0x80 packet starts a fresh session for the same result',
    () async {
      final service = BpMonitorBleService();
      addTearDown(service.close);
      final firstResultAt = DateTime.utc(2026, 7, 30, 9, 10);
      final nextProgressAt = firstResultAt.add(const Duration(seconds: 10));
      final secondResultAt = nextProgressAt.add(const Duration(seconds: 2));

      service.processNotificationForTesting(
        _confirmedResultPacket,
        receivedAt: firstResultAt,
      );
      final firstResult = service.currentResult;

      service.processNotificationForTesting(const <int>[
        0x80,
        0x00,
        0x78,
      ], receivedAt: nextProgressAt);

      expect(service.currentResult, isNull);
      expect(service.measurementStartedAt, nextProgressAt);
      expect(service.measurementCompletedAt, isNull);
      expect(service.latestProgressPressure, 120);
      expect(service.measurementState, BpMonitorMeasurementState.inProgress);

      service.processNotificationForTesting(
        _confirmedResultPacket,
        receivedAt: secondResultAt,
      );

      expect(service.currentResult, isNotNull);
      expect(service.currentResult, isNot(same(firstResult)));
      expect(service.currentResult!.rawBytes, _confirmedResultPacket);
      expect(service.currentResult!.receivedAt, secondResultAt);
      expect(service.measurementCompletedAt, secondResultAt);
      expect(
        service.measurementState,
        BpMonitorMeasurementState.resultReceived,
      );
    },
  );

  test(
    'measurement reset actions preserve saved monitor and raw capture state',
    () async {
      final preferences = _FakeSharedPreferencesAsync(<String, Object>{
        'bp_monitor_saved_remote_id': 'saved-monitor-id',
        'bp_monitor_saved_name': 'YK-IBPA1 Family Monitor',
        'bp_monitor_auto_connect': false,
      });
      final service = BpMonitorBleService(preferences: preferences);
      addTearDown(service.close);
      await service.initialize();
      service.startNewCapture();

      final firstAt = DateTime.utc(2026, 7, 30, 9, 20);
      service.processNotificationForTesting(
        _confirmedResultPacket,
        receivedAt: firstAt,
      );
      final captureStart = service.captureStartTime;
      final captureEventCount = service.captureEvents.length;

      service.prepareForNextMeasurement();

      expect(service.currentResult, isNull);
      _expectPairingAndCapturePreserved(
        service,
        expectedPacketCount: 1,
        expectedCaptureStart: captureStart,
        expectedCaptureEventCount: captureEventCount,
      );

      service.processNotificationForTesting(
        _confirmedResultPacket,
        receivedAt: firstAt.add(const Duration(seconds: 5)),
      );
      expect(
        service.currentResult,
        isNull,
        reason: 'UI clearing must not turn a retransmission into a new result.',
      );

      service.processNotificationForTesting(const <int>[
        0x80,
        0x00,
        0x78,
      ], receivedAt: firstAt.add(const Duration(seconds: 6)));
      service.processNotificationForTesting(
        _confirmedResultPacket,
        receivedAt: firstAt.add(const Duration(seconds: 7)),
      );
      expect(service.currentResult, isNotNull);

      service.clearCurrentResult();

      expect(service.currentResult, isNull);
      _expectPairingAndCapturePreserved(
        service,
        expectedPacketCount: 4,
        expectedCaptureStart: captureStart,
        expectedCaptureEventCount: captureEventCount,
      );
      expect(service.packets[0].bytes, _confirmedResultPacket);
      expect(service.packets[1].bytes, _confirmedResultPacket);
      expect(service.packets[2].bytes, const <int>[0x80, 0x00, 0x78]);
      expect(service.packets[3].bytes, _confirmedResultPacket);
    },
  );
}

void _expectPairingAndCapturePreserved(
  BpMonitorBleService service, {
  required int expectedPacketCount,
  required DateTime? expectedCaptureStart,
  required int expectedCaptureEventCount,
}) {
  expect(service.savedIdentifier, 'saved-monitor-id');
  expect(service.savedName, 'YK-IBPA1 Family Monitor');
  expect(service.hasSavedMonitor, isTrue);
  expect(service.autoConnect, isFalse);
  expect(service.captureActive, isTrue);
  expect(service.hasCaptureSession, isTrue);
  expect(service.captureStartTime, expectedCaptureStart);
  expect(service.captureEndTime, isNull);
  expect(service.totalPacketCount, expectedPacketCount);
  expect(service.captureEvents.length, expectedCaptureEventCount);
}

class _FakeSharedPreferencesAsync implements SharedPreferencesAsync {
  _FakeSharedPreferencesAsync(this.values);

  final Map<String, Object> values;

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError('Unexpected preference call: $invocation');
  }
}
