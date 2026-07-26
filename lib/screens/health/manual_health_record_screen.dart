import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/primary_button.dart';
import '../authentication/auth_widgets.dart';

class ManualHealthRecordScreen extends StatefulWidget {
  const ManualHealthRecordScreen({super.key});

  @override
  State<ManualHealthRecordScreen> createState() =>
      _ManualHealthRecordScreenState();
}

class _ManualHealthRecordScreenState extends State<ManualHealthRecordScreen> {
  String _source = 'Manual Entry';

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Manual Blood Pressure Entry',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCard(
            color: AppColors.lightGreen,
            borderColor: AppColors.lightGreen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.edit_note_rounded, color: AppColors.primaryGreen),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Use this mock form as a fallback when the monitor is '
                    'unavailable. No value is stored.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const MockTextField(
            label: 'Systolic pressure',
            hint: '120',
            icon: Icons.arrow_upward_rounded,
            keyboardType: TextInputType.number,
          ),
          const MockTextField(
            label: 'Diastolic pressure',
            hint: '80',
            icon: Icons.arrow_downward_rounded,
            keyboardType: TextInputType.number,
          ),
          const MockTextField(
            label: 'Pulse during measurement',
            hint: '72 BPM',
            icon: Icons.favorite_outline_rounded,
            keyboardType: TextInputType.number,
          ),
          const MockTextField(
            label: 'Date',
            hint: 'July 20, 2026',
            icon: Icons.calendar_today_outlined,
          ),
          const MockTextField(
            label: 'Time',
            hint: '8:45 AM',
            icon: Icons.schedule_rounded,
          ),
          const Text('Reading source', style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [MockData.deviceName, 'Manual Entry', 'Caregiver Entry']
                .map(
                  (source) => ChoiceChip(
                    label: Text(source),
                    selected: _source == source,
                    selectedColor: AppColors.lightGreen,
                    onSelected: (_) => setState(() => _source = source),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          const MockTextField(
            label: 'Notes',
            hint: 'Optional note',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 4),
          PrimaryButton(
            label: 'Save Record Preview',
            icon: Icons.check_rounded,
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Mock blood-pressure record accepted as $_source. '
                    'Nothing was stored.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
