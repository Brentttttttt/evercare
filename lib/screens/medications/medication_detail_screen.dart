import 'package:flutter/material.dart';

import '../../models/mock_medication.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/section_header.dart';

class MedicationDetailScreen extends StatelessWidget {
  const MedicationDetailScreen({required this.medication, super.key});

  final MockMedication medication;

  Future<void> _confirmDelete(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        title: const Text('Delete medication?'),
        content: Text(
          '${medication.name} will remain visible because this is a UI-only prototype.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Medication Details',
      actions: [
        IconButton(
          tooltip: 'Edit medication',
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.addMedication,
            arguments: true,
          ),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            color: AppColors.lightGreen,
            borderColor: AppColors.lightGreen,
            child: Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: AppColors.primaryGreen,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medication.name, style: AppTextStyles.pageTitle),
                      const SizedBox(height: 5),
                      Text(medication.dosage, style: AppTextStyles.body),
                      const SizedBox(height: 4),
                      Text(medication.purpose, style: AppTextStyles.bodyMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                LabeledValue(
                  label: 'Schedule',
                  value: 'Every day at ${medication.time}',
                  icon: Icons.schedule_rounded,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Start date',
                  value: medication.startDate,
                  icon: Icons.event_outlined,
                ),
                const Divider(),
                LabeledValue(
                  label: 'End date',
                  value: medication.endDate,
                  icon: Icons.event_available_outlined,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Instructions',
                  value: medication.instructions,
                  icon: Icons.description_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Adherence'),
          const SizedBox(height: 10),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '96%',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Taken as planned this month',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 13),
                LinearProgressIndicator(
                  value: .96,
                  minHeight: 9,
                  borderRadius: BorderRadius.all(Radius.circular(9)),
                  color: AppColors.primaryGreen,
                  backgroundColor: AppColors.lightGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Recent Intake'),
          const SizedBox(height: 10),
          const AppCard(
            child: Column(
              children: [
                _IntakeRow(date: 'July 18', status: 'Taken', time: '8:03 AM'),
                Divider(),
                _IntakeRow(date: 'July 17', status: 'Taken', time: '8:08 AM'),
                Divider(),
                _IntakeRow(date: 'July 16', status: 'Taken', time: '8:01 AM'),
                Divider(),
                _IntakeRow(date: 'July 15', status: 'Missed', time: '—'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.addMedication,
              arguments: true,
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Medication'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete Medication'),
          ),
        ],
      ),
    );
  }
}

class _IntakeRow extends StatelessWidget {
  const _IntakeRow({
    required this.date,
    required this.status,
    required this.time,
  });

  final String date;
  final String status;
  final String time;

  @override
  Widget build(BuildContext context) {
    final taken = status == 'Taken';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            taken ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: taken ? AppColors.primaryGreen : AppColors.danger,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(date, style: AppTextStyles.body)),
          Text(time, style: AppTextStyles.bodyMuted),
          const SizedBox(width: 12),
          Text(
            status,
            style: TextStyle(
              color: taken ? AppColors.darkGreen : AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
