import 'package:flutter/material.dart';

import '../../models/emergency_contact.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class EmergencyContactCard extends StatelessWidget {
  const EmergencyContactCard({
    required this.contact,
    required this.onCopyNumber,
    required this.onDetails,
    super.key,
  });

  final EmergencyContact contact;
  final VoidCallback onCopyNumber;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final accent = contact.isPrimary
        ? AppColors.danger
        : AppColors.primaryGreen;
    return AppCard(
      borderColor: contact.isPrimary
          ? AppColors.danger.withValues(alpha: .28)
          : AppColors.border,
      color: contact.isPrimary ? const Color(0xFFFFFBF7) : Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: contact.isPrimary ? 29 : 25,
                backgroundColor: accent.withValues(alpha: .12),
                foregroundColor: accent,
                child: Text(
                  contact.initials,
                  style: TextStyle(
                    fontSize: contact.isPrimary ? 17 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact.name,
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                        if (contact.isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE9E5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'PRIMARY',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(contact.relationship, style: AppTextStyles.bodyMuted),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 16, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          contact.phoneNumber,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          if (contact.isPrimary) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCopyNumber,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy Contact Number'),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCopyNumber,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: .35)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.copy_rounded, size: 17),
                label: const Text('Copy Number'),
              ),
            ),
          if (contact.isPrimary) ...[
            const SizedBox(height: 7),
            TextButton.icon(
              onPressed: onDetails,
              icon: const Icon(Icons.contact_page_outlined, size: 18),
              label: const Text('View contact details'),
            ),
          ],
        ],
      ),
    );
  }
}

class EmergencyInformationCard extends StatelessWidget {
  const EmergencyInformationCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onShowFullId,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<(String, String)> items;
  final VoidCallback onShowFullId;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFFFBF4),
      borderColor: const Color(0xFFF0DFC6),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEE1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.medical_information_outlined,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 11),
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          if (items.isNotEmpty) const SizedBox(height: 16),
          ...items.map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0E8DC))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(item.$1, style: AppTextStyles.label)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onShowFullId,
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Show Full Medical ID'),
            ),
          ),
        ],
      ),
    );
  }
}

class EmergencyChecklistCard extends StatelessWidget {
  const EmergencyChecklistCard({required this.items, super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        color: AppColors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryGreen,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(child: Text(item, style: AppTextStyles.body)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
