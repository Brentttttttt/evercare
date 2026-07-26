import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import 'appointment_form_fields.dart';

class AddAppointmentScreen extends StatelessWidget {
  const AddAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Add Appointment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New appointment', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          const Text(
            'Enter the visit details below. This form is a visual prototype and does not save information.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 21),
          const AppointmentFormFields(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _finish(context),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Appointment'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 19,
                color: AppColors.secondaryText,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No calendar, notification, account, or external service is connected.',
                  style: AppTextStyles.small,
                ),
              ),
            ],
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
          'Appointment preview added. UI prototype only — no information was saved.',
        ),
      ),
    );
  }
}
