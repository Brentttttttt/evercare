import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/appointment.dart';
import '../../repositories/appointment_repository.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_skeleton.dart';
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
    return Stack(
      children: [
        SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 204),
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
              const SizedBox(height: 28),
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
                      return const _AppointmentsLoading();
                    }
                    if (snapshot.hasError) {
                      return _AppointmentsError(onRetry: _reload);
                    }
                    return _AppointmentsContent(
                      appointments: snapshot.data ?? const [],
                      section: _section,
                      onSectionChanged: (value) =>
                          setState(() => _section = value),
                      onOpen: _open,
                    );
                  },
                ),
            ],
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 180,
          child: IgnorePointer(child: _BottomActionScrim()),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 92,
          child: SafeArea(
            top: false,
            minimum: EdgeInsets.zero,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _add,
                icon: Icon(
                  _repository == null ? Icons.login_rounded : Icons.add_rounded,
                ),
                label: Text(
                  _repository == null
                      ? 'Sign in to continue'
                      : 'Add Appointment',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
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
    final upcoming =
        appointments
            .where((item) => item.status == AppointmentStatus.upcoming)
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
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
        const SectionHeader(
          title: 'Next appointment',
          subtitle: 'Your nearest scheduled visit',
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 28),
        SectionHeader(
          title: 'Your appointments',
          subtitle:
              '${appointments.length} ${appointments.length == 1 ? 'saved visit' : 'saved visits'}',
        ),
        const SizedBox(height: 12),
        _AppointmentStatusFilter(
          selected: section,
          onChanged: onSectionChanged,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(switch (section) {
                0 => 'Upcoming',
                1 => 'Completed',
                _ => 'Cancelled',
              }, style: AppTextStyles.cardTitle),
            ),
            Text(
              '${visible.length} ${visible.length == 1 ? 'visit' : 'visits'}',
              style: AppTextStyles.label,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          EmptyStateCard(
            title: switch (section) {
              0 => 'No upcoming appointments',
              1 => 'No completed appointments',
              _ => 'No cancelled appointments',
            },
            message: 'Appointments in this category will appear here.',
            icon: switch (section) {
              0 => Icons.event_outlined,
              1 => Icons.event_available_outlined,
              _ => Icons.event_busy_outlined,
            },
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  _CompactAppointmentRow(
                    appointment: visible[index],
                    onTap: () => onOpen(visible[index]),
                  ),
                  if (index != visible.length - 1)
                    const Divider(height: 1, indent: 70),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AppointmentStatusFilter extends StatelessWidget {
  const _AppointmentStatusFilter({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  static const _labels = ['Upcoming', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final useWrappedControls =
        MediaQuery.sizeOf(context).width < 350 || textScale > 1.3;
    return Semantics(
      container: true,
      label: 'Filter appointments by status',
      child: useWrappedControls
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_labels.length, (index) {
                final label = _labels[index];
                return ChoiceChip(
                  selected: selected == index,
                  showCheckmark: false,
                  label: Text(label),
                  onSelected: (_) => onChanged(index),
                );
              }),
            )
          : SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: List.generate(
                  _labels.length,
                  (index) =>
                      ButtonSegment(value: index, label: Text(_labels[index])),
                ),
                selected: {selected},
                showSelectedIcon: false,
                onSelectionChanged: (value) => onChanged(value.first),
              ),
            ),
    );
  }
}

class _CompactAppointmentRow extends StatelessWidget {
  const _CompactAppointmentRow({
    required this.appointment,
    required this.onTap,
  });

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = appointmentStatusColors(appointment.status);
    return Semantics(
      button: true,
      label:
          '${appointment.title}, ${appointment.doctorName}, '
          '${appointment.dateLabel} at ${appointment.timeLabel}, '
          '${appointment.clinic}, ${appointment.statusLabel}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    switch (appointment.status) {
                      AppointmentStatus.upcoming =>
                        Icons.calendar_month_rounded,
                      AppointmentStatus.completed =>
                        Icons.event_available_rounded,
                      AppointmentStatus.cancelled => Icons.event_busy_rounded,
                    },
                    size: 22,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        appointment.doctorName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMuted,
                      ),
                      if (appointment.specialty.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          appointment.specialty,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.small,
                        ),
                      ],
                      const SizedBox(height: 9),
                      _CompactAppointmentFact(
                        icon: Icons.event_outlined,
                        text:
                            '${appointment.dateLabel} • ${appointment.timeLabel}',
                      ),
                      const SizedBox(height: 6),
                      _CompactAppointmentFact(
                        icon: Icons.local_hospital_outlined,
                        text: appointment.clinic,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(top: 9),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactAppointmentFact extends StatelessWidget {
  const _CompactAppointmentFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
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
                Divider(color: Colors.white.withValues(alpha: .24), height: 1),
                const SizedBox(height: 14),
                const Row(
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
                    Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionScrim extends StatelessWidget {
  const _BottomActionScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00F3F5F3), AppColors.background],
          stops: [0, .48],
        ),
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

class _AppointmentsLoading extends StatelessWidget {
  const _AppointmentsLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Next appointment',
          subtitle: 'Loading your nearest scheduled visit',
        ),
        SizedBox(height: 12),
        AppCardSkeleton(lines: 4),
        SizedBox(height: 28),
        SectionHeader(
          title: 'Your appointments',
          subtitle: 'Loading your saved visits',
        ),
        SizedBox(height: 12),
        AppSkeleton(width: 288, height: 42, borderRadius: 10),
        SizedBox(height: 16),
        AppCardSkeleton(lines: 4),
        SizedBox(height: 10),
        AppCardSkeleton(lines: 4),
      ],
    );
  }
}

class _AppointmentsError extends StatelessWidget {
  const _AppointmentsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      title: 'Could not load appointments',
      message: 'Check your connection, then try again.',
      icon: Icons.cloud_off_outlined,
      actionLabel: 'Try again',
      actionIcon: Icons.refresh_rounded,
      onAction: onRetry,
    );
  }
}
