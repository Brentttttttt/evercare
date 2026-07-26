import 'package:flutter/material.dart';

import '../../models/mock_appointment.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/appointment_card.dart';
import '../authentication/auth_widgets.dart';

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({required this.appointment, super.key});

  final MockAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final statusColors = appointmentStatusColors(appointment.status);
    final isUpcoming = appointment.status == MockAppointmentStatus.upcoming;
    final isCompleted = appointment.status == MockAppointmentStatus.completed;

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
                        : appointment.status == MockAppointmentStatus.cancelled
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
                const SizedBox(height: 3),
                Text(
                  appointment.specialty,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
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
                const Divider(),
                LabeledValue(
                  label: 'Address',
                  value: appointment.address,
                  icon: Icons.location_on_outlined,
                ),
                const Divider(),
                LabeledValue(
                  label: isCompleted ? 'Visit notes' : 'Notes',
                  value: appointment.notes,
                  icon: Icons.notes_rounded,
                ),
              ],
            ),
          ),
          if (isCompleted) ...[
            const SizedBox(height: 19),
            AppCard(
              color: AppColors.lightGreen,
              borderColor: AppColors.lightGreen,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    color: AppColors.darkGreen,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Follow-up reminder',
                          style: AppTextStyles.cardTitle,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Continue following the printed instructions from the clinic and bring this visit summary to your next consultation.',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (appointment.status == MockAppointmentStatus.cancelled) ...[
            const SizedBox(height: 19),
            AppCard(
              color: const Color(0xFFFFF5F3),
              borderColor: const Color(0xFFF6D5D1),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.danger),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This appointment is shown as cancelled in the hardcoded sample schedule.',
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
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.editAppointment,
                  arguments: appointment,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Appointment'),
              ),
            ),
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRescheduleSheet(context),
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
                onPressed: () => _confirmCancellation(context),
                icon: const Icon(Icons.event_busy_outlined),
                label: const Text('Cancel Appointment'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showRescheduleSheet(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          22,
          4,
          22,
          22 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reschedule appointment', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 5),
            const Text(
              'Preview a new date and time. Nothing will be changed or saved.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 20),
            MockTextField(
              label: 'Current date',
              icon: Icons.event_outlined,
              initialValue: appointment.dateLabel,
              readOnly: true,
            ),
            MockTextField(
              label: 'Current time',
              icon: Icons.schedule_rounded,
              initialValue: appointment.timeLabel,
              readOnly: true,
            ),
            const MockTextField(
              label: 'New date',
              hint: 'Select a new date',
              icon: Icons.calendar_today_outlined,
              readOnly: true,
            ),
            const MockTextField(
              label: 'New time',
              hint: 'Select a new time',
              icon: Icons.access_time_rounded,
              readOnly: true,
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, true),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Confirm New Schedule'),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: const Text('Keep Current Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      await showMockDialog(
        context,
        title: 'Schedule preview complete',
        message:
            'The reschedule flow is complete. No appointment information was changed or saved.',
        icon: Icons.event_available_outlined,
      );
    }
  }

  Future<void> _confirmCancellation(BuildContext context) async {
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
          'Are you sure you want to cancel the ${appointment.title} with ${appointment.doctorName}? This is a UI preview only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Appointment'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cancellation preview complete. No appointment was changed.',
          ),
        ),
      );
    }
  }
}
