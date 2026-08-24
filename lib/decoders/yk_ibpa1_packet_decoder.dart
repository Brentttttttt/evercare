import '../models/bp_monitor_packet.dart';
import '../models/bp_monitor_result.dart';
import '../services/bp_monitor_calibration.dart';

/// Provisional packet decoder for the YK-IBPA1 blood-pressure monitor.
///
/// Only the confirmed packet positions described by the current physical
/// monitor comparison are interpreted. All remaining bytes are retained as
/// raw metadata for future protocol validation.
class YkIbpa1PacketDecoder {
  const YkIbpa1PacketDecoder();

  static const int progressPacketType = 0x80;
  static const int completedResultPacketType = 0x81;
  static const String decoderVersion =
      'yk_ibpa1_provisional_v2_systolic_minus_10';
  static const String validationStatus =
      'local_systolic_offset_applied_not_medically_verified';

  /// Returns a completed result only for a packet beginning with `0x81` and
  /// containing the three confirmed result bytes.
  BpMonitorResult? decodeCompletedResult({
    required List<int> bytes,
    required DateTime receivedAt,
    required int packetIndex,
    required String deviceIdentifier,
    required String deviceName,
  }) {
    if (bytes.length < 4 || bytes.first != completedResultPacketType) {
      return null;
    }

    final rawBytes = List<int>.from(bytes);
    final rawSystolic = rawBytes[1];
    if (!BpMonitorCalibration.canApplyYkIbpa1SystolicCorrection(rawSystolic)) {
      return null;
    }
    return BpMonitorResult(
      rawSystolic: rawSystolic,
      systolic: BpMonitorCalibration.applyYkIbpa1SystolicCorrection(
        rawSystolic,
      ),
      diastolic: rawBytes[2],
      pulse: rawBytes[3],
      receivedAt: receivedAt,
      rawBytes: rawBytes,
      rawHex: BpMonitorPacket.formatHex(rawBytes),
      metadataBytes: rawBytes.sublist(4),
      packetIndex: packetIndex,
      decoderVersion: decoderVersion,
      validationStatus: validationStatus,
      deviceIdentifier: deviceIdentifier,
      deviceName: deviceName,
    );
  }

  /// Returns the live raw cuff pressure from a valid `0x80` progress packet.
  ///
  /// This value is measurement progress, not a completed systolic or
  /// diastolic reading.
  int? decodeProgressPressure(List<int> bytes) {
    if (bytes.length < 3 || bytes.first != progressPacketType) {
      return null;
    }
    return (bytes[1] << 8) | bytes[2];
  }
}
