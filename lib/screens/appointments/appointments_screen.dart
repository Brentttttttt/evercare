import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/appointment.dart';
import '../../repositories/appointment_repository.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/section_header.dart';
import 'add_appointment_screen.dart';
import 'appointment_detail_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({
    super.key,
    this.isActive = true,
    this.scrollController,
  });

  final bool isActive;
  final ScrollController? scrollController;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with WidgetsBindingObserver {
  int _section = 0;
  SupabaseClient? _client;
  String? _userId;
  AppointmentRepository? _repository;
  Future<List<Appointment>>? _appointments;
  List<Appointment> _latestAppointments = const [];
  Timer? _clockTimer;
  DateTime _now = DateTime.now().toUtc();
  final Set<String> _completingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateClockTimer();
  }

  @override
  void didUpdateWidget(covariant AppointmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    _updateClockTimer();
    if (widget.isActive) _reload();
  }

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
    _now = DateTime.now().toUtc();
    setState(() {
      _appointments = repository.fetchAll();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateClockTimer() {
    _clockTimer?.cancel();
    if (!widget.isActive) return;
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final previous = _now;
      final now = DateTime.now().toUtc();
      final crossedMissedBoundary = _latestAppointments.any(
        (appointment) =>
            appointment.status == AppointmentStatus.upcoming &&
            appointment.visitStateAt(previous) !=
                AppointmentVisitState.missed &&
            appointment.visitStateAt(now) == AppointmentVisitState.missed,
      );
      setState(() => _now = now);
      if (crossedMissedBoundary) _reload();
    });
  }

  Future<void> _markDone(Appointment appointment) async {
    final repository = _repository;
    if (repository == null || !_completingIds.add(appointment.id)) return;
    setState(() {});
    try {
      await repository.markCompleted(appointment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appointment.title} marked as done.')),
      );
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark this appointment as done. Try again.'),
        ),
      );
    } finally {
      _completingIds.remove(appointment.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _open(Appointment appointment) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appointment),
      ),
    );
    if (mounted) _reload();
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
          controller: widget.scrollController,
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
                    final appointments = snapshot.data ?? const [];
                    _latestAppointments = appointments;
                    return _AppointmentsContent(
                      appointments: appointments,
                      now: _now,
                      section: _section,
                      onSectionChanged: (value) =>
                          setState(() => _section = value),
                      onOpen: _open,
                      onMarkDone: (appointment) {
                        unawaited(_markDone(appointment));
                      },
                      completingIds: _completingIds,
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
    required this.now,
    required this.section,
    required this.onSectionChanged,
    required this.onOpen,
    required this.onMarkDone,
    required this.completingIds,
  });

  final List<Appointment> appointments;
  final DateTime now;
  final int section;
  final ValueChanged<int> onSectionChanged;
  final ValueChanged<Appointment> onOpen;
  final ValueChanged<Appointment> onMarkDone;
  final Set<String> completingIds;

  @override
  Widget build(BuildContext context) {
    final upcoming = appointments.where((item) {
      final state = item.visitStateAt(now);
      return state == AppointmentVisitState.upcoming ||
          state == AppointmentVisitState.due;
    }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final completed =
        appointments
            .where(
              (item) =>
                  item.visitStateAt(now) == AppointmentVisitState.completed,
            )
            .toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    final missed =
        appointments
            .where(
              (item) => item.visitStateAt(now) == AppointmentVisitState.missed,
            )
            .toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    final cancelled =
        appointments
            .where(
              (item) =>
                  item.visitStateAt(now) == AppointmentVisitState.cancelled,
            )
            .toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    final visible = switch (section) {
      0 => upcoming,
      1 => completed,
      2 => missed,
      _ => cancelled,
    };
    final nextAppointment = upcoming.firstOrNull;
    final nextState = nextAppointment?.visitStateAt(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: nextState == AppointmentVisitState.due
              ? 'Appointment reminder'
              : 'Next appointment',
          subtitle: nextState == AppointmentVisitState.due
              ? 'This visit is ready to be confirmed'
              : 'Your nearest scheduled visit',
        ),
        const SizedBox(height: 12),
        if (nextAppointment == null)
          const EmptyStateCard(
            title: 'No upcoming appointment',
            message: 'Your next scheduled visit will appear here.',
            icon: Icons.event_available_outlined,
          )
        else
          _NextAppointmentCard(
            appointment: nextAppointment,
            state: nextState!,
            busy: completingIds.contains(nextAppointment.id),
            onTap: () => onOpen(nextAppointment),
            onMarkDone: () => onMarkDone(nextAppointment),
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
                2 => 'Missed',
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
              2 => 'No missed appointments',
              _ => 'No cancelled appointments',
            },
            message: 'Appointments in this category will appear here.',
            icon: switch (section) {
              0 => Icons.event_outlined,
              1 => Icons.event_available_outlined,
              2 => Icons.event_busy_outlined,
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
                    state: visible[index].visitStateAt(now),
                    busy: completingIds.contains(visible[index].id),
                    onTap: () => onOpen(visible[index]),
                    onMarkDone: () => onMarkDone(visible[index]),
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

  static const _labels = ['Upcoming', 'Done', 'Missed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Filter appointments by status',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(_labels.length, (index) {
          final label = _labels[index];
          final isSelected = selected == index;
          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: Icon(
              switch (index) {
                0 => Icons.calendar_today_outlined,
                1 => Icons.check_circle_outline_rounded,
                2 => Icons.event_busy_outlined,
                _ => Icons.cancel_outlined,
              },
              size: 18,
              color: isSelected ? AppColors.darkGreen : AppColors.secondaryText,
            ),
            label: Text(label),
            onSelected: (_) => onChanged(index),
          );
        }),
      ),
    );
  }
}

