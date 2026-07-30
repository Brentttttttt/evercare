import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state_card.dart';

class BloodPressureTrendScreen extends StatelessWidget {
  const BloodPressureTrendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Blood Pressure Trend',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EverCare will build trends only from real monitor readings that '
            'have been intentionally saved.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 18),
          const EmptyStateCard(
            title: 'Blood-pressure trends are not available yet.',
            message:
                'Real readings are currently session-only and are not stored in '
                'a database. Trends, averages, and measurement counts will remain '
                'empty until reading history is intentionally persisted.',
            icon: Icons.show_chart_rounded,
          ),
        ],
      ),
    );
  }
}
