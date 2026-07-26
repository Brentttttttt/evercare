import 'package:flutter/material.dart';

import '../../widgets/app_page.dart';
import '../../widgets/primary_button.dart';
import '../authentication/auth_widgets.dart';

class AddMedicationScreen extends StatelessWidget {
  const AddMedicationScreen({super.key, this.isEditing = false});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: isEditing ? 'Edit Medication' : 'Add Medication',
      child: Column(
        children: [
          const MockTextField(
            label: 'Medicine name',
            hint: 'e.g. Amlodipine',
            icon: Icons.medication_outlined,
          ),
          const MockTextField(
            label: 'Dosage',
            hint: 'e.g. 5 mg · One tablet',
            icon: Icons.scale_outlined,
          ),
          const MockTextField(
            label: 'Purpose',
            hint: 'What is it for?',
            icon: Icons.health_and_safety_outlined,
          ),
          const MockTextField(
            label: 'Frequency',
            hint: 'Once daily',
            icon: Icons.repeat_rounded,
          ),
          const MockTextField(
            label: 'Start date',
            hint: 'July 20, 2026',
            icon: Icons.event_outlined,
          ),
          const MockTextField(
            label: 'End date',
            hint: 'Ongoing',
            icon: Icons.event_available_outlined,
          ),
          const MockTextField(
            label: 'Instructions',
            hint: 'Take after a meal',
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
          const MockTextField(
            label: 'Reminder times',
            hint: '8:00 AM',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 4),
          PrimaryButton(
            label: isEditing ? 'Save Changes' : 'Save Medication',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
