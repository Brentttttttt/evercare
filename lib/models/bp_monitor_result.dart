import 'dart:collection';

/// A completed blood-pressure reading provisionally decoded from YK-IBPA1.
///
/// The decoder remains provisional. Consumers must not treat this model as a
/// medically verified interpretation of the device protocol.
class BpMonitorResult {
  BpMonitorResult({
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
