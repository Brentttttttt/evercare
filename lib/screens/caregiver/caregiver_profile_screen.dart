import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../repositories/caregiver_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';

class CaregiverProfileScreen extends StatefulWidget {
  const CaregiverProfileScreen({super.key, this.caregiver});

  final Map<String, String>? caregiver;

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  CaregiverRepository? _repository;
  bool _removing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final client = EverCareBackendScope.maybeClient(context);
    _repository = client?.auth.currentUser == null
        ? null
        : CaregiverRepository(client!);
  }

  @override
  Widget build(BuildContext context) {
    final caregiver = widget.caregiver;
    if (caregiver == null) {
      return const DetailPage(
        title: 'Caregiver Profile',
        child: EmptyStateCard(
          title: 'No caregiver selected',
          message:
              'Choose a caregiver from Trusted People to view their profile.',
          icon: Icons.person_search_outlined,
        ),
      );
    }
    final name = caregiver['name']?.trim() ?? '';
    final relationship = caregiver['relationship']?.trim() ?? 'Caregiver';
    final phone = caregiver['phone']?.trim() ?? '';
    final status = caregiver['status']?.trim() ?? 'unknown';

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
                    _initials(name),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name.isEmpty ? 'Caregiver profile' : name,
                  style: AppTextStyles.pageTitle,
                ),
                const SizedBox(height: 4),
                Text(relationship, style: AppTextStyles.bodyMuted),
                const SizedBox(height: 16),
                if (phone.isNotEmpty) ...[
                  LabeledValue(
                    label: 'Phone number',
                    value: phone,
                    icon: Icons.phone_outlined,
                  ),
                  const Divider(),
                ],
                LabeledValue(
                  label: 'Relationship status',
                  value: _status(status),
                  icon: Icons.verified_user_outlined,
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyPhone(phone),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Phone Number'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          const AppCard(
            color: Color(0xFFF5FAF7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.primaryGreen),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fine-grained sharing permissions are not enabled yet. This page does not claim that health records are currently shared.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            ),
          ),
          if (_repository != null && caregiver['id']?.isNotEmpty == true) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _removing ? null : _removeRelationship,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                icon: _removing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_remove_outlined),
                label: Text(_removing ? 'Removing…' : 'Remove Relationship'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyPhone(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Phone number copied.')));
  }

  Future<void> _removeRelationship() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove caregiver relationship?'),
        content: const Text(
          'This permanently removes the relationship from your EverCare account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _removing = true);
    try {
      await _repository!.removeRelationship(widget.caregiver!['id']!);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _removing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EverCare could not remove this relationship.'),
        ),
      );
    }
  }

  String _initials(String name) {
    final value = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return value.isEmpty ? 'EC' : value;
  }

  String _status(String value) {
    if (value.isEmpty) return 'Unknown';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
