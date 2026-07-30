import 'package:flutter/material.dart';

import '../../models/medication.dart';
import '../../repositories/medication_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_backend_scope.dart';
import 'add_medication_screen.dart';

class MedicationDetailScreen extends StatefulWidget {
  const MedicationDetailScreen({required this.medication, super.key});

  final Object medication;

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final raw = widget.medication;
    if (raw is! Medication) {
      return const DetailPage(
        title: 'Medication Details',
        child: AppCard(
          child: Text(
            'This medication is not a saved account record. Return to Medications to choose an available item.',
            style: AppTextStyles.bodyMuted,
          ),
        ),
      );
    }
    final medication = raw;
    return DetailPage(
      title: 'Medication Details',
      actions: [
        IconButton(
          tooltip: 'Edit medication',
          onPressed: () => _edit(medication),
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
                      if (medication.purpose.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          medication.purpose,
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
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
                  label: 'Status',
                  value: medication.statusLabel,
                  icon: medication.isActive
                      ? Icons.check_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Frequency',
                  value: medication.frequency.isEmpty
                      ? 'Not provided'
                      : medication.frequency,
                  icon: Icons.repeat_rounded,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Reminder time',
                  value: medication.scheduleLabel,
                  icon: Icons.schedule_rounded,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Start date',
                  value: medication.startDateLabel,
                  icon: Icons.event_outlined,
                ),
                const Divider(),
                LabeledValue(
                  label: 'End date',
                  value: medication.endDateLabel,
                  icon: Icons.event_available_outlined,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Instructions',
                  value: medication.instructions.isEmpty
                      ? 'No instructions saved'
                      : medication.instructions,
                  icon: Icons.description_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _edit(medication),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Medication'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              onPressed: _deleting ? null : () => _confirmDelete(medication),
              icon: _deleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: Text(_deleting ? 'Deleting…' : 'Delete Medication'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(Medication medication) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(medication: medication),
      ),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _confirmDelete(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        title: const Text('Delete medication?'),
        content: Text(
          '${medication.name} will be permanently removed from your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Medication'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final client = EverCareBackendScope.maybeClient(context);
    if (client?.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again before deleting.')),
      );
      return;
    }
    setState(() => _deleting = true);
    try {
      await MedicationRepository(client!).delete(medication.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete the medication. Please try again.'),
        ),
      );
    }
  }
}
