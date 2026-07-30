import 'package:flutter/material.dart';

import '../models/mock_appointment.dart';
import '../models/mock_blood_pressure_record.dart';
import '../models/mock_medication.dart';

abstract final class MockData {
  static const deviceName = 'Yongrow/Yonker YK-BPA1';
  static const deviceModel = 'YK-BPA1';
  static const deviceType = 'Bluetooth Upper-Arm Blood Pressure Monitor';
  static const syncMethod = 'Bluetooth Low Energy';

  static const profile = {
    'name': 'Maria Santos',
    'age': '68',
    'email': 'maria.santos@example.com',
    'phone': '+63 912 345 6789',
    'bloodType': 'O+',
    'userType': 'Senior Citizen',
    'birthDate': 'March 14, 1958',
    'address': 'Guiguinto, Bulacan, Philippines',
  };

  static final bloodPressureRecords = [
    MockBloodPressureRecord(
      systolic: 120,
      diastolic: 80,
      pulse: 72,
      measuredAt: DateTime(2026, 7, 20, 8, 45),
      status: 'Normal',
      source: syncMethod,
      deviceName: deviceName,
      notes: 'Morning reading before breakfast.',
    ),
    MockBloodPressureRecord(
      systolic: 118,
      diastolic: 78,
      pulse: 70,
      measuredAt: DateTime(2026, 7, 19, 8, 38),
      status: 'Normal',
      source: syncMethod,
      deviceName: deviceName,
      notes: 'Seated and rested before measurement.',
    ),
    MockBloodPressureRecord(
      systolic: 124,
      diastolic: 82,
      pulse: 74,
      measuredAt: DateTime(2026, 7, 18, 8, 42),
      status: 'Slightly Elevated',
      source: syncMethod,
      deviceName: deviceName,
      notes: 'Measurement completed after morning medicine.',
    ),
    MockBloodPressureRecord(
      systolic: 121,
      diastolic: 79,
      pulse: 71,
      measuredAt: DateTime(2026, 7, 17, 8, 41),
      status: 'Normal',
      source: syncMethod,
      deviceName: deviceName,
      notes: 'No additional notes.',
    ),
    MockBloodPressureRecord(
      systolic: 126,
      diastolic: 84,
      pulse: 75,
      measuredAt: DateTime(2026, 7, 16, 8, 50),
      status: 'Elevated',
      source: syncMethod,
      deviceName: deviceName,
      notes: 'Repeated after resting for five minutes.',
    ),
  ];

  static MockBloodPressureRecord get latestBloodPressure =>
      bloodPressureRecords.first;

  static const medications = [
    MockMedication(
      name: 'Amlodipine',
      dosage: '5 mg · One tablet',
      purpose: 'For high blood pressure',
      time: '8:00 AM',
      status: 'Taken',
      instructions: 'Take one tablet each morning after breakfast.',
      startDate: 'January 10, 2026',
      endDate: 'Ongoing',
    ),
    MockMedication(
      name: 'Metformin',
      dosage: '500 mg · One tablet',
      purpose: 'For diabetes',
      time: '12:30 PM',
      status: 'Upcoming',
      instructions: 'Take with lunch as directed.',
      startDate: 'March 2, 2026',
      endDate: 'Ongoing',
    ),
    MockMedication(
      name: 'Atorvastatin',
      dosage: '10 mg · One tablet',
      purpose: 'For cholesterol',
      time: '8:00 PM',
      status: 'Upcoming',
      instructions: 'Take one tablet in the evening after dinner.',
      startDate: 'February 18, 2026',
      endDate: 'Ongoing',
    ),
  ];

