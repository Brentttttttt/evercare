import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state_card.dart';

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
            'Real blood-pressure readings received from the selected monitor will '
            'appear here after secure history storage is added.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 18),
          const EmptyStateCard(
            title: 'No real monitor readings have been saved yet.',
            message:
                'Completed BLE readings are currently kept only for the active '
                'app session. EverCare is not saving blood-pressure readings to '
                'a database in this phase.',
            icon: Icons.history_toggle_off_rounded,
          ),
        ],
      ),
    );
  }
}
