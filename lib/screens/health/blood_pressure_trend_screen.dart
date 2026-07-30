import 'package:flutter/material.dart';

import '../../models/blood_pressure_reading.dart';
import '../../repositories/blood_pressure_repository.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/blood_pressure_widgets.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';

class BloodPressureTrendScreen extends StatefulWidget {
  const BloodPressureTrendScreen({super.key});

  @override
  State<BloodPressureTrendScreen> createState() =>
      _BloodPressureTrendScreenState();
}

class _BloodPressureTrendScreenState extends State<BloodPressureTrendScreen> {
  Future<List<BloodPressureReading>>? _readings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readings ??= _load();
  }

  Future<List<BloodPressureReading>> _load() async {
    final client = EverCareBackendScope.maybeClient(context);
    if (client == null || client.auth.currentUser == null) return const [];
    return BloodPressureRepository(client).list(limit: 30);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn =
        EverCareBackendScope.maybeClient(context)?.auth.currentUser != null;
    return DetailPage(
      title: 'Blood Pressure Trend',
      child: FutureBuilder<List<BloodPressureReading>>(
        future: _readings,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyStateCard(
              title: 'Could not load your trend',
              message:
                  '${snapshot.error}\n\nCheck your connection and try again.',
              icon: Icons.cloud_off_rounded,
            );
          }
          final newestFirst = snapshot.data ?? const <BloodPressureReading>[];
          if (newestFirst.length < 2) {
            return EmptyStateCard(
              title: signedIn
                  ? 'At least two saved readings are needed'
                  : 'Sign in to view your trend',
              message: signedIn
                  ? 'Save real BLE or manual readings to build a personal trend. No sample readings are inserted.'
                  : 'Your private trend is available after you sign in.',
              icon: Icons.show_chart_rounded,
            );
          }
          final readings = newestFirst.reversed.toList(growable: false);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This chart visualizes your saved measurements. It does not provide a diagnosis or medical verification.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 18),
              AppCard(
                child: BloodPressureTrendChart(
                  systolic: readings
                      .map((reading) => reading.systolic.toDouble())
                      .toList(growable: false),
                  diastolic: readings
                      .map((reading) => reading.diastolic.toDouble())
                      .toList(growable: false),
                  pulse: readings
                      .map((reading) => reading.pulse.toDouble())
                      .toList(growable: false),
                  labels: readings
                      .map(
                        (reading) =>
                            '${reading.measuredAt.month}/${reading.measuredAt.day}',
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${readings.length} saved measurements shown',
                style: AppTextStyles.small,
              ),
            ],
          );
        },
      ),
    );
  }
}
