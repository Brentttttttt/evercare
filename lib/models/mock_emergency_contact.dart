class MockEmergencyContact {
  const MockEmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    required this.availability,
    required this.initials,
    this.primary = false,
  });

  final String name;
  final String relationship;
  final String phone;
  final String availability;
  final String initials;
  final bool primary;
}
