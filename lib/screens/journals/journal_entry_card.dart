import 'package:flutter/material.dart';

import '../../models/journal_entry.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import 'journal_photo_widgets.dart';
import 'journal_ui_helpers.dart';

class JournalEntryCard extends StatelessWidget {
  const JournalEntryCard({
    required this.entry,
    required this.onAction,
    super.key,
  });

  final JournalEntry entry;
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
                    Text(_dateLabel(entry.entryAt), style: AppTextStyles.small),
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
          Text(
            entry.body,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body,
          ),
          if (entry.photos.isNotEmpty) ...[
            const SizedBox(height: 14),
            _PhotoPreview(entry: entry),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _EntryTag(
                label: entry.mood.isEmpty ? 'Mood not recorded' : entry.mood,
                icon: journalMoodIcon(entry.mood),
                emphasized: true,
              ),
              ...entry.tags.map(
                (tag) => _EntryTag(label: tag, icon: Icons.sell_outlined),
              ),
              ...entry.symptoms.map((tag) => _EntryTag(label: tag)),
              ...entry.activities.map((tag) => _EntryTag(label: tag)),
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
                icon: entry.bookmarked
                    ? Icons.bookmark_remove_outlined
                    : Icons.bookmark_add_outlined,
                label: entry.bookmarked ? 'Unsave' : 'Save',
                onTap: () => onAction('Bookmark'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime value) =>
      journalDateLabel(value, includeTime: true);
}

class _EntryTag extends StatelessWidget {
  const _EntryTag({required this.label, this.emphasized = false, this.icon});

  final String label;
  final bool emphasized;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.lightGreen : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.darkGreen),
            const SizedBox(width: 5),
          ],
          Text(label, style: AppTextStyles.small),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final first = entry.photos.first;
    return Semantics(
      button: first.signedUrl != null,
      label: '${entry.photos.length} attached journal photos',
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: first.signedUrl == null
              ? null
              : () => showJournalPhotoPreview(context, photo: first),
          child: SizedBox(
            width: double.infinity,
            height: 154,
            child: Stack(
              fit: StackFit.expand,
              children: [
                JournalPhotoImage(photo: first),
                if (entry.photos.length > 1)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkGreen.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${entry.photos.length - 1}',
                        style: AppTextStyles.small.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
