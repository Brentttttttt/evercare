import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/blood_pressure_widgets.dart';
import '../../widgets/section_header.dart';

class HealthReportScreen extends StatelessWidget {
  const HealthReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Blood Pressure Report',
      actions: [
        IconButton(
          tooltip: 'Report information',
          onPressed: () => showMockDialog(
            context,
            title: 'Static blood-pressure report',
            message:
                'Every reading, average, and trend on this page is hardcoded '
                'mock content. No data is loaded, stored, or calculated.',
            icon: Icons.info_outline_rounded,
          ),
          icon: const Icon(Icons.info_outline_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCard(
            color: AppColors.darkGreen,
            borderColor: AppColors.darkGreen,
            child: Row(
              children: [
                Icon(
                  Icons.monitor_heart_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JULY 14–20, 2026',
                        style: TextStyle(
                          color: Color(0xFFCDE7D1),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .8,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Maria’s weekly BP summary',
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
          const SizedBox(height: 22),
          const SectionHeader(title: 'Weekly summary'),
          const SizedBox(height: 11),
          const AppCard(
            child: Column(
              children: [
                _ReportValue(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Average systolic pressure',
                  value: '120 mmHg',
                  color: AppColors.danger,
                ),
                Divider(),
                _ReportValue(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Average diastolic pressure',
                  value: '80 mmHg',
                  color: AppColors.blue,
                ),
                Divider(),
                _ReportValue(
                  icon: Icons.favorite_outline_rounded,
                  label: 'Average pulse during BP',
                  value: '72 BPM',
                  color: AppColors.warning,
                ),
                Divider(),
                _ReportValue(
                  icon: Icons.north_east_rounded,
                  label: 'Highest reading',
                  value: '126/84',
                  color: AppColors.danger,
                ),
                Divider(),
                _ReportValue(
                  icon: Icons.south_east_rounded,
                  label: 'Lowest reading',
                  value: '118/78',
                  color: AppColors.primaryGreen,
                ),
                Divider(),
                _ReportValue(
                  icon: Icons.fact_check_outlined,
                  label: 'Measurements this week',
                  value: '7',
                  color: AppColors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Blood pressure trend'),
          const SizedBox(height: 11),
          const AppCard(
            child: BloodPressureTrendChart(
              systolic: [126, 121, 124, 118, 120, 119, 120],
              diastolic: [84, 79, 82, 78, 80, 79, 80],
              pulse: [75, 71, 74, 70, 72, 71, 72],
              labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
              height: 175,
            ),
          ),
          const SizedBox(height: 18),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Measurement consistency',
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                    Text('7 of 7 days', style: AppTextStyles.label),
                  ],
                ),
                SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 1,
                  minHeight: 9,
                  borderRadius: BorderRadius.all(Radius.circular(9)),
                  color: AppColors.primaryGreen,
                  backgroundColor: AppColors.lightGreen,
                ),
                SizedBox(height: 18),
                Divider(),
                SizedBox(height: 18),
                LabeledValue(
                  label: 'Device',
                  value: MockData.deviceName,
                  icon: Icons.monitor_heart_outlined,
                ),
                LabeledValue(
                  label: 'Data source',
                  value: MockData.syncMethod,
                  icon: Icons.bluetooth_connected_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Static UI classifications and averages only. This report does '
            'not provide medical advice.',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
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
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(value, style: AppTextStyles.cardTitle),
        ],
      ),
    );
  }
}
