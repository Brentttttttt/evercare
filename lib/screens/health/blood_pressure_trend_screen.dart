import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/blood_pressure_widgets.dart';

class BloodPressureTrendScreen extends StatefulWidget {
  const BloodPressureTrendScreen({super.key});

  @override
  State<BloodPressureTrendScreen> createState() =>
      _BloodPressureTrendScreenState();
}

class _BloodPressureTrendScreenState extends State<BloodPressureTrendScreen> {
  int _period = 0;

  static const _datasets = [
    (
      systolic: <double>[126, 121, 124, 118, 120, 119, 120],
      diastolic: <double>[84, 79, 82, 78, 80, 79, 80],
      pulse: <double>[75, 71, 74, 70, 72, 71, 72],
      labels: <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    ),
    (
      systolic: <double>[124, 122, 121, 120, 119, 121, 120],
      diastolic: <double>[82, 81, 80, 79, 78, 80, 80],
      pulse: <double>[74, 73, 72, 71, 70, 72, 72],
      labels: <String>['1', '5', '10', '15', '20', '25', '30'],
    ),
    (
      systolic: <double>[126, 124, 123, 121, 120, 119, 120],
      diastolic: <double>[84, 82, 82, 81, 80, 79, 80],
      pulse: <double>[75, 74, 73, 72, 72, 71, 72],
      labels: <String>['May', '', 'Jun', '', 'Jul', '', 'Now'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final data = _datasets[_period];
    return DetailPage(
      title: 'Blood Pressure Trend',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('7 Days')),
                ButtonSegment(value: 1, label: Text('30 Days')),
                ButtonSegment(value: 2, label: Text('3 Months')),
              ],
              selected: {_period},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => _period = value.first),
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: BloodPressureTrendChart(
              systolic: data.systolic,
              diastolic: data.diastolic,
              pulse: data.pulse,
              labels: data.labels,
              height: 210,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _TrendValue(
                    width: width,
                    label: 'Weekly average',
                    value: '120/80',
                    unit: 'mmHg',
                    color: AppColors.primaryGreen,
                  ),
                  _TrendValue(
                    width: width,
                    label: 'Monthly average',
                    value: '121/80',
                    unit: 'mmHg',
                    color: AppColors.blue,
                  ),
                  _TrendValue(
                    width: width,
                    label: 'Average pulse',
                    value: '72',
                    unit: 'BPM',
                    color: AppColors.warning,
                  ),
                  _TrendValue(
                    width: width,
                    label: 'Measurements',
                    value: '7',
                    unit: 'this week',
                    color: AppColors.purple,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const AppCard(
            child: Column(
              children: [
                LabeledValue(
                  label: 'Highest sample reading',
                  value: '126/84 mmHg · Pulse 75 BPM',
                  icon: Icons.north_east_rounded,
                ),
                Divider(),
                LabeledValue(
                  label: 'Lowest sample reading',
                  value: '118/78 mmHg · Pulse 70 BPM',
                  icon: Icons.south_east_rounded,
                ),
                Divider(),
                LabeledValue(
                  label: 'Data source',
                  value: MockData.deviceName,
                  icon: Icons.bluetooth_connected_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'All trend lines and averages are hardcoded visual samples. '
            'No medical calculation or stored data is used.',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _TrendValue extends StatelessWidget {
  const _TrendValue({
    required this.width,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 12),
            Text(label, style: AppTextStyles.label),
            const SizedBox(height: 5),
            Text(value, style: AppTextStyles.sectionTitle),
            Text(unit, style: AppTextStyles.small),
          ],
        ),
      ),
    );
  }
}
