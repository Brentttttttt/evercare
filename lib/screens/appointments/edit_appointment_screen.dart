import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../repositories/appointment_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_backend_scope.dart';
import 'appointment_form_fields.dart';

class EditAppointmentScreen extends StatefulWidget {
  const EditAppointmentScreen({required this.appointment, super.key});

  final Object appointment;

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  AppointmentFormController? _form;
  bool _saving = false;

  Appointment? get _appointment => widget.appointment is Appointment
      ? widget.appointment as Appointment
      : null;

  @override
  void initState() {
    super.initState();
    final appointment = _appointment;
    if (appointment != null) _form = AppointmentFormController(appointment);
  }

  @override
  void dispose() {
    _form?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointment = _appointment;
    final form = _form;
    if (appointment == null || form == null) {
      return const DetailPage(
        title: 'Edit Appointment',
        child: AppCard(
          child: Text(
            'This appointment is not a saved account record. Return to Appointments and choose an available visit.',
            style: AppTextStyles.bodyMuted,
          ),
        ),
      );
    }
    final client = EverCareBackendScope.maybeClient(context);
    final canSave = client?.auth.currentUser != null;
    return DetailPage(
      title: 'Edit Appointment',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update visit details', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 6),
            const Text(
              'Changes are saved securely to your account.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 21),
            AppointmentFormFields(controller: form),
            if (!canSave)
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text(
                  'Sign in again before saving changes.',
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
                label: Text(_saving ? 'Saving…' : 'Save Changes'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Discard Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final appointment = _appointment;
    final form = _form;
    final client = EverCareBackendScope.maybeClient(context);
    if (appointment == null ||
        form == null ||
        client?.auth.currentUser == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await AppointmentRepository(client!).update(
        appointment.id,
        title: form.title.text,
        doctorName: form.doctorName.text,
        specialty: form.specialty,
        startsAt: form.startsAt,
        clinic: form.clinic.text,
        address: form.address.text,
        notes: form.notes.text,
        status: appointment.status,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the appointment. Please try again.'),
        ),
      );
    }
  }
}
