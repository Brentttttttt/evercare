class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    required this.isPrimary,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] as String,
      name: (map['name'] as String?)?.trim() ?? '',
      relationship: (map['relationship'] as String?)?.trim() ?? '',
      phoneNumber: (map['phone_number'] as String?)?.trim() ?? '',
      isPrimary: map['is_primary'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isPrimary;

  String get initials {
    final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class EmergencyMedicalProfile {
  const EmergencyMedicalProfile({
    required this.fullName,
    required this.birthDate,
    required this.bloodType,
    required this.allergies,
    required this.conditions,
    required this.preferredHospital,
    required this.medicalNotes,
  });

  factory EmergencyMedicalProfile.fromMaps({
    required Map<String, dynamic>? profile,
    required Map<String, dynamic>? medicalProfile,
  }) {
    return EmergencyMedicalProfile(
      fullName: (profile?['full_name'] as String?)?.trim() ?? '',
      birthDate: _date(profile?['birth_date']),
      bloodType: (medicalProfile?['blood_type'] as String?)?.trim() ?? '',
      allergies: _strings(medicalProfile?['allergies']),
      conditions: _strings(medicalProfile?['conditions']),
      preferredHospital:
          (medicalProfile?['preferred_hospital'] as String?)?.trim() ?? '',
      medicalNotes: (medicalProfile?['medical_notes'] as String?)?.trim() ?? '',
    );
  }

  final String fullName;
  final DateTime? birthDate;
  final String bloodType;
  final List<String> allergies;
  final List<String> conditions;
  final String preferredHospital;
  final String medicalNotes;

  bool get hasMedicalDetails =>
      bloodType.isNotEmpty ||
      allergies.isNotEmpty ||
      conditions.isNotEmpty ||
      preferredHospital.isNotEmpty ||
      medicalNotes.isNotEmpty;
}

DateTime? _date(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

List<String> _strings(dynamic value) => switch (value) {
  List<dynamic> values => values.whereType<String>().toList(growable: false),
  _ => const <String>[],
};
