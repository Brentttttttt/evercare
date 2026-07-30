import 'package:flutter/material.dart';

import '../../models/blood_pressure_reading.dart';
import '../../repositories/blood_pressure_repository.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/blood_pressure_widgets.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';
import 'blood_pressure_record_screen.dart';

class BloodPressureHistoryScreen extends StatefulWidget {
  const BloodPressureHistoryScreen({super.key});

  @override
  State<BloodPressureHistoryScreen> createState() =>
      _BloodPressureHistoryScreenState();
}

class _BloodPressureHistoryScreenState
    extends State<BloodPressureHistoryScreen> {
  Future<List<BloodPressureReading>>? _readings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readings ??= _load();
  }

  Future<List<BloodPressureReading>> _load() async {
    final client = EverCareBackendScope.maybeClient(context);
    if (client == null || client.auth.currentUser == null) return const [];
    return BloodPressureRepository(client).list();
  }

  void _reload() => setState(() => _readings = _load());

  @override
  Widget build(BuildContext context) {
    final signedIn =
        EverCareBackendScope.maybeClient(context)?.auth.currentUser != null;
    return DetailPage(
      title: 'Blood Pressure History',
      child: FutureBuilder<List<BloodPressureReading>>(
        future: _readings,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _HistoryError(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final readings = snapshot.data ?? const <BloodPressureReading>[];
          if (readings.isEmpty) {
            return EmptyStateCard(
              title: signedIn
                  ? 'No saved blood-pressure readings'
                  : 'Sign in to view saved readings',
              message: signedIn
                  ? 'Save a completed BLE result or add a manual reading. EverCare never inserts sample health data.'
                  : 'Your private reading history is available after you sign in.',
              icon: Icons.history_toggle_off_rounded,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'These are user-saved measurements and are not medically verified.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 18),
              for (final reading in readings) ...[
                BloodPressureRecordCard(
                  record: reading,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            BloodPressureRecordScreen(record: reading),
                      ),
                    );
                    if (mounted) _reload();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EmptyStateCard(
          title: 'Could not load reading history',
          message: '$message\n\nCheck your connection, then try again.',
          icon: Icons.cloud_off_rounded,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
        ),
      ],
    );
  }
}
