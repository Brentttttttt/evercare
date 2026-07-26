import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_page.dart';

class MedicalInformationScreen extends StatelessWidget {
  const MedicalInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = MockData.profile;
    return DetailPage(
      title: 'Medical Information',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.danger, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryText.withValues(alpha: .08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.medical_information_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      'EMERGENCY HEALTH CARD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeader(
                    title: profile['name']!,
                    subtitle: 'Age ${profile['age']} · Senior Citizen',
                    trailing: const CircleAvatar(
                      radius: 29,
                      backgroundColor: AppColors.lightGreen,
                      child: Text(
                        'MS',
                        style: TextStyle(
                          color: AppColors.darkGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MedicalRow(
                    label: 'Blood type',
                    value: profile['bloodType']!,
                  ),
                  const _MedicalRow(
                    label: 'Allergies',
                    value: 'Penicillin, shellfish',
                  ),
                  const _MedicalRow(
                    label: 'Medical conditions',
                    value: 'Hypertension, Type 2 diabetes',
                  ),
                  const _MedicalRow(
                    label: 'Current medications',
                    value: 'Amlodipine, Metformin, Atorvastatin',
                  ),
                  const _MedicalRow(
                    label: 'Emergency contact',
                    value: 'Ana Santos · +63 917 555 0182',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sample information for UI demonstration only.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalRow extends StatelessWidget {
  const _MedicalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
