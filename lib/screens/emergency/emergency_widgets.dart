import 'package:flutter/material.dart';

import '../../models/mock_emergency_contact.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class EmergencyContactCard extends StatelessWidget {
  const EmergencyContactCard({
    required this.contact,
    required this.onCall,
    required this.onMessage,
    required this.onDetails,
    super.key,
  });

  final MockEmergencyContact contact;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final accent = contact.primary ? AppColors.danger : AppColors.primaryGreen;
    return AppCard(
      borderColor: contact.primary
          ? AppColors.danger.withValues(alpha: .28)
          : AppColors.border,
      color: contact.primary ? const Color(0xFFFFFBF7) : Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: contact.primary ? 29 : 25,
                backgroundColor: accent.withValues(alpha: .12),
                foregroundColor: accent,
                child: Text(
                  contact.initials,
                  style: TextStyle(
                    fontSize: contact.primary ? 17 : 15,
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
                        if (contact.primary)
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
                          contact.phone,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 6),
                        Text(contact.availability, style: AppTextStyles.small),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          if (contact.primary) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCall,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.call_outlined, size: 18),
                label: const Text('Call Anna'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onMessage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: .35)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                label: const Text('Send Emergency Message'),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCall,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onMessage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent.withValues(alpha: .35)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 17,
                    ),
                    label: const Text('Message'),
                  ),
                ),
              ],
            ),
          if (contact.primary) ...[
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
    required this.items,
    required this.onShowFullId,
    super.key,
  });

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
          const Text(
            'Maria’s Emergency Medical ID',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 4),
          const Text(
            'Important sample information for a care emergency',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 16),
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
