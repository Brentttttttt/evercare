import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../repositories/appointment_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/evercare_backend_scope.dart';
import 'edit_appointment_screen.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({required this.appointment, super.key});

  final Object appointment;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  Appointment? _appointment;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.appointment;
    if (raw is Appointment) _appointment = raw;
  }

  @override
  Widget build(BuildContext context) {
    final appointment = _appointment;
    if (appointment == null) {
      return const DetailPage(
        title: 'Appointment Details',
        child: AppCard(
          child: Text(
            'This appointment is not a saved account record. Return to Appointments to choose an available visit.',
            style: AppTextStyles.bodyMuted,
          ),
        ),
      );
    }

    final statusColors = appointmentStatusColors(appointment.status);
    final isUpcoming = appointment.status == AppointmentStatus.upcoming;
    final isCompleted = appointment.status == AppointmentStatus.completed;

    return DetailPage(
      title: 'Appointment Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            color: statusColors.background,
            borderColor: statusColors.background,
            child: Column(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.event_available_rounded
                        : appointment.status == AppointmentStatus.cancelled
                        ? Icons.event_busy_rounded
                        : Icons.calendar_month_rounded,
                    size: 34,
                    color: statusColors.foreground,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  appointment.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle.copyWith(fontSize: 23),
                ),
                const SizedBox(height: 7),
                Text(
                  appointment.doctorName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (appointment.specialty.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    appointment.specialty,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    appointment.statusLabel,
                    style: AppTextStyles.small.copyWith(
                      color: statusColors.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 19),
          Text('Visit information', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 11),
          AppCard(
            child: Column(
              children: [
                LabeledValue(
                  label: 'Date',
                  value: appointment.dateLabel,
                  icon: Icons.event_outlined,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Time',
                  value: appointment.timeLabel,
                  icon: Icons.schedule_rounded,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Clinic or hospital',
                  value: appointment.clinic,
                  icon: Icons.local_hospital_outlined,
                ),
                if (appointment.address.isNotEmpty) ...[
                  const Divider(),
                  LabeledValue(
                    label: 'Address',
                    value: appointment.address,
                    icon: Icons.location_on_outlined,
                  ),
                ],
                if (appointment.notes.isNotEmpty) ...[
                  const Divider(),
                  LabeledValue(
                    label: 'Notes',
                    value: appointment.notes,
                    icon: Icons.notes_rounded,
                  ),
                ],
              ],
            ),
          ),
          if (appointment.status == AppointmentStatus.cancelled) ...[
            const SizedBox(height: 19),
            const AppCard(
              color: Color(0xFFFFF5F3),
              borderColor: Color(0xFFF6D5D1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.danger),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This appointment has been cancelled.',
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isUpcoming) ...[
            const SizedBox(height: 21),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _updating ? null : () => _edit(appointment),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Appointment'),
              ),
            ),
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _updating ? null : () => _reschedule(appointment),
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Reschedule'),
              ),
            ),
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                onPressed: _updating ? null : () => _cancel(appointment),
                icon: _updating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.event_busy_outlined),
                label: Text(_updating ? 'Updating…' : 'Cancel Appointment'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(Appointment appointment) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditAppointmentScreen(appointment: appointment),
      ),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _reschedule(Appointment appointment) async {
    final date = await showDatePicker(
      context: context,
      initialDate: appointment.startsAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appointment.startsAt),
    );
    if (time == null || !mounted) return;
    final newStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.edit_calendar_outlined,
          color: AppColors.primaryGreen,
        ),
        title: const Text('Save new schedule?'),
        content: Text('Move this appointment to ${_dateTimeLabel(newStart)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Current Time'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save Schedule'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _performUpdate(
      () => AppointmentRepository(EverCareBackendScope.read(context)).update(
        appointment.id,
        title: appointment.title,
        doctorName: appointment.doctorName,
        specialty: appointment.specialty,
        startsAt: newStart,
        clinic: appointment.clinic,
        address: appointment.address,
        notes: appointment.notes,
        status: appointment.status,
      ),
      updated: appointment.copyWith(startsAt: newStart),
      successMessage: 'Appointment rescheduled.',
    );
  }

  Future<void> _cancel(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.event_busy_outlined,
          color: AppColors.danger,
          size: 34,
        ),
        title: const Text('Cancel appointment?'),
        content: Text(
          'Cancel ${appointment.title} with ${appointment.doctorName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Appointment'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final client = EverCareBackendScope.maybeClient(context);
    if (client?.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again before updating.')),
      );
      return;
    }
    await _performUpdate(
      () => AppointmentRepository(
        client!,
      ).setStatus(appointment.id, AppointmentStatus.cancelled),
      updated: appointment.copyWith(status: AppointmentStatus.cancelled),
      successMessage: 'Appointment cancelled.',
    );
  }

  Future<void> _performUpdate(
    Future<void> Function() action, {
    required Appointment updated,
    required String successMessage,
  }) async {
    final client = EverCareBackendScope.maybeClient(context);
    if (client?.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again before updating.')),
      );
      return;
    }
    setState(() => _updating = true);
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _appointment = updated;
        _updating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update the appointment. Please try again.'),
        ),
      );
    }
  }
}

String _dateTimeLabel(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.month}/${value.day}/${value.year} at '
      '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
}
