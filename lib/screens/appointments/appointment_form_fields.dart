import 'package:flutter/material.dart';

import '../../models/mock_appointment.dart';
import '../../theme/app_colors.dart';
import '../authentication/auth_widgets.dart';

class AppointmentFormFields extends StatefulWidget {
  const AppointmentFormFields({super.key, this.appointment});

  final MockAppointment? appointment;

  @override
  State<AppointmentFormFields> createState() => _AppointmentFormFieldsState();
}

class _AppointmentFormFieldsState extends State<AppointmentFormFields> {
  static const _specialties = [
    'General Physician',
    'Internal Medicine',
    'Dentist',
    'Endocrinologist',
    'Ophthalmologist',
    'Cardiologist',
  ];

  late String _specialty = widget.appointment?.specialty ?? _specialties.first;

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    return Column(
      children: [
        MockTextField(
          label: 'Appointment title',
          hint: 'e.g. General Check-up',
          icon: Icons.event_note_outlined,
          initialValue: appointment?.title,
        ),
        MockTextField(
          label: 'Doctor name',
          hint: 'e.g. Dr. Maria Reyes',
          icon: Icons.person_outline_rounded,
          initialValue: appointment?.doctorName,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
            initialValue: _specialty,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Specialty',
              prefixIcon: Icon(
                Icons.medical_services_outlined,
                color: AppColors.primaryGreen,
              ),
            ),
            items: _specialties
                .map(
                  (specialty) => DropdownMenuItem(
                    value: specialty,
                    child: Text(specialty, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) setState(() => _specialty = value);
            },
          ),
        ),
        MockTextField(
          label: 'Clinic or hospital',
          hint: 'Enter the clinic name',
          icon: Icons.local_hospital_outlined,
          initialValue: appointment?.clinic,
        ),
        MockTextField(
          label: 'Date',
          hint: 'August 4, 2026',
          icon: Icons.calendar_today_outlined,
          initialValue: appointment?.dateLabel,
          readOnly: true,
          onTap: () => _showPickerPreview(context, 'Date picker'),
        ),
        MockTextField(
          label: 'Time',
          hint: '9:30 AM',
          icon: Icons.schedule_rounded,
          initialValue: appointment?.timeLabel,
          readOnly: true,
          onTap: () => _showPickerPreview(context, 'Time picker'),
        ),
        MockTextField(
          label: 'Address',
          hint: 'Clinic address',
          icon: Icons.location_on_outlined,
          initialValue: appointment?.address,
        ),
        MockTextField(
          label: 'Notes',
          hint: 'Optional reminders for this visit',
          icon: Icons.notes_rounded,
          initialValue: appointment?.notes,
          maxLines: 4,
        ),
      ],
    );
  }

  void _showPickerPreview(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.touch_app_outlined,
          color: AppColors.primaryGreen,
        ),
        title: Text(title),
        content: const Text(
          'A date or time picker would open here in the complete application. This UI prototype does not change any information.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
