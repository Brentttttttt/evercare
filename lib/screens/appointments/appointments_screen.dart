import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/mock_appointment.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_header.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int _section = 0;

  List<MockAppointment> get _visibleAppointments => switch (_section) {
    0 => MockData.upcomingAppointments,
    1 => MockData.completedAppointments,
    _ => MockData.cancelledAppointments,
  };

  void _open(MockAppointment appointment) {
    Navigator.pushNamed(
      context,
      AppRoutes.appointmentDetails,
      arguments: appointment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextAppointment = MockData.upcomingAppointments.first;
    final visibleAppointments = _visibleAppointments;
    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CarePhotoBanner(
            assetPath: 'assets/images/appointment_clinic.png',
            semanticLabel:
                'An elderly woman speaking with her doctor in a bright clinic',
            title: 'Prepared for every visit',
            subtitle: 'Keep appointment details together and easy to review.',
            height: 172,
          ),
          const SizedBox(height: 24),
          const Text('NEXT APPOINTMENT', style: AppTextStyles.eyebrow),
          const SizedBox(height: 10),
          _NextAppointmentCard(
            appointment: nextAppointment,
            onTap: () => _open(nextAppointment),
          ),
          const SizedBox(height: 26),
          const SectionHeader(
            title: 'Appointment summary',
            subtitle: 'A simple overview of your visits',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  value: '2',
                  label: 'Upcoming',
                  icon: Icons.calendar_month_outlined,
                  color: AppColors.blue,
                  selected: _section == 0,
                  onTap: () => setState(() => _section = 0),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SummaryCard(
                  value: '4',
                  label: 'Completed',
                  icon: Icons.event_available_outlined,
                  color: AppColors.primaryGreen,
                  selected: _section == 1,
                  onTap: () => setState(() => _section = 1),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SummaryCard(
                  value: '1',
                  label: 'Cancelled',
                  icon: Icons.event_busy_outlined,
                  color: AppColors.danger,
                  selected: _section == 2,
                  onTap: () => setState(() => _section = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 27),
          const SectionHeader(title: 'Your appointments'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Upcoming')),
                ButtonSegment(value: 1, label: Text('Completed')),
                ButtonSegment(value: 2, label: Text('Cancelled')),
              ],
              selected: {_section},
              showSelectedIcon: false,
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8),
                ),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              onSelectionChanged: (value) =>
                  setState(() => _section = value.first),
            ),
          ),
          const SizedBox(height: 17),
          if (visibleAppointments.isEmpty)
            const EmptyStateCard(
              title: 'No appointments here',
              message: 'Appointments in this category will appear here.',
              icon: Icons.event_note_outlined,
            )
          else
            ...visibleAppointments.map(
              (appointment) => Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: AppointmentCard(
                  appointment: appointment,
                  onTap: () => _open(appointment),
                ),
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.addAppointment),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Appointment'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({required this.appointment, required this.onTap});

  final MockAppointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.darkGreen,
      borderColor: AppColors.darkGreen,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 51,
                      height: 51,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.title,
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            appointment.doctorName,
                            style: AppTextStyles.bodyMuted.copyWith(
                              color: const Color(0xFFD3E8DC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                _NextAppointmentFact(
                  icon: Icons.calendar_today_outlined,
                  text: appointment.dateLabel,
                ),
                const SizedBox(height: 10),
                _NextAppointmentFact(
                  icon: Icons.schedule_rounded,
                  text: appointment.timeLabel,
                ),
                const SizedBox(height: 10),
                _NextAppointmentFact(
                  icon: Icons.local_hospital_outlined,
                  text: appointment.clinic,
                ),
                const SizedBox(height: 19),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'View appointment details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextAppointmentFact extends StatelessWidget {
  const _NextAppointmentFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: const Color(0xFFBDE7CB)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: .1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? color.withValues(alpha: .45) : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 6),
              Text(
                value,
                style: AppTextStyles.sectionTitle.copyWith(color: color),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: AppTextStyles.small),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
