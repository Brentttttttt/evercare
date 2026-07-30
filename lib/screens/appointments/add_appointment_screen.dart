import 'package:flutter/material.dart';

import '../../repositories/appointment_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_backend_scope.dart';
import 'appointment_form_fields.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AppointmentFormController _form;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _form = AppointmentFormController();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = EverCareBackendScope.maybeClient(context);
    final canSave = client?.auth.currentUser != null;
    return DetailPage(
      title: 'Add Appointment',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New appointment', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 6),
            const Text(
              'Enter the visit details you want to keep in your account.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 21),
            AppointmentFormFields(controller: _form),
            if (!canSave)
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text(
                  'Sign in before saving an appointment.',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canSave && !_saving ? _submit : null,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving…' : 'Save Appointment'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final client = EverCareBackendScope.maybeClient(context);
    if (client?.auth.currentUser == null) return;
    setState(() => _saving = true);
    try {
      await AppointmentRepository(client!).create(
        title: _form.title.text,
        doctorName: _form.doctorName.text,
        specialty: _form.specialty,
        startsAt: _form.startsAt,
        clinic: _form.clinic.text,
        address: _form.address.text,
        notes: _form.notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the appointment. Please try again.'),
        ),
      );
    }
  }
}
