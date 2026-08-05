class HospitalLocation {
  const HospitalLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? distanceMeters;

  String get distanceLabel {
    final distance = distanceMeters;
    if (distance == null) return 'Distance unavailable';
    if (distance < 1000) return '${distance.round()} m away';
    return '${(distance / 1000).toStringAsFixed(1)} km away';
  }
}
