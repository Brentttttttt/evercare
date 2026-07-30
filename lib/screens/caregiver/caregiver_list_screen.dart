import 'package:flutter/material.dart';

import '../../models/caregiver_relationship.dart';
import '../../repositories/caregiver_repository.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';

class CaregiverListScreen extends StatefulWidget {
  const CaregiverListScreen({super.key});

  @override
  State<CaregiverListScreen> createState() => _CaregiverListScreenState();
}

class _CaregiverListScreenState extends State<CaregiverListScreen> {
  CaregiverRepository? _repository;
  List<CaregiverRelationship> _relationships = const [];
  bool _initialized = false;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final client = EverCareBackendScope.maybeClient(context);
    if (client?.auth.currentUser == null) {
      _loading = false;
      return;
    }
    _repository = CaregiverRepository(client!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Trusted People',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caregiver relationships connected to your EverCare account.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(36),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_repository == null)
            const EmptyStateCard(
              title: 'Sign in to see trusted people',
              message:
                  'Caregiver relationships will appear here after you sign in.',
              icon: Icons.lock_outline_rounded,
            )
          else if (_error != null)
            _CaregiverError(message: _error!, onRetry: _load)
          else if (_relationships.isEmpty)
            const EmptyStateCard(
              title: 'No caregivers connected',
              message:
                  'You do not have a caregiver relationship in EverCare yet.',
              icon: Icons.people_outline_rounded,
            )
          else
            ..._relationships.map(
              (caregiver) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => _openProfile(caregiver),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.lightGreen,
                        child: Text(
                          _initials(caregiver.name),
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              caregiver.name.isEmpty
                                  ? 'Caregiver profile'
                                  : caregiver.name,
                              style: AppTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${caregiver.relationshipLabel} · ${_status(caregiver.status)}',
                              style: AppTextStyles.bodyMuted,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.secondaryText,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          const AppCard(
            color: Color(0xFFF5FAF7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primaryGreen),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Caregiver invitations are not enabled yet. EverCare only displays relationships already stored in your account.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final relationships = await _repository!.fetchRelationships();
      if (!mounted) return;
      setState(() {
        _relationships = relationships;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'EverCare could not load trusted people. Please try again.';
      });
    }
  }

  Future<void> _openProfile(CaregiverRelationship caregiver) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.caregiverProfile,
      arguments: caregiver.toRouteArguments(),
    );
    if (changed == true && mounted) await _load();
  }

  String _initials(String name) {
    final value = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return value.isEmpty ? 'EC' : value;
  }

  String _status(String value) {
    if (value.isEmpty) return 'Unknown';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _CaregiverError extends StatelessWidget {
  const _CaregiverError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: AppColors.danger,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
