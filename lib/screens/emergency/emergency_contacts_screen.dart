import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Emergency Contacts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ContactCard(
            name: 'Ana Santos',
            relationship: 'Daughter · Primary contact',
            phone: '+63 917 555 0182',
            primary: true,
            onEdit: () => _showEdit(context),
          ),
          const SizedBox(height: 12),
          _ContactCard(
            name: 'Miguel Santos',
            relationship: 'Son · Secondary contact',
            phone: '+63 918 555 0137',
            onEdit: () => _showEdit(context),
          ),
          const SizedBox(height: 12),
          const AppCard(
            color: Color(0xFFFFF8EB),
            borderColor: Color(0xFFF8E1B6),
            child: Row(
              children: [
                Icon(Icons.support_agent_rounded, color: AppColors.warning),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Local emergency hotline',
                        style: AppTextStyles.cardTitle,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hotline number placeholder',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => showMockDialog(
              context,
              title: 'Add emergency contact',
              message:
                  'A contact form would open here. EverCare will not access the phone’s contact list.',
              icon: Icons.person_add_alt_1_outlined,
            ),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  void _showEdit(BuildContext context) {
    showMockDialog(
      context,
      title: 'Edit contact',
      message:
          'Contact editing is a static preview. No phone contacts or saved data are changed.',
      icon: Icons.edit_outlined,
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.name,
    required this.relationship,
    required this.phone,
    required this.onEdit,
    this.primary = false,
  });

  final String name;
  final String relationship;
  final String phone;
  final VoidCallback onEdit;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: primary ? AppColors.lightGreen : null,
      borderColor: primary ? AppColors.lightGreen : null,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white,
                child: Text(
                  name.split(' ').map((part) => part[0]).join(),
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(relationship, style: AppTextStyles.bodyMuted),
                    const SizedBox(height: 5),
                    Text(phone, style: AppTextStyles.body),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit contact',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
