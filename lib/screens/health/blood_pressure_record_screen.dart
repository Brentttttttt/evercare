import 'package:flutter/material.dart';

import '../../models/blood_pressure_reading.dart';
import '../../repositories/blood_pressure_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/blood_pressure_widgets.dart';
import '../../widgets/evercare_backend_scope.dart';

class BloodPressureRecordScreen extends StatefulWidget {
  const BloodPressureRecordScreen({required this.record, super.key});

  final BloodPressureReading record;

  @override
  State<BloodPressureRecordScreen> createState() =>
      _BloodPressureRecordScreenState();
}

class _BloodPressureRecordScreenState extends State<BloodPressureRecordScreen> {
  late String? _notes = widget.record.notes;
  bool _working = false;

  BloodPressureRepository? get _repository {
    final client = EverCareBackendScope.maybeClient(context);
    if (client == null || client.auth.currentUser == null) return null;
    return BloodPressureRepository(client);
  }

  Future<void> _editNotes() async {
    final repository = _repository;
    if (repository == null) return;
    final controller = TextEditingController(text: _notes);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit notes'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Optional note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    setState(() => _working = true);
    try {
      await repository.updateNotes(widget.record.id, value);
      if (!mounted) return;
      setState(() => _notes = value.trim().isEmpty ? null : value.trim());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notes updated securely.')));
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _delete() async {
    final repository = _repository;
    if (repository == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this reading?'),
        content: const Text(
          'This permanently removes the saved reading from your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
    try {
      await repository.delete(widget.record.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _working = false);
        _showError(error);
      }
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not update the reading: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final canEdit = _repository != null && !_working;
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
                    BloodPressureStatusBadge(status: record.statusLabel),
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
                  value: record.monitorName ?? 'Not provided',
                  icon: Icons.monitor_heart_outlined,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Measurement source',
                  value: record.sourceLabel,
                  icon: record.source == 'ble'
                      ? Icons.bluetooth_connected_rounded
                      : Icons.edit_note_rounded,
                ),
                const Divider(),
                LabeledValue(
                  label: 'User notes',
                  value: _notes ?? 'No notes',
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
                Icon(Icons.info_outline_rounded, color: AppColors.warning),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'This record was saved by the user and has not been medically verified. Contact a qualified professional for interpretation.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: canEdit ? _editNotes : null,
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(_working ? 'Saving…' : 'Edit Notes'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            onPressed: canEdit ? _delete : null,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete Record'),
          ),
        ],
      ),
    );
  }
}
