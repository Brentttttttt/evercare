import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/medication.dart';
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
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  int _tab = 0;
  SupabaseClient? _client;
  String? _userId;
  MedicationRepository? _repository;
  Future<List<Medication>>? _medications;

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
      _medications = _repository!.fetchAll();
    } else {
      _repository = null;
      _medications = null;
    }
  }

  void _reload() {
    final repository = _repository;
    if (repository == null) return;
    setState(() => _medications = repository.fetchAll());
  }

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
                FutureBuilder<List<Medication>>(
                  future: _medications,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _MedicationLoadingContent();
                    }
                    if (snapshot.hasError) {
                      return _MedicationErrorCard(onRetry: _reload);
                    }
                    return _MedicationContent(
                      medications: snapshot.data ?? const [],
                      selected: _tab,
                      onSelected: (value) => setState(() => _tab = value),
                      onOpen: _openMedication,
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
    required this.medications,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
  });

  final List<Medication> medications;
  final int selected;
  final ValueChanged<int> onSelected;
  final ValueChanged<Medication> onOpen;

  @override
  Widget build(BuildContext context) {
    final active = medications.where((item) => item.isActive).toList();
    final inactive = medications.where((item) => !item.isActive).toList();
    final visible = switch (selected) {
      0 => active,
      1 => medications,
      _ => inactive,
    };
    final selectedLabel = switch (selected) {
      0 => 'Active medications',
      1 => 'All medications',
      _ => 'Inactive medications',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Your medications',
          subtitle:
              '${medications.length} saved • ${active.length} currently active',
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
              0 => 'No active medications',
              1 => 'No medications yet',
              _ => 'No inactive medications',
            },
            message: selected == 1
                ? 'Add a medication to build your personal list.'
                : 'Medications in this category will appear here.',
            icon: selected == 2
                ? Icons.pause_circle_outline_rounded
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

class _MedicationStatusFilter extends StatelessWidget {
  const _MedicationStatusFilter({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  static const _labels = ['Active', 'All', 'Inactive'];

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
    final active = medication.isActive;
    final details = [
      medication.dosage,
      medication.frequency,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
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
                    color: active
                        ? AppColors.primaryContainer
                        : AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    size: 21,
                    color: active ? AppColors.primaryGreen : AppColors.warning,
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
                            icon: active
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