  static final appointments = [
    MockAppointment(
      id: 'appointment-general-august',
      title: 'General Check-up',
      doctorName: 'Dr. Maria Reyes',
      specialty: 'General Physician',
      dateTime: DateTime(2026, 8, 4, 9, 30),
      clinic: 'Guiguinto Community Hospital',
      address: 'Guiguinto, Bulacan',
      notes:
          'Bring the latest blood-pressure records and current medication list.',
      status: MockAppointmentStatus.upcoming,
    ),
    MockAppointment(
      id: 'appointment-dental-august',
      title: 'Dental Check-up',
      doctorName: 'Dr. Juan Dela Cruz',
      specialty: 'Dentist',
      dateTime: DateTime(2026, 8, 18, 14),
      clinic: 'Bright Smile Dental Clinic',
      address: 'Malolos, Bulacan',
      notes: 'Bring the previous dental X-ray and medication list.',
      status: MockAppointmentStatus.upcoming,
    ),
    MockAppointment(
      id: 'appointment-bp-july',
      title: 'Blood Pressure Consultation',
      doctorName: 'Dr. Antonio Santos',
      specialty: 'Internal Medicine',
      dateTime: DateTime(2026, 7, 12, 10),
      clinic: 'Bulacan Medical Center',
      address: 'Malolos, Bulacan',
      notes:
          'Blood-pressure monitoring should continue regularly. Bring the recorded readings to the next consultation.',
      status: MockAppointmentStatus.completed,
    ),
    MockAppointment(
      id: 'appointment-routine-june',
      title: 'Routine Medical Examination',
      doctorName: 'Dr. Elena Garcia',
      specialty: 'General Physician',
      dateTime: DateTime(2026, 6, 20, 8, 30),
      clinic: 'Guiguinto Community Hospital',
      address: 'Guiguinto, Bulacan',
      notes: 'Routine visit completed. Follow the printed clinic instructions.',
      status: MockAppointmentStatus.completed,
    ),
    MockAppointment(
      id: 'appointment-diabetes-may',
      title: 'Diabetes Follow-up',
      doctorName: 'Dr. Liza Mendoza',
      specialty: 'Endocrinologist',
      dateTime: DateTime(2026, 5, 14, 10, 15),
      clinic: 'St. Anne Medical Clinic',
      address: 'Plaridel, Bulacan',
      notes:
          'Blood-sugar results were reviewed. Continue the current care plan until the next visit.',
      status: MockAppointmentStatus.completed,
    ),
    MockAppointment(
      id: 'appointment-laboratory-april',
      title: 'Laboratory Results Review',
      doctorName: 'Dr. Maria Reyes',
      specialty: 'General Physician',
      dateTime: DateTime(2026, 4, 28, 15),
      clinic: 'Guiguinto Community Hospital',
      address: 'Guiguinto, Bulacan',
      notes:
          'Routine laboratory results were discussed. A printed summary was provided by the clinic.',
      status: MockAppointmentStatus.completed,
    ),
    MockAppointment(
      id: 'appointment-eye-june',
      title: 'Eye Examination',
      doctorName: 'Dr. Roberto Cruz',
      specialty: 'Ophthalmologist',
      dateTime: DateTime(2026, 6, 5, 13, 30),
      clinic: 'Vision Care Clinic',
      address: 'Malolos, Bulacan',
      notes: 'Cancelled appointment preview.',
      status: MockAppointmentStatus.cancelled,
    ),
  ];

  static List<MockAppointment> get upcomingAppointments => appointments
      .where(
        (appointment) => appointment.status == MockAppointmentStatus.upcoming,
      )
      .toList(growable: false);

  static List<MockAppointment> get completedAppointments => appointments
      .where(
        (appointment) => appointment.status == MockAppointmentStatus.completed,
      )
      .toList(growable: false);

  static List<MockAppointment> get cancelledAppointments => appointments
      .where(
        (appointment) => appointment.status == MockAppointmentStatus.cancelled,
      )
      .toList(growable: false);

  static const caregivers = [
    {
      'name': 'Ana Santos',
      'relationship': 'Daughter',
      'phone': '+63 917 555 0182',
      'email': 'ana.santos@example.com',
    },
    {
      'name': 'Miguel Santos',
      'relationship': 'Son',
      'phone': '+63 918 555 0137',
      'email': 'miguel.santos@example.com',
    },
    {
      'name': 'Elena Cruz',
      'relationship': 'Caregiver',
      'phone': '+63 919 555 0145',
      'email': 'elena.cruz@example.com',
    },
  ];

  static const notifications = [
    {
      'group': 'Today',
      'title': 'Time to take Metformin',
      'subtitle': 'One tablet · 12:30 PM',
      'icon': Icons.medication_outlined,
    },
    {
      'group': 'Today',
      'title': 'Dental appointment tomorrow',
      'subtitle': 'Bright Smile Dental Clinic · 2:00 PM',
      'icon': Icons.calendar_month_outlined,
    },
  ];
}
