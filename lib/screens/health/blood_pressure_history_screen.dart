import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/blood_pressure_widgets.dart';

class BloodPressureHistoryScreen extends StatelessWidget {
  const BloodPressureHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Blood Pressure History',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blood-pressure readings with pulse measured during each reading.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 18),
          ...MockData.bloodPressureRecords.map(
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
        ],
      ),
    );
  }
}
