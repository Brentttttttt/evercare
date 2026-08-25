import 'package:flutter/material.dart';

import '../../models/blood_pressure_assessment.dart';
import '../../models/blood_pressure_reading.dart';
import '../../repositories/blood_pressure_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/blood_pressure_widgets.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/section_header.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({super.key});

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  Future<List<BloodPressureReading>>? _readings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readings ??= _load();
  }

  Future<List<BloodPressureReading>> _load() async {
    final client = EverCareBackendScope.maybeClient(context);
    if (client == null || client.auth.currentUser == null) return const [];
    final records = await BloodPressureRepository(client).list(limit: 100);
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return records
        .where((record) => !record.measuredAt.isBefore(cutoff))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn =
        EverCareBackendScope.maybeClient(context)?.auth.currentUser != null;
    return DetailPage(
      title: 'Blood Pressure Report',
      child: FutureBuilder<List<BloodPressureReading>>(
        future: _readings,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyStateCard(
              title: 'Could not load the report',
              message:
                  '${snapshot.error}\n\nCheck your connection and try again.',
              icon: Icons.cloud_off_rounded,
            );
          }
          final readings = snapshot.data ?? const <BloodPressureReading>[];
          if (readings.isEmpty) {
            return EmptyStateCard(
              title: signedIn
                  ? 'No readings saved in the last 7 days'
                  : 'Sign in to view your report',
              message: signedIn
                  ? 'The report is created only from real readings you save. EverCare does not insert sample health records.'
                  : 'Your private health report is available after you sign in.',
              icon: Icons.monitor_heart_outlined,
            );
          }
          return _ReportContent(readings: readings);
        },
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.readings});

  final List<BloodPressureReading> readings;

  @override
  Widget build(BuildContext context) {
    final chronological = readings.reversed.toList(growable: false);
    final averageSystolic = _average(readings.map((item) => item.systolic));
    final averageDiastolic = _average(readings.map((item) => item.diastolic));
    final averagePulse = _average(readings.map((item) => item.pulse));
    final newest = readings.first;
    final newestAssessment = BloodPressureAssessment.fromValues(
      systolic: newest.systolic,
      diastolic: newest.diastolic,
      pulse: newest.pulse,
    );
    final newestRangeColor = bloodPressureRangeColor(newestAssessment);
    final bleCount = readings.where((item) => item.source == 'ble').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          color: AppColors.darkGreen,
          borderColor: AppColors.darkGreen,
          child: const Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 34),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAST 7 DAYS',
                      style: TextStyle(
                        color: Color(0xFFCDE7D1),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .8,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Your saved BP summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          color: newestRangeColor.withValues(alpha: .08),
          borderColor: newestRangeColor.withValues(alpha: .24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LATEST SAVED READING', style: AppTextStyles.eyebrow),
              const SizedBox(height: 8),
              Text(
                newestAssessment.friendlyStatus,
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 3),
              Text(
                newestAssessment.label,
                style: AppTextStyles.bodyMuted.copyWith(
                  color: newestRangeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${newest.systolic}/${newest.diastolic} mmHg · Pulse ${newest.pulse} BPM',
                style: AppTextStyles.cardTitle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Measured summary'),
        const SizedBox(height: 11),
        AppCard(
          child: Column(
            children: [
              _ReportValue(
                icon: Icons.arrow_upward_rounded,
                label: 'Average upper number (systolic)',
                value: '$averageSystolic mmHg',
                color: AppColors.danger,
              ),
              const Divider(),
              _ReportValue(
                icon: Icons.arrow_downward_rounded,
                label: 'Average lower number (diastolic)',
                value: '$averageDiastolic mmHg',
                color: AppColors.blue,
              ),
              const Divider(),
              _ReportValue(
                icon: Icons.favorite_outline_rounded,
                label: 'Average recorded pulse',
                value: '$averagePulse BPM',
                color: AppColors.warning,
              ),
              const Divider(),
              _ReportValue(
                icon: Icons.fact_check_outlined,
                label: 'Saved measurements',
                value: '${readings.length}',
                color: AppColors.purple,
              ),
            ],
          ),
        ),
        if (chronological.length >= 2) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Recorded trend'),
          const SizedBox(height: 11),
          AppCard(
            child: BloodPressureTrendChart(
              systolic: chronological
                  .map((item) => item.systolic.toDouble())
                  .toList(growable: false),
              diastolic: chronological
                  .map((item) => item.diastolic.toDouble())
                  .toList(growable: false),
              pulse: chronological
                  .map((item) => item.pulse.toDouble())
                  .toList(growable: false),
              labels: chronological
                  .map(
                    (item) => '${item.measuredAt.month}/${item.measuredAt.day}',
                  )
                  .toList(growable: false),
              height: 175,
            ),
          ),
        ],
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            children: [
              LabeledValue(
                label: 'Bluetooth measurements',
                value: '$bleCount of ${readings.length}',
                icon: Icons.bluetooth_connected_rounded,
              ),
              const Divider(),
              LabeledValue(
                label: 'Latest device',
                value: newest.monitorName ?? newest.sourceLabel,
                icon: Icons.monitor_heart_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'This report summarizes your saved measurements only and is not a '
          'medical diagnosis. Verification status is shown with each saved '
          'reading in Blood Pressure History.',
          style: AppTextStyles.bodyMuted,
        ),
      ],
    );
  }

  int _average(Iterable<int> values) {
    final list = values.toList(growable: false);
    return (list.reduce((a, b) => a + b) / list.length).round();
  }
}

class _ReportValue extends StatelessWidget {
  const _ReportValue({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackText =
            constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: stackText
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: AppTextStyles.body),
                          const SizedBox(height: 3),
                          Text(value, style: AppTextStyles.cardTitle),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(label, style: AppTextStyles.body),
                          ),
                          const SizedBox(width: 10),
                          Text(value, style: AppTextStyles.cardTitle),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
