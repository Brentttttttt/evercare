class CaregiverRelationship {
  const CaregiverRelationship({
    required this.id,
    required this.caregiverId,
    required this.name,
    required this.phoneNumber,
    required this.relationshipLabel,
    required this.status,
  });

  factory CaregiverRelationship.fromMap(Map<String, dynamic> map) {
    final joined = map['caregiver'];
    final caregiver = joined is Map<String, dynamic>
        ? joined
        : joined is List && joined.isNotEmpty && joined.first is Map
        ? Map<String, dynamic>.from(joined.first as Map)
        : const <String, dynamic>{};
    return CaregiverRelationship(
      id: map['id'] as String,
      caregiverId: (map['caregiver_id'] as String?) ?? '',
      name: (caregiver['full_name'] as String?)?.trim() ?? '',
      phoneNumber: (caregiver['phone_number'] as String?)?.trim() ?? '',
      relationshipLabel:
          (map['relationship_label'] as String?)?.trim() ?? 'Caregiver',
      status: (map['status'] as String?)?.trim() ?? 'pending',
    );
  }

  final String id;
  final String caregiverId;
  final String name;
  final String phoneNumber;
  final String relationshipLabel;
  final String status;

  Map<String, String> toRouteArguments() => {
    'id': id,
    'caregiverId': caregiverId,
    'name': name,
    'phone': phoneNumber,
    'relationship': relationshipLabel,
    'status': status,
  };
}
