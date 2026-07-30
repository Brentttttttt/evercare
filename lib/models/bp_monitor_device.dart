class BpMonitorDevice {
  const BpMonitorDevice({
    required this.identifier,
    required this.name,
    required this.rssi,
  });

  final String identifier;
  final String name;
  final int rssi;

  BpMonitorDevice copyWith({String? name, int? rssi}) {
    return BpMonitorDevice(
      identifier: identifier,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
    );
  }
}
