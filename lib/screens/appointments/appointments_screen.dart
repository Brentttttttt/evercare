import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/appointment.dart';
import '../../repositories/appointment_repository.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/section_header.dart';
import 'add_appointment_screen.dart';
import 'appointment_detail_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int _section = 0;
  SupabaseClient? _client;
  String? _userId;
  AppointmentRepository? _repository;
  Future<List<Appointment>>? _appointments;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final client = EverCareBackendScope.maybeClient(context);
    final userId = client?.auth.currentUser?.id;
    if (identical(client, _client) && userId == _userId) return;
    _client = client;
    _userId = userId;
    if (client != null && userId != null) {
      _repository = AppointmentRepository(client);
      _appointments = _repository!.fetchAll();
    } else {
      _repository = null;
      _appointments = null;
    }
  }

  void _reload() {
    final repository = _repository;
    if (repository == null) return;
    setState(() => _appointments = repository.fetchAll());
  }

  Future<void> _open(Appointment appointment) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appointment),
      ),
    );
    if (changed == true && mounted) _reload();
  }

  Future<void> _add() async {
    if (_repository == null) {
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
    );
    if (changed == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
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
            subtitle:
                'Keep your appointment details together and easy to review.',
            height: 172,
          ),
          const SizedBox(height: 24),
          if (_repository == null)
            EmptyStateCard(
              title: _client == null
                  ? 'Appointments unavailable'
                  : 'Sign in to view appointments',
              message: _client == null
                  ? 'The secure data service is not available in this app session.'
                  : 'Your appointment list is private and only loads after you sign in.',
              icon: _client == null
                  ? Icons.cloud_off_rounded
                  : Icons.lock_outline_rounded,
            )
          else
            FutureBuilder<List<Appointment>>(
              future: _appointments,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _AppointmentsError(onRetry: _reload);
                }
                return _AppointmentsContent(
                  appointments: snapshot.data ?? const [],
                  section: _section,
                  onSectionChanged: (value) => setState(() => _section = value),
                  onOpen: _open,
                );
              },
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _add,
              icon: Icon(
                _repository == null ? Icons.login_rounded : Icons.add_rounded,
              ),
              label: Text(
                _repository == null ? 'Sign in to continue' : 'Add Appointment',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentsContent extends StatelessWidget {
  const _AppointmentsContent({
    required this.appointments,
    required this.section,
    required this.onSectionChanged,
    required this.onOpen,
  });

  final List<Appointment> appointments;
  final int section;
  final ValueChanged<int> onSectionChanged;
  final ValueChanged<Appointment> onOpen;

  @override
  Widget build(BuildContext context) {
    final upcoming = appointments
        .where((item) => item.status == AppointmentStatus.upcoming)
        .toList();
    final completed =
        appointments
            .where((item) => item.status == AppointmentStatus.completed)
            .toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    final cancelled =
        appointments
            .where((item) => item.status == AppointmentStatus.cancelled)
            .toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    final visible = switch (section) {
      0 => upcoming,
      1 => completed,
      _ => cancelled,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NEXT APPOINTMENT', style: AppTextStyles.eyebrow),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          const EmptyStateCard(
            title: 'No upcoming appointment',
            message: 'Your next scheduled visit will appear here.',
            icon: Icons.event_available_outlined,
          )
        else
          _NextAppointmentCard(
            appointment: upcoming.first,
            onTap: () => onOpen(upcoming.first),
          ),
        const SizedBox(height: 26),
        const SectionHeader(
          title: 'Appointment summary',
          subtitle: 'A simple overview of your saved visits',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                value: '${upcoming.length}',
                label: 'Upcoming',
                icon: Icons.calendar_month_outlined,
                color: AppColors.blue,
                selected: section == 0,
                onTap: () => onSectionChanged(0),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _SummaryCard(
                value: '${completed.length}',
                label: 'Completed',
                icon: Icons.event_available_outlined,
                color: AppColors.primaryGreen,
                selected: section == 1,
                onTap: () => onSectionChanged(1),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _SummaryCard(
                value: '${cancelled.length}',
                label: 'Cancelled',
                icon: Icons.event_busy_outlined,
                color: AppColors.danger,
                selected: section == 2,
                onTap: () => onSectionChanged(2),
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
            selected: {section},
            showSelectedIcon: false,
            style: const ButtonStyle(
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8),
              ),
              textStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            onSelectionChanged: (value) => onSectionChanged(value.first),
          ),
        ),
        const SizedBox(height: 17),
        if (visible.isEmpty)
          const EmptyStateCard(
            title: 'No appointments here',
            message: 'Appointments in this category will appear here.',
            icon: Icons.event_note_outlined,
          )
        else
          ...visible.map(
            (appointment) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: AppointmentCard(
                appointment: appointment,
                onTap: () => onOpen(appointment),
              ),
            ),
          ),
      ],
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({required this.appointment, required this.onTap});

  final Appointment appointment;
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
          const Positioned.fill(
            child: CareCardArtwork(
              assetPath: 'assets/images/appointment_card_v2.png',
              alignment: Alignment.centerRight,
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

class _AppointmentsError extends StatelessWidget {
  const _AppointmentsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const EmptyStateCard(
          title: 'Could not load appointments',
          message: 'Check your connection, then try again.',
          icon: Icons.cloud_off_outlined,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
