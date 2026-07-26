import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/blood_pressure_widgets.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/section_header.dart';

class HealthOverviewScreen extends StatefulWidget {
  const HealthOverviewScreen({super.key});

  @override
  State<HealthOverviewScreen> createState() => _HealthOverviewScreenState();
}

class _HealthOverviewScreenState extends State<HealthOverviewScreen> {
  bool _connected = true;
  String _measurementState = 'Device Connected';

  static const _states = [
    'Device Not Connected',
    'Device Connected',
    'Waiting for Measurement',
    'Measurement in Progress',
    'Measurement Completed',
    'Synchronization Completed',
    'Synchronization Failed',
  ];

  @override
  Widget build(BuildContext context) {
    final latest = MockData.latestBloodPressure;
    final status = _statusContent(_measurementState);
    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CarePhotoBanner(
            assetPath: 'assets/images/bp_monitor_home.png',
            semanticLabel:
                'An elderly woman calmly using an upper-arm blood pressure monitor at home',
            title: 'Measure with confidence',
            subtitle: 'Keep your blood-pressure routine calm and consistent.',
            height: 170,
          ),
          const SizedBox(height: 20),
          _ConnectedDeviceCard(
            connected: _connected,
            onConnect: () =>
                Navigator.pushNamed(context, AppRoutes.deviceConnection),
            onDisconnect: () {
              setState(() {
                _connected = false;
                _measurementState = 'Device Not Connected';
              });
            },
            onViewInformation: () => showMockDialog(
              context,
              title: MockData.deviceName,
              message:
                  '${MockData.deviceType}\n\nModel: ${MockData.deviceModel}\n'
                  'Displayed sync method: ${MockData.syncMethod}\n\n'
                  'This is static device information. EverCare is not '
                  'communicating with Bluetooth hardware.',
              icon: Icons.info_outline_rounded,
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Latest reading'),
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.lightGreen,
            borderColor: AppColors.lightGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'TODAY · 8:45 AM',
                        style: AppTextStyles.eyebrow,
                      ),
                    ),
                    BloodPressureStatusBadge(status: latest.status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${latest.systolic} / ${latest.diastolic}',
                          style: AppTextStyles.metric.copyWith(fontSize: 37),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 7, bottom: 3),
                      child: Text('mmHg', style: AppTextStyles.label),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _ReadingValue(
                      label: 'Systolic',
                      value: '${latest.systolic}',
                      unit: 'mmHg',
                    ),
                    const _ReadingDivider(),
                    _ReadingValue(
                      label: 'Diastolic',
                      value: '${latest.diastolic}',
                      unit: 'mmHg',
                    ),
                    const _ReadingDivider(),
                    _ReadingValue(
                      label: 'Pulse',
                      value: '${latest.pulse}',
                      unit: 'BPM',
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(),
                ),
                LabeledValue(
                  label: 'Measured',
                  value: '${latest.dateLabel} · ${latest.timeLabel}',
                  icon: Icons.schedule_rounded,
                ),
                LabeledValue(
                  label: 'Source',
                  value: latest.deviceName,
                  icon: Icons.monitor_heart_outlined,
                ),
                LabeledValue(
                  label: 'Sync method',
                  value: latest.source,
                  icon: Icons.bluetooth_connected_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeader(title: 'Measurement status'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _measurementState,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Preview device state',
              prefixIcon: Icon(Icons.tune_rounded),
            ),
            items: _states
                .map(
                  (state) => DropdownMenuItem(value: state, child: Text(state)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _measurementState = value;
                _connected = value != 'Device Not Connected';
              });
            },
          ),
          const SizedBox(height: 12),
          AppCard(
            color: status.color.withValues(alpha: .08),
            borderColor: status.color.withValues(alpha: .20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(status.icon, color: status.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(status.title, style: AppTextStyles.cardTitle),
                      const SizedBox(height: 6),
                      Text(status.message, style: AppTextStyles.bodyMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'Recent readings',
            actionLabel: 'View all',
            onAction: () =>
                Navigator.pushNamed(context, AppRoutes.bloodPressureHistory),
          ),
          const SizedBox(height: 12),
          ...MockData.bloodPressureRecords
              .take(3)
              .map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BloodPressureRecordCard(
                    record: record,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.bloodPressureRecord,
                      arguments: record,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 14),
          SectionHeader(
            title: 'Blood pressure trend',
            actionLabel: 'Details',
            onAction: () =>
                Navigator.pushNamed(context, AppRoutes.bloodPressureTrend),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.bloodPressureTrend),
            child: const Column(
              children: [
                BloodPressureTrendChart(
                  systolic: [126, 121, 124, 118, 120],
                  diastolic: [84, 79, 82, 78, 80],
                  pulse: [75, 71, 74, 70, 72],
                  labels: ['16', '17', '18', '19', '20'],
                  height: 150,
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _AverageTile(
                        label: 'Weekly average',
                        value: '122/81',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _AverageTile(
                        label: 'Average pulse',
                        value: '72 BPM',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.manualRecord),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Enter Blood Pressure Manually'),
          ),
        ],
      ),
    );
  }

  _MeasurementStatus _statusContent(String state) {
    return switch (state) {
      'Device Not Connected' => const _MeasurementStatus(
        title: 'Device Not Connected',
        message: 'Open the connection page to preview connecting the YK-BPA1.',
        icon: Icons.bluetooth_disabled_rounded,
        color: AppColors.secondaryText,
      ),
      'Waiting for Measurement' => const _MeasurementStatus(
        title: 'Waiting for Measurement',
        message: 'Complete a blood-pressure measurement on the monitor.',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.blue,
      ),
      'Measurement in Progress' => const _MeasurementStatus(
        title: 'Measurement in Progress',
        message: 'Keep your arm still while the monitor completes its reading.',
        icon: Icons.monitor_heart_rounded,
        color: AppColors.warning,
      ),
      'Measurement Completed' => const _MeasurementStatus(
        title: 'Measurement Completed',
        message: 'The sample reading is ready to be synchronized.',
        icon: Icons.task_alt_rounded,
        color: AppColors.primaryGreen,
      ),
      'Synchronization Completed' => const _MeasurementStatus(
        title: 'Synchronization Completed',
        message: 'The sample reading has been displayed in EverCare.',
        icon: Icons.sync_rounded,
        color: AppColors.primaryGreen,
      ),
      'Synchronization Failed' => const _MeasurementStatus(
        title: 'Synchronization Failed',
        message:
            'Keep the device close and preview the connection steps again.',
        icon: Icons.sync_problem_rounded,
        color: AppColors.danger,
      ),
      _ => const _MeasurementStatus(
        title: 'Device Ready',
        message:
            'Place the cuff correctly around your upper arm and press '
            'Start on the monitor.',
        icon: Icons.check_circle_rounded,
        color: AppColors.primaryGreen,
      ),
    };
  }
}

class _ConnectedDeviceCard extends StatelessWidget {
  const _ConnectedDeviceCard({
    required this.connected,
    required this.onConnect,
    required this.onDisconnect,
    required this.onViewInformation,
  });

  final bool connected;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onViewInformation;

  @override
  Widget build(BuildContext context) {
    final statusColor = connected
        ? AppColors.primaryGreen
        : AppColors.secondaryText;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  connected
                      ? Icons.bluetooth_connected_rounded
                      : Icons.bluetooth_disabled_rounded,
                  color: statusColor,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(MockData.deviceName, style: AppTextStyles.cardTitle),
                    SizedBox(height: 5),
                    Text(MockData.deviceType, style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    connected ? 'Connected' : 'Not connected',
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 14.5,
                      color: statusColor,
                    ),
                  ),
                ),
                const Icon(
                  Icons.battery_5_bar_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 5),
                const Text('85%', style: AppTextStyles.label),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(
                Icons.sync_rounded,
                size: 18,
                color: AppColors.secondaryText,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Last synchronization: Today, 8:45 AM',
                  style: AppTextStyles.small,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onConnect,
            icon: const Icon(Icons.bluetooth_searching_rounded),
            label: const Text('Connect Device'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onDisconnect,
            icon: const Icon(Icons.link_off_rounded),
            label: const Text('Disconnect'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onViewInformation,
            icon: const Icon(Icons.info_outline_rounded),
            label: const Text('View Device Information'),
          ),
        ],
      ),
    );
  }
}

class _ReadingValue extends StatelessWidget {
  const _ReadingValue({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 5),
          Text(value, style: AppTextStyles.sectionTitle),
          Text(unit, style: AppTextStyles.small),
        ],
      ),
    );
  }
}

class _ReadingDivider extends StatelessWidget {
  const _ReadingDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.border,
    );
  }
}

class _AverageTile extends StatelessWidget {
  const _AverageTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.small),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.cardTitle),
        ],
      ),
    );
  }
}

class _MeasurementStatus {
  const _MeasurementStatus({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}
