import 'package:flutter/material.dart';

import '../../models/mock_journal_entry.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class JournalEntryCard extends StatelessWidget {
  const JournalEntryCard({
    required this.entry,
    required this.onAction,
    super.key,
  });

  final MockJournalEntry entry;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(entry.dateLabel, style: AppTextStyles.small),
                  ],
                ),
              ),
              Icon(
                entry.bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: entry.bookmarked
                    ? AppColors.warning
                    : AppColors.secondaryText,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(entry.body, style: AppTextStyles.body),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _EntryTag(label: 'Mood: ${entry.mood}', emphasized: true),
              ...entry.tags.map((tag) => _EntryTag(label: tag)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(
                icon: Icons.visibility_outlined,
                label: 'View',
                onTap: () => onAction('View'),
              ),
              _ActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => onAction('Edit'),
              ),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: AppColors.danger,
                onTap: () => onAction('Delete'),
              ),
              _ActionButton(
                icon: Icons.bookmark_border_rounded,
                label: 'Bookmark',
                onTap: () => onAction('Bookmark'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryTag extends StatelessWidget {
  const _EntryTag({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.lightGreen : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(label, style: AppTextStyles.small),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.darkGreen,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(label, style: AppTextStyles.small.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
