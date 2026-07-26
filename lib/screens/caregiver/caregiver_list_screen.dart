import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class CaregiverListScreen extends StatelessWidget {
  const CaregiverListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Trusted People',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Family members and caregivers who can view shared information.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 18),
          ...MockData.caregivers.map(
            (caregiver) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.caregiverProfile,
                  arguments: caregiver,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.lightGreen,
                      child: Text(
                        caregiver['name']!
                            .split(' ')
                            .map((part) => part[0])
                            .join(),
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
                            caregiver['name']!,
                            style: AppTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            caregiver['relationship']!,
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
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: () => showMockDialog(
              context,
              title: 'Add a trusted person',
              message:
                  'A caregiver invitation form would open here. This prototype does not send invitations.',
              icon: Icons.person_add_alt_1_outlined,
            ),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Add Caregiver'),
          ),
        ],
      ),
    );
  }
}
