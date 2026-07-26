import '../models/mock_emergency_contact.dart';

abstract final class EmergencyMockData {
  static const contacts = [
    MockEmergencyContact(
      name: 'Anna Santos',
      relationship: 'Daughter · Primary caregiver',
      phone: '09XX XXX XXXX',
      availability: 'Available anytime',
      initials: 'AS',
      primary: true,
    ),
    MockEmergencyContact(
      name: 'Roberto Santos',
      relationship: 'Son · Secondary caregiver',
      phone: '09XX XXX XXXX',
      availability: 'Usually available',
      initials: 'RS',
    ),
    MockEmergencyContact(
      name: 'Dr. Elena Cruz',
      relationship: 'Primary physician',
      phone: '02 XXXX XXXX',
      availability: 'Clinic hours',
      initials: 'EC',
    ),
    MockEmergencyContact(
      name: 'Nearby Health Center',
      relationship: 'Local healthcare facility',
      phone: '044 XXX XXXX',
      availability: 'Open daily',
      initials: 'HC',
    ),
  ];

  static const medicalInformation = [
    ('Patient name', 'Maria Santos'),
    ('Date of birth', 'March 12, 1952'),
    ('Blood type', 'O+'),
    ('Known allergy', 'Penicillin'),
    ('Existing condition', 'Hypertension'),
    ('Primary medicine', 'Amlodipine'),
    ('Primary caregiver', 'Anna Santos'),
    ('Preferred hospital', 'EverCare Medical Center'),
  ];

  static const waitingChecklist = [
    'Stay calm and remain with the older adult',
    'Keep the area safe and clear',
    'Prepare the medicine list and medical ID',
    'Note when the symptoms or incident began',
    'Follow instructions provided by emergency personnel',
    'Do not give unprescribed medicine',
  ];
}
