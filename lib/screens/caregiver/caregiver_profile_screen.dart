import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class CaregiverProfileScreen extends StatefulWidget {
  const CaregiverProfileScreen({super.key, this.caregiver});

  final Map<String, String>? caregiver;

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  bool _healthRecords = true;
  bool _medications = true;
  bool _emergencyAlerts = true;
  bool _appointments = true;

  @override
  Widget build(BuildContext context) {
    final caregiver = widget.caregiver ?? MockData.caregivers.first;
    final initials = caregiver['name']!
        .split(' ')
        .map((part) => part[0])
        .join();
    return DetailPage(
      title: 'Caregiver Profile',
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 43,
                  backgroundColor: AppColors.lightGreen,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(caregiver['name']!, style: AppTextStyles.pageTitle),
                const SizedBox(height: 4),
                Text(
                  caregiver['relationship']!,
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 16),
                LabeledValue(
                  label: 'Phone number',
                  value: caregiver['phone']!,
                  icon: Icons.phone_outlined,
                ),
                const Divider(),
                LabeledValue(
                  label: 'Email address',
                  value: caregiver['email']!,
                  icon: Icons.email_outlined,
                ),
                const Divider(),
                const LabeledValue(
                  label: 'Emergency contact',
                  value: 'Enabled',
                  icon: Icons.contact_emergency_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Shared Permissions',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('View blood-pressure records'),
                  subtitle: const Text('Latest measurements and history'),
                  value: _healthRecords,
                  onChanged: (value) => setState(() => _healthRecords = value),
                ),
                SwitchListTile(
                  title: const Text('View medications'),
                  subtitle: const Text('Medicine names and schedules'),
                  value: _medications,
                  onChanged: (value) => setState(() => _medications = value),
                ),
                SwitchListTile(
                  title: const Text('Receive emergency alerts'),
                  subtitle: const Text('Visual preference only'),
                  value: _emergencyAlerts,
                  onChanged: (value) =>
                      setState(() => _emergencyAlerts = value),
                ),
                SwitchListTile(
                  title: const Text('View appointments'),
                  subtitle: const Text('Upcoming clinic visits'),
                  value: _appointments,
                  onChanged: (value) => setState(() => _appointments = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Changes are shown on this screen only and are not saved.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}
