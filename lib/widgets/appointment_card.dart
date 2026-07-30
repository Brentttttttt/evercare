import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_page.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    required this.appointment,
    required this.onTap,
    super.key,
  });

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = appointmentStatusColors(appointment.status);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  _statusIcon(appointment.status),
                  color: colors.foreground,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 4),
                    Text(
                      appointment.doctorName,
                      style: AppTextStyles.bodyMuted,
                    ),
                    const SizedBox(height: 2),
                    Text(appointment.specialty, style: AppTextStyles.small),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryText,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          Wrap(
            spacing: 16,
            runSpacing: 9,
            children: [
              _AppointmentFact(
                icon: Icons.event_outlined,
                label: appointment.dateLabel,
              ),
              _AppointmentFact(
                icon: Icons.schedule_rounded,
                label: appointment.timeLabel,
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.local_hospital_outlined,
                size: 19,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(appointment.clinic, style: AppTextStyles.bodyMuted),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                appointment.statusLabel,
                style: AppTextStyles.small.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

({Color background, Color foreground}) appointmentStatusColors(
  AppointmentStatus status,
) {
  return switch (status) {
    AppointmentStatus.upcoming => (
      background: AppColors.paleBlue,
      foreground: AppColors.blue,
    ),
    AppointmentStatus.completed => (
      background: AppColors.lightGreen,
      foreground: AppColors.darkGreen,
    ),
    AppointmentStatus.cancelled => (
      background: const Color(0xFFFFECEA),
      foreground: AppColors.danger,
    ),
  };
}

IconData _statusIcon(AppointmentStatus status) {
  return switch (status) {
    AppointmentStatus.upcoming => Icons.calendar_month_rounded,
    AppointmentStatus.completed => Icons.event_available_rounded,
    AppointmentStatus.cancelled => Icons.event_busy_rounded,
  };
}

class _AppointmentFact extends StatelessWidget {
  const _AppointmentFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: AppColors.primaryGreen),
        const SizedBox(width: 7),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
