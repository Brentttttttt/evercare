import 'package:evercare/decoders/yk_ibpa1_packet_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decoder = YkIbpa1PacketDecoder();
  final receivedAt = DateTime.utc(2026, 7, 30, 10, 11, 12, 345);

  group('YK-IBPA1 completed result packets', () {
    const confirmedPacket = <int>[
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

    test('decodes the confirmed physical monitor comparison', () {
      final result = decoder.decodeCompletedResult(
        bytes: confirmedPacket,
        receivedAt: receivedAt,
        packetIndex: 42,
        deviceIdentifier: 'test-device-id',
        deviceName: 'YK-IBPA1',
      );

      expect(result, isNotNull);
      expect(result!.systolic, 70);
      expect(result.diastolic, 36);
      expect(result.pulse, 50);
      expect(result.receivedAt, receivedAt);
      expect(result.packetIndex, 42);
      expect(result.deviceIdentifier, 'test-device-id');
      expect(result.deviceName, 'YK-IBPA1');
      expect(result.decoderVersion, 'yk_ibpa1_provisional_v1');
      expect(
        result.validationStatus,
        'awaiting_additional_reference_measurements',
      );
      expect(result.rawBytes, confirmedPacket);
      expect(result.rawHex, '81 46 24 32 00 00 19 03 15 0A 11 00 00 00 00');
    });

    test('preserves all bytes after index 3 as raw metadata', () {
      final result = decoder.decodeCompletedResult(
        bytes: confirmedPacket,
        receivedAt: receivedAt,
        packetIndex: 1,
        deviceIdentifier: 'test-device-id',
        deviceName: 'YK-IBPA1',
      );

      expect(result!.metadataBytes, <int>[
        0x00,
        0x00,
        0x19,
        0x03,
        0x15,
        0x0A,
        0x11,
        0,
        0,
        0,
        0,
      ]);
    });
  });

  group('YK-IBPA1 progress packets', () {
    test('does not create a completed reading', () {
      final result = decoder.decodeCompletedResult(
        bytes: const <int>[0x80, 0x01, 0x2C],
        receivedAt: receivedAt,
        packetIndex: 1,
        deviceIdentifier: 'test-device-id',
        deviceName: 'YK-IBPA1',
      );

      expect(result, isNull);
    });

    test('calculates the big-endian raw cuff-pressure value', () {
      expect(
        decoder.decodeProgressPressure(const <int>[0x80, 0x01, 0x2C]),
        300,
      );
    });
  });

  group('invalid and unknown packets', () {
    test('rejects empty and short packets safely', () {
      expect(
        decoder.decodeCompletedResult(
          bytes: const <int>[],
          receivedAt: receivedAt,
          packetIndex: 1,
          deviceIdentifier: 'test-device-id',
          deviceName: 'YK-IBPA1',
        ),
        isNull,
      );
      expect(
        decoder.decodeCompletedResult(
          bytes: const <int>[0x81, 70, 36],
          receivedAt: receivedAt,
          packetIndex: 2,
          deviceIdentifier: 'test-device-id',
          deviceName: 'YK-IBPA1',
        ),
        isNull,
      );
      expect(decoder.decodeProgressPressure(const <int>[0x80, 0x01]), isNull);
    });

    test('unknown packet types do not create readings or progress', () {
      const unknown = <int>[0x82, 70, 36, 50];
      expect(
        decoder.decodeCompletedResult(
          bytes: unknown,
          receivedAt: receivedAt,
          packetIndex: 1,
          deviceIdentifier: 'test-device-id',
          deviceName: 'YK-IBPA1',
        ),
        isNull,
      );
      expect(decoder.decodeProgressPressure(unknown), isNull);
    });
  });
}
