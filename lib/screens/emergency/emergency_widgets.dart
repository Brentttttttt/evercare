import 'package:flutter/material.dart';

import '../../models/emergency_contact.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Calm, platform-style emergency surfaces shared by the emergency page.
///
/// These deliberately avoid heavy shadows and stacked borders: urgent actions
/// stay visually prominent while saved information reads like an iOS grouped
/// list.
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
    return _EmergencySurface(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    contact.initials,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.primaryContainerForeground,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.name, style: AppTextStyles.cardTitle),
                      const SizedBox(height: 2),
                      Text(
                        contact.relationship,
                        style: AppTextStyles.bodyMuted,
                      ),
                      if (contact.isPrimary) ...[
                        const SizedBox(height: 7),
                        const _PrimaryLabel(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, color: AppColors.border),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 6),
              child: Row(
                children: [
                  const _ListSymbol(icon: Icons.phone_outlined),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      contact.phoneNumber,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onCopyNumber,
                    tooltip: 'Copy ${contact.name}’s number',
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 19),
                  ),
                ],
              ),
            ),
          ),
          if (contact.isPrimary) ...[
            const Divider(height: 1, indent: 56, color: AppColors.border),
            _DisclosureRow(
              icon: Icons.contact_page_outlined,
              label: 'View contact details',
              onTap: onDetails,
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
    return _EmergencySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _LargeListSymbol(
                  icon: Icons.medical_information_outlined,
                ),
                const SizedBox(width: 13),
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
              ],
            ),
          ),
          if (items.isNotEmpty) ...[
            const Divider(height: 1, indent: 16, color: AppColors.border),
            for (var index = 0; index < items.length; index++) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(items[index].$1, style: AppTextStyles.label),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: Text(
                        items[index].$2,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index != items.length - 1)
                const Divider(height: 1, indent: 16, color: AppColors.border),
            ],
          ],
          const Divider(height: 1, indent: 16, color: AppColors.border),
          _DisclosureRow(
            icon: Icons.badge_outlined,
            label: 'Show Full Medical ID',
            onTap: onShowFullId,
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
    return _EmergencySurface(
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryGreen,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(items[index], style: AppTextStyles.body),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (index != items.length - 1)
              const Divider(height: 1, indent: 56, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _EmergencySurface extends StatelessWidget {
  const _EmergencySurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.border.withValues(alpha: .72),
          width: .7,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _PrimaryLabel extends StatelessWidget {
  const _PrimaryLabel();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Primary emergency contact',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 13,
              color: AppColors.primary,
            ),
            SizedBox(width: 4),
            Text(
              'PRIMARY',
              style: TextStyle(
                color: AppColors.primaryContainerForeground,
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w700,
                letterSpacing: .45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSymbol extends StatelessWidget {
  const _ListSymbol({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 21, color: AppColors.primaryGreen);
  }
}

class _LargeListSymbol extends StatelessWidget {
  const _LargeListSymbol({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: AppColors.primaryGreen, size: 24),
    );
  }
}

class _DisclosureRow extends StatelessWidget {
  const _DisclosureRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _ListSymbol(icon: icon),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
