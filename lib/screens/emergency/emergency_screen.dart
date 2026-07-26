import 'package:flutter/material.dart';

import '../../data/emergency_mock_data.dart';
import '../../models/mock_emergency_contact.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/section_header.dart';
import 'emergency_widgets.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = EmergencyMockData.contacts;
    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CarePhotoBanner(
            assetPath: 'assets/images/emergency_preparedness.png',
            semanticLabel:
                'A daughter reassuring an older woman beside a prepared care bag and medical folder',
            title: 'Prepared care brings peace of mind',
            subtitle: 'Keep trusted contacts and important details nearby.',
            height: 168,
          ),
          const SizedBox(height: 20),
          AppCard(
            color: const Color(0xFFFFF8F4),
            borderColor: const Color(0xFFF5D8D3),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E1),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.sos_rounded,
                    color: AppColors.danger,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Do you need immediate help?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 7),
                const Text(
                  'Choose an emergency contact below. EverCare will help you prepare the call.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showCallPreview(
                      context,
                      name: 'Emergency Services',
                      phone: '911',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: const Icon(Icons.call_rounded),
                    label: const Text('Call Emergency Services'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Emergency Hotline: 911',
                  style: AppTextStyles.small,
                ),
                const SizedBox(height: 12),
                const Text(
                  'If the person is unconscious, having difficulty breathing, experiencing severe chest pain, or facing an immediate danger, contact emergency services.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 27),
          const SectionHeader(
            title: 'Primary Emergency Contact',
            subtitle: 'A trusted person to contact first',
          ),
          const SizedBox(height: 12),
          EmergencyContactCard(
            contact: contacts.first,
            onCall: () => _showCallPreview(
              context,
              name: contacts.first.name,
              phone: contacts.first.phone,
            ),
            onMessage: () => _showMessagePreview(context, contacts.first),
            onDetails: () =>
                Navigator.pushNamed(context, AppRoutes.emergencyContacts),
          ),
          const SizedBox(height: 27),
          const SectionHeader(
            title: 'Other Emergency Contacts',
            subtitle: 'Family and healthcare support',
          ),
          const SizedBox(height: 12),
          ...contacts
              .skip(1)
              .map(
                (contact) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: EmergencyContactCard(
                    contact: contact,
                    onCall: () => _showCallPreview(
                      context,
                      name: contact.name,
                      phone: contact.phone,
                    ),
                    onMessage: () => _showMessagePreview(context, contact),
                    onDetails: () {},
                  ),
                ),
              ),
          const SizedBox(height: 16),
          const SectionHeader(
            title: 'Emergency Medical Information',
            subtitle: 'Hardcoded details for this UI prototype',
          ),
          const SizedBox(height: 12),
          EmergencyInformationCard(
            items: EmergencyMockData.medicalInformation,
            onShowFullId: () =>
                Navigator.pushNamed(context, AppRoutes.medicalInfo),
          ),
          const SizedBox(height: 27),
          const SectionHeader(
            title: 'While Waiting for Help',
            subtitle: 'Simple reminders during an emergency',
          ),
          const SizedBox(height: 12),
          const EmergencyChecklistCard(
            items: EmergencyMockData.waitingChecklist,
          ),
          const SizedBox(height: 8),
          const Text(
            'This prototype provides general sample information only. Always follow instructions from qualified emergency personnel.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }

  void _showMessagePreview(BuildContext context, MockEmergencyContact contact) {
    // TODO: Open the device messaging app in a future implementation.
    showMockDialog(
      context,
      title: 'Message ${contact.name}?',
      message:
          'No message was created or sent. Messaging is shown as a mock interface only.',
      icon: Icons.chat_bubble_outline_rounded,
    );
  }

  void _showCallPreview(
    BuildContext context, {
    required String name,
    required String phone,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 2, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8E4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_in_talk_outlined,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 13),
            Text('Call $name?', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 7),
            Text(phone, style: AppTextStyles.cardTitle),
            const SizedBox(height: 7),
            const Text(
              'This will open your phone application with the contact number ready.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      // TODO: Launch the device phone dialer in a future implementation.
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Phone preview only — no call was started.',
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    child: const Text('Continue to Phone'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
