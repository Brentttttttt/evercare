import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_page.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'About EverCare',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Semantics(
              header: true,
              child: Column(
                children: [
                  const EverCareLogo(size: 68),
                  const SizedBox(height: 14),
                  Text(
                    'Your Health. Our Care.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Thoughtful tools for everyday caregiving.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMuted,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Version 0.1.0',
                      style: AppTextStyles.small,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AboutIcon(icon: Icons.favorite_outline_rounded),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Designed for clearer care',
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 13),
                Text(
                  'EverCare is an accessible care interface designed to help '
                  'older adults and trusted caregivers keep blood-pressure '
                  'readings, medicines, and appointments organized and easy '
                  'to understand.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AboutIcon(icon: Icons.public_rounded),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Supporting well-being for all ages',
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                    SizedBox(width: 10),
                    _SdgBadge(),
                  ],
                ),
                SizedBox(height: 13),
                Text(
                  'EverCare reflects Sustainable Development Goal 3 by '
                  'promoting healthy lives and well-being through an inclusive, '
                  'elderly-friendly design.',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            color: AppColors.warningContainer.withValues(alpha: .55),
            borderColor: AppColors.warning.withValues(alpha: .28),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.warning,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health information notice',
                        style: AppTextStyles.cardTitle,
                      ),
                      SizedBox(height: 5),
                      Text(
                        'EverCare helps organize personal care information. It '
                        'does not provide medical diagnoses, verify readings, '
                        'or replace advice from qualified healthcare '
                        'professionals.',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('© 2026 EverCare', style: AppTextStyles.small),
        ],
      ),
    );
  }
}

class _AboutIcon extends StatelessWidget {
  const _AboutIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: .1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 21),
    );
  }
}

class _SdgBadge extends StatelessWidget {
  const _SdgBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'SDG 3',
        style: AppTextStyles.small.copyWith(
          color: AppColors.primaryContainerForeground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