class _CompactAppointmentRow extends StatelessWidget {
  const _CompactAppointmentRow({
    required this.appointment,
    required this.state,
    required this.busy,
    required this.onTap,
    required this.onMarkDone,
  });

  final Appointment appointment;
  final AppointmentVisitState state;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onMarkDone;

  @override
  Widget build(BuildContext context) {
    final colors = _appointmentVisitColors(state);
    final actionLabel = switch (state) {
      AppointmentVisitState.due => 'Mark as Done',
      AppointmentVisitState.missed => 'Mark Done Late',
      _ => null,
    };
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label:
                '${appointment.title}, ${appointment.doctorName}, '
                '${appointment.dateLabel} at ${appointment.timeLabel}, '
                '${appointment.clinic}, ${_appointmentVisitLabel(state)}',
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    14,
                    10,
                    actionLabel == null ? 14 : 10,
                  ),
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
                          _appointmentVisitIcon(state),
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
                            const SizedBox(height: 9),
                            _AppointmentStatusBadge(state: state),
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
          ),
          if (actionLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onMarkDone,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(busy ? 'Saving…' : actionLabel),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppointmentStatusBadge extends StatelessWidget {
  const _AppointmentStatusBadge({required this.state});

  final AppointmentVisitState state;

  @override
  Widget build(BuildContext context) {
    final colors = _appointmentVisitColors(state);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _appointmentVisitIcon(state),
              size: 15,
              color: colors.foreground,
            ),
            const SizedBox(width: 5),
            Text(
              _appointmentVisitLabel(state),
              style: AppTextStyles.small.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
  const _NextAppointmentCard({
    required this.appointment,
    required this.state,
    required this.busy,
    required this.onTap,
    required this.onMarkDone,
  });

  final Appointment appointment;
  final AppointmentVisitState state;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onMarkDone;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .18),
                        ),
                      ),
                      child: Text(
                        _appointmentVisitLabel(state),
                        style: AppTextStyles.small.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state == AppointmentVisitState.due
                            ? 'Visit is due • open details'
                            : 'View appointment details',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
                if (state == AppointmentVisitState.due) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: busy ? null : onMarkDone,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.darkGreen,
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: .65,
                        ),
                        disabledForegroundColor: AppColors.darkGreen,
                      ),
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(busy ? 'Saving…' : 'Mark as Done'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

({Color background, Color foreground}) _appointmentVisitColors(
  AppointmentVisitState state,
) {
  return switch (state) {
    AppointmentVisitState.upcoming => (
      background: AppColors.paleBlue,
      foreground: AppColors.blue,
    ),
    AppointmentVisitState.due => (
      background: AppColors.warningContainer,
      foreground: AppColors.warning,
    ),
    AppointmentVisitState.completed => (
      background: AppColors.lightGreen,
      foreground: AppColors.darkGreen,
    ),
    AppointmentVisitState.missed => (
      background: AppColors.destructiveContainer,
      foreground: AppColors.danger,
    ),
    AppointmentVisitState.cancelled => (
      background: AppColors.muted,
      foreground: AppColors.secondaryText,
    ),
  };
}

String _appointmentVisitLabel(AppointmentVisitState state) {
  return switch (state) {
    AppointmentVisitState.upcoming => 'Upcoming',
    AppointmentVisitState.due => 'Due now',
    AppointmentVisitState.completed => 'Completed',
    AppointmentVisitState.missed => 'Missed',
    AppointmentVisitState.cancelled => 'Cancelled',
  };
}

IconData _appointmentVisitIcon(AppointmentVisitState state) {
  return switch (state) {
    AppointmentVisitState.upcoming => Icons.calendar_month_rounded,
    AppointmentVisitState.due => Icons.notifications_active_rounded,
    AppointmentVisitState.completed => Icons.event_available_rounded,
    AppointmentVisitState.missed => Icons.event_busy_rounded,
    AppointmentVisitState.cancelled => Icons.block_outlined,
  };
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
