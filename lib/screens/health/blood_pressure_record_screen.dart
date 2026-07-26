import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/mock_blood_pressure_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/blood_pressure_widgets.dart';

class BloodPressureRecordScreen extends StatelessWidget {
  const BloodPressureRecordScreen({required this.record, super.key});

  final MockBloodPressureRecord record;

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Record Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            color: AppColors.lightGreen,
            borderColor: AppColors.lightGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${record.dateLabel} · ${record.timeLabel}',
                        style: AppTextStyles.label,
                      ),
                    ),
                    BloodPressureStatusBadge(status: record.status),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${record.systolic} / ${record.diastolic}',
                          style: AppTextStyles.metric.copyWith(fontSize: 37),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 7, bottom: 3),
                      child: Text('mmHg', style: AppTextStyles.label),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 20,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Pulse ${record.pulse} BPM',
                      style: AppTextStyles.cardTitle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                LabeledValue(
                  label: 'Systolic pressure',
                  value: '${record.systolic} mmHg',
                  icon: Icons.arrow_upward_rounded,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Diastolic pressure',
                  value: '${record.diastolic} mmHg',
                  icon: Icons.arrow_downward_rounded,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Pulse during measurement',
                  value: '${record.pulse} BPM',
                  icon: Icons.favorite_outline_rounded,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Device',
                  value: record.deviceName,
                  icon: Icons.monitor_heart_outlined,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Connection',
                  value: record.source,
                  icon: Icons.bluetooth_connected_rounded,
                ),
                const Divider(),
                const LabeledValue(
                  label: 'Measurement source',
                  value: 'Connected device',
                  icon: Icons.link_rounded,
                ),
                const Divider(),
                LabeledValue(
                  label: 'User notes',
                  value: record.notes,
                  icon: Icons.notes_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppCard(
            color: Color(0xFFFFF8EB),
            borderColor: Color(0xFFF5DFAF),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.accessibility_new_rounded, color: AppColors.warning),
                SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Measurement position reminder',
                        style: AppTextStyles.cardTitle,
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Sit with your back supported, feet flat, and cuffed '
                        'arm resting at heart level.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => showMockDialog(
              context,
              title: 'Edit notes',
              message:
                  'A note editor would open here. The record is not changed '
                  'or stored in this UI prototype.',
              icon: Icons.edit_note_rounded,
            ),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Edit Notes'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            onPressed: () => showMockDialog(
              context,
              title: 'Delete record?',
              message:
                  'This is a static confirmation. The sample record will not '
                  'be deleted.',
              actionLabel: 'Close',
              icon: Icons.delete_outline_rounded,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete Record'),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Source: ${MockData.deviceName}',
              style: AppTextStyles.small,
            ),
          ),
        ],
      ),
    );
  }
}
