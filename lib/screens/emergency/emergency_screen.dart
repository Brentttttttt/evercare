import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Emergency',
      child: Column(
        children: [
          const Text(
            'For a real emergency, use your phone’s emergency services.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 22),
          Semantics(
            button: true,
            label: 'Tap for emergency preview',
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () => showMockDialog(
                context,
                title: 'Emergency action preview',
                message:
                    'No call or alert was sent. This button is a static UI preview only.',
                actionLabel: 'Close',
                icon: Icons.sos_rounded,
              ),
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger,
                  border: Border.all(color: const Color(0xFFFFD9D5), width: 13),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: .24),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sos_rounded, color: Colors.white, size: 64),
                    SizedBox(height: 5),
                    Text(
                      'Tap for Emergency',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _EmergencyAction(
            icon: Icons.my_location_outlined,
            title: 'Share My Location',
            subtitle: 'Preview location-sharing confirmation',
            onTap: () => showMockDialog(
              context,
              title: 'Share your location?',
              message:
                  'EverCare has not accessed or shared your location. Location services are not included in this prototype.',
              icon: Icons.location_off_outlined,
            ),
          ),
          const SizedBox(height: 12),
          _EmergencyAction(
            icon: Icons.call_outlined,
            title: 'Call Emergency Contact',
            subtitle: 'Ana Santos · Daughter',
            onTap: () => showMockDialog(
              context,
              title: 'Call Ana Santos?',
              message:
                  'No phone call has been placed. This is a static confirmation preview.',
              icon: Icons.phone_paused_outlined,
            ),
          ),
          const SizedBox(height: 12),
          _EmergencyAction(
            icon: Icons.medical_information_outlined,
            title: 'Medical Information',
            subtitle: 'View the emergency health card',
            onTap: () => Navigator.pushNamed(context, AppRoutes.medicalInfo),
          ),
          const SizedBox(height: 12),
          _EmergencyAction(
            icon: Icons.local_hospital_outlined,
            title: 'Nearest Hospitals',
            subtitle: 'View sample nearby facilities',
            onTap: () => showMockDialog(
              context,
              title: 'Nearby hospitals',
              message:
                  'Guiguinto Community Hospital\nBulacan Medical Center\nSt. Mary’s Hospital\n\nThis is sample information. GPS is not being used.',
              icon: Icons.local_hospital_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyAction extends StatelessWidget {
  const _EmergencyAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDEC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.danger),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.secondaryText,
          ),
        ],
      ),
    );
  }
}
