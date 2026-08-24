import 'dart:collection';

/// A completed blood-pressure reading provisionally decoded from YK-IBPA1.
///
/// The decoder remains provisional. Consumers must not treat this model as a
/// medically verified interpretation of the device protocol.
class BpMonitorResult {
  BpMonitorResult({
    required this.rawSystolic,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.receivedAt,
    required List<int> rawBytes,
    required this.rawHex,
    required List<int> metadataBytes,
    required this.packetIndex,
    required this.decoderVersion,
    required this.validationStatus,
    required this.deviceIdentifier,
    required this.deviceName,
  }) : rawBytes = UnmodifiableListView<int>(List<int>.from(rawBytes)),
       metadataBytes = UnmodifiableListView<int>(List<int>.from(metadataBytes));

  /// The systolic value read directly from the result packet.
  final int rawSystolic;

  /// The app-side calibrated systolic value used in caregiver-facing UI,
  /// saved BLE records, trends, and AI requests.
  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime receivedAt;
  final List<int> rawBytes;
  final String rawHex;
  final List<int> metadataBytes;
  final int packetIndex;
  final String decoderVersion;
  final String validationStatus;
  final String deviceIdentifier;
  final String deviceName;
}
