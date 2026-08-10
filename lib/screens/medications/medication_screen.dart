import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/medication.dart';
import '../../models/medication_dose.dart';
import '../../repositories/medication_repository.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/section_header.dart';
import 'add_medication_screen.dart';
import 'medication_detail_screen.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({
    super.key,
    this.isActive = true,
    this.scrollController,
  });

  final bool isActive;
  final ScrollController? scrollController;

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen>
    with WidgetsBindingObserver {
  int _tab = 0;
  SupabaseClient? _client;
  String? _userId;
  MedicationRepository? _repository;
  Future<MedicationOverview>? _overview;
  MedicationOverview? _latestOverview;
  Timer? _clockTimer;
  DateTime _now = DateTime.now().toUtc();
  late String _philippineDateKey = _dateKey(_now);
  final Set<String> _takingDoseKeys = {};
  final Set<String> _syncingMissedKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateClockTimer();
  }

  @override
  void didUpdateWidget(covariant MedicationScreen oldWidget) {
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
      _repository = MedicationRepository(client);
      _overview = _repository!.fetchOverview(now: _now);
    } else {
      _repository = null;
      _overview = null;
      _latestOverview = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _now = DateTime.now().toUtc();
      _reload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    super.dispose();
  }

  void _reload() {
    final repository = _repository;
    if (repository == null) return;
    _now = DateTime.now().toUtc();
    _philippineDateKey = _dateKey(_now);
    setState(() {
      _overview = repository.fetchOverview(now: _now);
    });
  }

  void _updateClockTimer() {
    _clockTimer?.cancel();
    if (!widget.isActive) return;
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final now = DateTime.now().toUtc();
      final dateKey = _dateKey(now);
      if (dateKey != _philippineDateKey) {
        _philippineDateKey = dateKey;
        _now = now;
        _reload();
        return;
      }
      setState(() => _now = now);
      unawaited(_syncNewlyMissedDoses());
    });
  }

  MedicationDoseState _stateAt(MedicationDoseOccurrence occurrence) {
    return MedicationScheduleEngine(now: () => _now).resolveState(
      scheduledFor: occurrence.scheduledFor,
      dose: occurrence.dose,
      at: _now,
    );
  }

  Future<void> _syncNewlyMissedDoses() async {
    final repository = _repository;
    final overview = _latestOverview;
    if (repository == null || overview == null) return;
    var changed = false;
    for (final occurrence in overview.todayDoses) {
      final key = _doseKey(occurrence);
      if (_stateAt(occurrence) != MedicationDoseState.missed ||
          occurrence.dose?.status == MedicationDoseStatus.missed ||
          !_syncingMissedKeys.add(key)) {
        continue;
      }
      try {
        await repository.markMissed(occurrence);
        changed = true;
      } catch (_) {
        // The derived Missed state remains honest locally; a later refresh
        // retries persistence without interrupting the caregiver.
      } finally {
        _syncingMissedKeys.remove(key);
      }
    }
    if (changed && mounted) _reload();
  }

  Future<void> _markTaken(MedicationDoseOccurrence occurrence) async {
    final repository = _repository;
    final key = _doseKey(occurrence);
    if (repository == null || !_takingDoseKeys.add(key)) return;
    setState(() {});
    try {
      await repository.markTaken(occurrence);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${occurrence.medication.name} marked as taken.'),
        ),
      );
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not mark this dose as taken. Try again.'),
        ),
      );
    } finally {
      _takingDoseKeys.remove(key);
      if (mounted) setState(() {});
    }
  }

  String _doseKey(MedicationDoseOccurrence occurrence) =>
      '${occurrence.medication.id}|${occurrence.scheduledFor.toUtc().toIso8601String()}';

  Future<void> _openMedication(Medication medication) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MedicationDetailScreen(medication: medication),
      ),
    );
    if (changed == true && mounted) _reload();
  }

  Future<void> _addMedication() async {
    if (_repository == null) {
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
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
                assetPath: 'assets/images/medication_support.png',
                semanticLabel:
                    'A caregiver helping an elderly woman organize medicines at home',
                title: 'Medication support, made simple',
                subtitle:
                    'Keep your current medicine schedule together in one place.',
                height: 172,
              ),
              const SizedBox(height: 28),
              if (_repository == null)
                _MedicationAccessCard(backendAvailable: _client != null)
              else
                FutureBuilder<MedicationOverview>(
                  future: _overview,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _MedicationLoadingContent();
                    }
                    if (snapshot.hasError) {
                      return _MedicationErrorCard(onRetry: _reload);
                    }
                    final overview =
                        snapshot.data ??
                        const MedicationOverview(
                          medications: [],
                          todayDoses: [],
                        );
                    _latestOverview = overview;
                    return _MedicationContent(
                      overview: overview,
                      now: _now,
                      selected: _tab,
                      onSelected: (value) => setState(() => _tab = value),
                      onOpen: _openMedication,
                      onTaken: _markTaken,
                      takingDoseKeys: _takingDoseKeys,
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
                onPressed: _addMedication,
                icon: Icon(
                  _repository == null ? Icons.login_rounded : Icons.add_rounded,
                ),
                label: Text(
                  _repository == null
                      ? 'Sign in to continue'
                      : 'Add Medication',
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

class _MedicationAccessCard extends StatelessWidget {
  const _MedicationAccessCard({required this.backendAvailable});

  final bool backendAvailable;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      title: backendAvailable
          ? 'Sign in to view medications'
          : 'Medications unavailable',
      message: backendAvailable
          ? 'Your medication list is private and only loads after you sign in.'
          : 'The secure data service is not available in this app session.',
      icon: backendAvailable
          ? Icons.lock_outline_rounded
          : Icons.cloud_off_rounded,
    );
  }
}

class _MedicationContent extends StatelessWidget {
  const _MedicationContent({
    required this.overview,
    required this.now,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
    required this.onTaken,
    required this.takingDoseKeys,
  });

  final MedicationOverview overview;
  final DateTime now;
  final int selected;
  final ValueChanged<int> onSelected;
  final ValueChanged<Medication> onOpen;
  final ValueChanged<MedicationDoseOccurrence> onTaken;
  final Set<String> takingDoseKeys;

  @override
  Widget build(BuildContext context) {
    final medications = overview.medications;
    final current = medications
        .where((item) => item.isActive && !item.isCompleted)
        .toList();
    final completed = medications.where((item) => item.isCompleted).toList();
    final visible = switch (selected) {
      0 => current,
      1 => medications,
      _ => completed,
    };
    final selectedLabel = switch (selected) {
      0 => 'Current medications',
      1 => 'All medications',
      _ => 'Completed medications',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MedicationReminderSection(
          doses: overview.todayDoses,
          now: now,
          onTaken: onTaken,
          takingDoseKeys: takingDoseKeys,
          hasUnconfirmedSchedules: current.any(
            (medication) => !medication.hasReminderSchedule,
          ),
        ),
        const SizedBox(height: 28),
        SectionHeader(
          title: 'Your medications',
          subtitle:
              '${medications.length} saved • ${current.length} currently active',
        ),
        const SizedBox(height: 12),
        _MedicationStatusFilter(selected: selected, onChanged: onSelected),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(selectedLabel, style: AppTextStyles.cardTitle),
            ),
            Text(
              '${visible.length} ${visible.length == 1 ? 'medicine' : 'medicines'}',
              style: AppTextStyles.label,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visible.isEmpty)
          EmptyStateCard(
            title: switch (selected) {
              0 => 'No current medications',
              1 => 'No medications yet',
              _ => 'No completed medications',
            },
            message: selected == 1
                ? 'Add a medication to build your personal list.'
                : selected == 2
                ? 'Medicines you mark as done will appear here.'
                : 'Active medicines will appear here.',
            icon: selected == 2
                ? Icons.task_alt_rounded
                : Icons.medication_outlined,
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  _MedicationRow(
                    medication: visible[index],
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

class MedicationReminderSection extends StatelessWidget {
  const MedicationReminderSection({
    required this.doses,
    required this.now,
    required this.onTaken,
    required this.takingDoseKeys,
    required this.hasUnconfirmedSchedules,
    super.key,
  });

  final List<MedicationDoseOccurrence> doses;
  final DateTime now;
  final ValueChanged<MedicationDoseOccurrence> onTaken;
  final Set<String> takingDoseKeys;
  final bool hasUnconfirmedSchedules;

  @override
  Widget build(BuildContext context) {
    final engine = MedicationScheduleEngine(now: () => now);
    final states = [
      for (final dose in doses)
        engine.resolveState(
          scheduledFor: dose.scheduledFor,
          dose: dose.dose,
          at: now,
        ),
    ];
    final dueCount = states
        .where((state) => state == MedicationDoseState.due)
        .length;
    final missedCount = states
        .where((state) => state == MedicationDoseState.missed)
        .length;
    final takenCount = states
        .where((state) => state == MedicationDoseState.taken)
        .length;
    final upcomingCount = states
        .where((state) => state == MedicationDoseState.upcoming)
        .length;
    final skippedCount = states
        .where((state) => state == MedicationDoseState.skipped)
        .length;
    final summary = doses.isEmpty
        ? 'One reminder is shown at the saved time on each chosen day.'
        : [
            if (dueCount > 0) '$dueCount due now',
            if (takenCount > 0) '$takenCount taken',
            if (missedCount > 0) '$missedCount missed',
            if (upcomingCount > 0) '$upcomingCount upcoming',
            if (skippedCount > 0) '$skippedCount skipped',
          ].join(' • ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Medication reminders', subtitle: summary),
        const SizedBox(height: 12),
        if (doses.isEmpty)
          AppCard(
            color: AppColors.muted,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No doses scheduled today',
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasUnconfirmedSchedules
                            ? 'An older medication still needs reminder days. Open it, choose Edit, then select its weekdays.'
                            : 'Your selected weekday schedules have no doses for today.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            borderColor: dueCount > 0
                ? AppColors.primaryGreen.withValues(alpha: .42)
                : AppColors.border,
            child: Column(
              children: [
                for (var index = 0; index < doses.length; index++) ...[
                  _TodayDoseRow(
                    occurrence: doses[index],
                    state: states[index],
                    now: now,
                    busy: takingDoseKeys.contains(_occurrenceKey(doses[index])),
                    onTaken: () => onTaken(doses[index]),
                  ),
                  if (index != doses.length - 1)
                    const Divider(height: 1, indent: 64),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TodayDoseRow extends StatelessWidget {
  const _TodayDoseRow({
    required this.occurrence,
    required this.state,
    required this.now,
    required this.busy,
    required this.onTaken,
  });

  final MedicationDoseOccurrence occurrence;
  final MedicationDoseState state;
  final DateTime now;
  final bool busy;
  final VoidCallback onTaken;

  @override
  Widget build(BuildContext context) {
    final actionLabel = switch (state) {
      MedicationDoseState.due => 'Taken',
      MedicationDoseState.missed => 'Taken late',
      _ => null,
    };
    final statusLabel = switch (state) {
      MedicationDoseState.upcoming => 'Upcoming',
      MedicationDoseState.due => 'Due now',
      MedicationDoseState.taken => 'Taken',
      MedicationDoseState.skipped => 'Skipped',
      MedicationDoseState.missed => 'Missed',
    };
    final statusColor = switch (state) {
      MedicationDoseState.taken => AppColors.primaryGreen,
      MedicationDoseState.due => AppColors.primaryGreen,
      MedicationDoseState.missed => AppColors.danger,
      MedicationDoseState.skipped => AppColors.warning,
      MedicationDoseState.upcoming => AppColors.secondaryText,
    };
    final icon = switch (state) {
      MedicationDoseState.taken => Icons.check_circle_rounded,
      MedicationDoseState.due => Icons.notifications_active_rounded,
      MedicationDoseState.missed => Icons.error_outline_rounded,
      MedicationDoseState.skipped => Icons.next_plan_outlined,
      MedicationDoseState.upcoming => Icons.schedule_rounded,
    };
    final time = _philippineTimeLabel(occurrence.scheduledFor);
    final scheduledLabel = _samePhilippineDate(occurrence.scheduledFor, now)
        ? time
        : 'yesterday at $time';
    final detail = switch (state) {
      MedicationDoseState.upcoming => 'Scheduled for $scheduledLabel',
      MedicationDoseState.due =>
        'Scheduled for $scheduledLabel • Confirm after the patient takes it',
      MedicationDoseState.missed =>
        'More than one hour past the $scheduledLabel reminder',
      MedicationDoseState.skipped => 'This dose was skipped',
      MedicationDoseState.taken =>
        occurrence.dose?.takenAt == null
            ? 'Dose recorded as taken'
            : 'Recorded at ${_philippineTimeLabel(occurrence.dose!.takenAt!)}',
    };
    return Semantics(
      container: true,
      label:
          '${occurrence.medication.name}, $statusLabel, scheduled for $scheduledLabel',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: statusColor, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occurrence.medication.name,
                        style: AppTextStyles.cardTitle,
                      ),
                      if (occurrence.medication.dosage.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          occurrence.medication.dosage,
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(detail, style: AppTextStyles.small),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.small.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onTaken,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(busy ? 'Saving…' : actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MedicationStatusFilter extends StatelessWidget {
  const _MedicationStatusFilter({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  static const _labels = ['Current', 'All', 'Done'];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final useWrappedControls =
        MediaQuery.sizeOf(context).width < 350 || textScale > 1.3;
    return Semantics(
      container: true,
      label: 'Filter medications by status',
      child: useWrappedControls
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_labels.length, (index) {
                return ChoiceChip(
                  selected: selected == index,
                  showCheckmark: false,
                  label: Text(_labels[index]),
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

class _MedicationRow extends StatelessWidget {
  const _MedicationRow({required this.medication, required this.onTap});

  final Medication medication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = medication.isActive && !medication.isCompleted;
    final details = medication.dosage.trim();
    return Semantics(
      button: true,
      label:
          '${medication.name}, $details, ${medication.scheduleLabel}, ${medication.statusLabel}',
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
                    color: active || medication.isCompleted
                        ? AppColors.primaryContainer
                        : AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    size: 21,
                    color: active || medication.isCompleted
                        ? AppColors.primaryGreen
                        : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          details,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                      if (medication.purpose.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          medication.purpose,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.small,
                        ),
                      ],
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _MedicationMetadata(
                            icon: Icons.schedule_rounded,
                            label: medication.scheduleLabel,
                          ),
                          _MedicationMetadata(
                            icon: Icons.calendar_view_week_rounded,
                            label: medication.scheduleDaysLabel,
                          ),
                          _MedicationMetadata(
                            icon: medication.isCompleted
                                ? Icons.task_alt_rounded
                                : active
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_outline_rounded,
                            label: medication.statusLabel,
                            active: active,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(top: 9),
                  child: Icon(
                    Icons.chevron_right_rounded,
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

class _MedicationMetadata extends StatelessWidget {
  const _MedicationMetadata({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryContainer : AppColors.muted,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: active
                ? AppColors.primaryContainerForeground
                : AppColors.secondaryText,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              fontWeight: FontWeight.w600,
              color: active
                  ? AppColors.primaryContainerForeground
                  : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationLoadingContent extends StatelessWidget {
  const _MedicationLoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Your medications',
          subtitle: 'Loading your saved medication schedule',
        ),
        SizedBox(height: 12),
        AppSkeleton(width: 240, height: 42, borderRadius: 10),
        SizedBox(height: 22),
        AppSkeleton(width: 174, height: 22, borderRadius: 7),
        SizedBox(height: 12),
        AppCardSkeleton(lines: 3),
        SizedBox(height: 10),
        AppCardSkeleton(lines: 3),
        SizedBox(height: 10),
        AppCardSkeleton(lines: 3),
      ],
    );
  }
}

class _MedicationErrorCard extends StatelessWidget {
  const _MedicationErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      title: 'Could not load medications',
      message: 'Check your connection, then try again.',
      icon: Icons.cloud_off_outlined,
      actionLabel: 'Try again',
      actionIcon: Icons.refresh_rounded,
      onAction: onRetry,
    );
  }
}

String _occurrenceKey(MedicationDoseOccurrence occurrence) =>
    '${occurrence.medication.id}|${occurrence.scheduledFor.toUtc().toIso8601String()}';

String _dateKey(DateTime instant) {
  final wallClock = MedicationScheduleEngine.toPhilippineWallClock(instant);
  return '${wallClock.year}-${wallClock.month}-${wallClock.day}';
}

bool _samePhilippineDate(DateTime first, DateTime second) =>
    _dateKey(first) == _dateKey(second);

String _philippineTimeLabel(DateTime instant) {
  final wallClock = MedicationScheduleEngine.toPhilippineWallClock(instant);
  final hour = wallClock.hour;
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$displayHour:${wallClock.minute.toString().padLeft(2, '0')} '
      '${hour >= 12 ? 'PM' : 'AM'}';
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
