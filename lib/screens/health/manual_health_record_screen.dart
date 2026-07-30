import 'package:flutter/material.dart';

import '../../repositories/blood_pressure_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/primary_button.dart';
import '../authentication/auth_widgets.dart';

class ManualHealthRecordScreen extends StatefulWidget {
  const ManualHealthRecordScreen({super.key});

  @override
  State<ManualHealthRecordScreen> createState() =>
      _ManualHealthRecordScreenState();
}

class _ManualHealthRecordScreenState extends State<ManualHealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _pulse = TextEditingController();
  final _notes = TextEditingController();
  DateTime _measuredAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _systolic.dispose();
    _diastolic.dispose();
    _pulse.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value, int maximum) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null) return 'Enter a whole number.';
    if (number <= 0 || number > maximum) return 'Check this value.';
    return null;
  }

  Future<void> _chooseDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (value == null || !mounted) return;
    setState(() {
      _measuredAt = DateTime(
        value.year,
        value.month,
        value.day,
        _measuredAt.hour,
        _measuredAt.minute,
      );
    });
  }

  Future<void> _chooseTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measuredAt),
    );
    if (value == null || !mounted) return;
    setState(() {
      _measuredAt = DateTime(
        _measuredAt.year,
        _measuredAt.month,
        _measuredAt.day,
        value.hour,
        value.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final client = EverCareBackendScope.maybeClient(context);
    if (client == null || client.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in before saving a reading.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await BloodPressureRepository(client).saveManual(
        systolic: int.parse(_systolic.text.trim()),
        diastolic: int.parse(_diastolic.text.trim()),
        pulse: int.parse(_pulse.text.trim()),
        measuredAt: _measuredAt,
        notes: _notes.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reading saved. It is not medically verified.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the reading: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return DetailPage(
      title: 'Manual Blood Pressure Entry',
      child: Form(
        key: _formKey,
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
                      'Enter a measurement you actually took. Saved entries are user-provided and are not medically verified.',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            AppTextField(
              controller: _systolic,
              label: 'Systolic pressure',
              hint: 'mmHg',
              icon: Icons.arrow_upward_rounded,
              keyboardType: TextInputType.number,
              validator: (value) => _validateNumber(value, 350),
            ),
            AppTextField(
              controller: _diastolic,
              label: 'Diastolic pressure',
              hint: 'mmHg',
              icon: Icons.arrow_downward_rounded,
              keyboardType: TextInputType.number,
              validator: (value) => _validateNumber(value, 250),
            ),
            AppTextField(
              controller: _pulse,
              label: 'Pulse during measurement',
              hint: 'BPM',
              icon: Icons.favorite_outline_rounded,
              keyboardType: TextInputType.number,
              validator: (value) => _validateNumber(value, 300),
            ),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primaryGreen,
                    ),
                    title: const Text('Measurement date'),
                    subtitle: Text(localizations.formatMediumDate(_measuredAt)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _chooseDate,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.primaryGreen,
                    ),
                    title: const Text('Measurement time'),
                    subtitle: Text(
                      localizations.formatTimeOfDay(
                        TimeOfDay.fromDateTime(_measuredAt),
                      ),
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: _chooseTime,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _notes,
              label: 'Notes',
              hint: 'Optional note',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 4),
            PrimaryButton(
              label: _saving ? 'Saving…' : 'Save Record',
              icon: Icons.check_rounded,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
