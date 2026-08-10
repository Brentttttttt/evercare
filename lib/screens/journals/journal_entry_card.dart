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
      onTap: () => onAction('View'),
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
              IconButton(
                onPressed: () => onAction('Bookmark'),
                tooltip: entry.bookmarked
                    ? 'Remove journal bookmark'
                    : 'Bookmark journal entry',
                icon: Icon(
                  entry.bookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: entry.bookmarked
                      ? AppColors.warning
                      : AppColors.secondaryText,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Journal entry actions',
                onSelected: onAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Edit',
                    child: _MenuAction(
                      icon: Icons.edit_outlined,
                      label: 'Edit entry',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Delete',
                    child: _MenuAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete entry',
                      color: AppColors.danger,
                    ),
                  ),
                ],
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
              ..._visibleDetails.map(
                (detail) => _EntryTag(
                  label: detail.label,
                  icon: detail.isCustom ? Icons.sell_outlined : null,
                ),
              ),
              if (_hiddenDetailCount > 0)
                _EntryTag(label: '+$_hiddenDetailCount more'),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 11),
          Row(
            children: [
              Text(
                'View entry',
                style: AppTextStyles.label.copyWith(color: AppColors.darkGreen),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.darkGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_JournalDetail> get _details => [
    ...entry.tags.map((label) => _JournalDetail(label, isCustom: true)),
    ...entry.symptoms.map(_JournalDetail.new),
    ...entry.activities.map(_JournalDetail.new),
  ];

  List<_JournalDetail> get _visibleDetails =>
      _details.take(3).toList(growable: false);

  int get _hiddenDetailCount => (_details.length - 3).clamp(0, _details.length);

  String _dateLabel(DateTime value) =>
      journalDateLabel(value, includeTime: true);
}

class _JournalDetail {
  const _JournalDetail(this.label, {this.isCustom = false});

  final String label;
  final bool isCustom;
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

class _MenuAction extends StatelessWidget {
  const _MenuAction({
    required this.icon,
    required this.label,
    this.color = AppColors.darkGreen,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.body.copyWith(color: color)),
      ],
    );
  }
}
