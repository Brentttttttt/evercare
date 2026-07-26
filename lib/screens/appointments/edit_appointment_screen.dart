import 'package:flutter/material.dart';

import '../../models/mock_appointment.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import 'appointment_form_fields.dart';

class EditAppointmentScreen extends StatelessWidget {
  const EditAppointmentScreen({required this.appointment, super.key});

  final MockAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Edit Appointment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Update visit details', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          const Text(
            'Review the prefilled appointment information. Changes remain on this screen only.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 21),
          AppointmentFormFields(appointment: appointment),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _finish(context),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Discard Changes'),
            ),
          ),
        ],
      ),
    );
  }

  void _finish(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Appointment changes previewed. No information was saved.',
        ),
      ),
    );
  }
}
