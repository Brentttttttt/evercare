import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/medication.dart';
import '../../repositories/medication_repository.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/medication_card.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 108),
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
              const SizedBox(height: 18),
              if (_repository == null)
                _MedicationAccessCard(backendAvailable: _client != null)
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Active')),
                      ButtonSegment(value: 1, label: Text('All')),
                      ButtonSegment(value: 2, label: Text('Inactive')),
                    ],
                    selected: {_tab},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        setState(() => _tab = value.first),
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Medication>>(
                  future: _medications,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _MedicationLoadingCard();
                    }
                    if (snapshot.hasError) {
                      return _MedicationErrorCard(onRetry: _reload);
                    }
                    final all = snapshot.data ?? const <Medication>[];
                    final visible = switch (_tab) {
                      0 => all.where((item) => item.isActive).toList(),
                      1 => all,
                      _ => all.where((item) => !item.isActive).toList(),
                    };
                    if (visible.isEmpty) {
                      return EmptyStateCard(
                        title: _tab == 0
                            ? 'No active medications'
                            : _tab == 2
                            ? 'No inactive medications'
                            : 'No medications yet',
                        message: _tab == 1
                            ? 'Add a medication to build your personal list.'
                            : 'Medications in this category will appear here.',
                        icon: Icons.medication_outlined,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tab == 0
                              ? 'Active medications'
                              : _tab == 1
                              ? 'All medications'
                              : 'Inactive medications',
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 14),
                        ...visible.map(
                          (medicine) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MedicationCard(
                              medication: medicine,
                              onTap: () => _openMedication(medicine),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: FilledButton.icon(
            onPressed: _addMedication,
            icon: Icon(
              _repository == null ? Icons.login_rounded : Icons.add_rounded,
            ),
            label: Text(
              _repository == null ? 'Sign in to continue' : 'Add Medication',
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

class _MedicationLoadingCard extends StatelessWidget {
  const _MedicationLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 42),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _MedicationErrorCard extends StatelessWidget {
  const _MedicationErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const EmptyStateCard(
          title: 'Could not load medications',
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
