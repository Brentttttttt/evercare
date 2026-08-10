import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/appointment.dart';
import '../../repositories/appointment_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_backend_scope.dart';
import 'edit_appointment_screen.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({required this.appointment, super.key});

  final Object appointment;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen>
    with WidgetsBindingObserver {
  Appointment? _appointment;
  bool _updating = false;
  DateTime _now = DateTime.now().toUtc();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final raw = widget.appointment;
    if (raw is Appointment) _appointment = raw;
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now().toUtc());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => _now = DateTime.now().toUtc());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
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

    final visitState = appointment.visitStateAt(_now);
    final statusColors = _visitStateColors(visitState);
    final isUpcoming = visitState == AppointmentVisitState.upcoming;
    final canMarkDone =
        visitState == AppointmentVisitState.due ||
        visitState == AppointmentVisitState.missed;
    final hasHospitalLocation =
        appointment.clinic.trim().isNotEmpty ||
        appointment.address.trim().isNotEmpty;

    return DetailPage(
      title: 'Appointment Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: AppCard(
              color: statusColors.background,
              borderColor: statusColors.background,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(
                      _visitStateIcon(visitState),
                      size: 34,
                      color: statusColors.foreground,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.title,
                          style: AppTextStyles.pageTitle.copyWith(fontSize: 23),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          appointment.doctorName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (appointment.specialty.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            appointment.specialty,
                            style: AppTextStyles.bodyMuted,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _visitStateLabel(visitState),
                            style: AppTextStyles.small.copyWith(
                              color: statusColors.foreground,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
          if (hasHospitalLocation) ...[
            const SizedBox(height: 19),
            Text('Hospital location', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: AppCard(
                color: AppColors.paleBlue,
                borderColor: AppColors.blue.withValues(alpha: .18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.blue,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.clinic.trim().isEmpty
                                    ? 'Saved appointment location'
                                    : appointment.clinic,
                                style: AppTextStyles.cardTitle,
                              ),
                              if (appointment.address.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  appointment.address,
                                  style: AppTextStyles.small,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openGoogleMapsDirections(appointment),
                        icon: const Icon(Icons.directions_rounded),
                        label: const Text('Get Directions in Google Maps'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openGoogleMapsHospitalDetails(appointment),
                        icon: const Icon(Icons.contact_phone_outlined),
                        label: const Text('Find Contact Number & Details'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Google Maps opens outside EverCare. Verify contact details and availability before traveling when possible.',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (visitState == AppointmentVisitState.cancelled) ...[
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
          if (visitState == AppointmentVisitState.missed) ...[
            const SizedBox(height: 19),
            const AppCard(
              color: Color(0xFFFFF8EE),
              borderColor: Color(0xFFF1D7B3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    color: Color(0xFF9A4F14),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No completion was recorded within 24 hours. If the visit happened, you can correct it below.',
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canMarkDone) ...[
            const SizedBox(height: 21),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _updating ? null : () => _markDone(appointment),
                icon: _updating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.task_alt_rounded),
                label: Text(
                  _updating
                      ? 'Saving…'
                      : visitState == AppointmentVisitState.missed
                      ? 'Mark Done Late'
                      : 'Mark Appointment as Done',
                ),
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

  Future<void> _markDone(Appointment appointment) async {
    final wasMissed =
        appointment.visitStateAt(_now) == AppointmentVisitState.missed;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.task_alt_rounded,
          color: AppColors.primaryGreen,
          size: 34,
        ),
        title: Text(
          wasMissed
              ? 'Record this visit as completed?'
              : 'Mark appointment as done?',
        ),
        content: Text(
          wasMissed
              ? 'This corrects the missed status and records that the patient attended the appointment.'
              : 'Confirm that the patient attended this appointment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not Yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Mark as Done'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repository = AppointmentRepository(
      EverCareBackendScope.read(context),
    );
    await _performUpdate(
      () => repository.markCompleted(appointment.id),
      updated: appointment.copyWith(
        status: AppointmentStatus.completed,
        completedAt: DateTime.now(),
      ),
      successMessage: 'Appointment marked as done.',
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

  Future<void> _openGoogleMapsDirections(Appointment appointment) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': _hospitalSearchQuery(appointment),
      'travelmode': 'driving',
    });
    await _launchExternalGoogleUrl(
      uri,
      failureMessage: 'Could not open Google Maps directions.',
    );
  }

  Future<void> _openGoogleMapsHospitalDetails(Appointment appointment) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': _hospitalSearchQuery(appointment),
    });
    await _launchExternalGoogleUrl(
      uri,
      failureMessage: 'Could not open this hospital in Google Maps.',
    );
  }

  Future<void> _launchExternalGoogleUrl(
    Uri uri, {
    required String failureMessage,
  }) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failureMessage)));
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

String _hospitalSearchQuery(Appointment appointment) {
  return <String>[
    if (appointment.clinic.trim().isNotEmpty) appointment.clinic.trim(),
    if (appointment.address.trim().isNotEmpty) appointment.address.trim(),
    'hospital',
  ].join(', ');
}

({Color background, Color foreground}) _visitStateColors(
  AppointmentVisitState state,
) {
  return switch (state) {
    AppointmentVisitState.upcoming => (
      background: AppColors.paleBlue,
      foreground: AppColors.blue,
    ),
    AppointmentVisitState.due => (
      background: AppColors.lightGreen,
      foreground: AppColors.darkGreen,
    ),
    AppointmentVisitState.completed => (
      background: AppColors.lightGreen,
      foreground: AppColors.darkGreen,
    ),
    AppointmentVisitState.missed => (
      background: const Color(0xFFFFF3E8),
      foreground: const Color(0xFF9A4F14),
    ),
    AppointmentVisitState.cancelled => (
      background: const Color(0xFFFFECEA),
      foreground: AppColors.danger,
    ),
  };
}

String _visitStateLabel(AppointmentVisitState state) => switch (state) {
  AppointmentVisitState.upcoming => 'Upcoming',
  AppointmentVisitState.due => 'Due now',
  AppointmentVisitState.completed => 'Completed',
  AppointmentVisitState.missed => 'Missed',
  AppointmentVisitState.cancelled => 'Cancelled',
};

IconData _visitStateIcon(AppointmentVisitState state) => switch (state) {
  AppointmentVisitState.upcoming => Icons.calendar_month_rounded,
  AppointmentVisitState.due => Icons.notifications_active_rounded,
  AppointmentVisitState.completed => Icons.event_available_rounded,
  AppointmentVisitState.missed => Icons.event_busy_outlined,
  AppointmentVisitState.cancelled => Icons.block_rounded,
};

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
