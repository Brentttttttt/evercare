import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/mock_medication.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/medication_card.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  int _tab = 0;

  void _openMedication(MockMedication medication) {
    Navigator.pushNamed(
      context,
      AppRoutes.medicationDetails,
      arguments: medication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 108),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CarePhotoBanner(
                assetPath: 'assets/images/medication_support.png',
                semanticLabel:
                    'A caregiver helping an elderly woman organize medicines at home',
                title: 'Medication support, made simple',
                subtitle:
                    'A clear daily routine helps every dose feel manageable.',
                height: 172,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Today')),
                    ButtonSegment(value: 1, label: Text('All')),
                    ButtonSegment(value: 2, label: Text('History')),
                  ],
                  selected: {_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      setState(() => _tab = value.first),
                ),
              ),
              const SizedBox(height: 20),
              if (_tab == 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Monday, July 20',
                        style: AppTextStyles.sectionTitle,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        '1 of 3 taken',
                        style: TextStyle(
                          color: AppColors.darkGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...MockData.medications.map(
                  (medicine) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MedicationCard(
                      medication: medicine,
                      onTap: () => _openMedication(medicine),
                    ),
                  ),
                ),
              ] else if (_tab == 1) ...[
                const Text(
                  'All Medications',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 14),
                ...MockData.medications.map(
                  (medicine) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MedicationCard(
                      medication: medicine,
                      onTap: () => _openMedication(medicine),
                    ),
                  ),
                ),
              ] else
                const EmptyStateCard(
                  title: 'No recent changes',
                  message:
                      'A sample medication intake history appears inside each medicine’s details.',
                  icon: Icons.history_rounded,
                ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.addMedication),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Medication'),
          ),
        ),
      ],
    );
  }
}
