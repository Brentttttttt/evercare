import 'package:flutter/material.dart';

import '../../models/journal_entry.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'journal_paper.dart';
import 'journal_photo_widgets.dart';
import 'journal_ui_helpers.dart';

Future<void> showJournalEntryReader(BuildContext context, JournalEntry entry) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.darkGreen.withValues(alpha: .34),
    builder: (dialogContext) {
      final screen = MediaQuery.sizeOf(dialogContext);
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 720,
            maxHeight: screen.height * .92,
          ),
          child: JournalPaper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
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
                          Text(entry.title, style: AppTextStyles.pageTitle),
                          const SizedBox(height: 4),
                          Text(
                            journalDateLabel(entry.entryAt, includeTime: true),
                            style: AppTextStyles.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                    if (entry.bookmarked)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.bookmark_rounded,
                          color: AppColors.warning,
                          semanticLabel: 'Bookmarked entry',
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      tooltip: 'Close journal entry',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              journalMoodIcon(entry.mood),
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.mood.isEmpty
                                  ? 'Mood not recorded'
                                  : 'Feeling ${entry.mood.toLowerCase()}',
                              style: AppTextStyles.cardTitle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SelectableText(
                          entry.body,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 16,
                            height: 1.9,
                          ),
                        ),
                        if (entry.photos.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Photo memories',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (
                                var index = 0;
                                index < entry.photos.length;
                                index++
                              )
                                JournalPhotoAttachment(
                                  photo: entry.photos[index],
                                  semanticLabel:
                                      'Journal photo ${index + 1} of ${entry.photos.length}',
                                  onRemove: null,
                                  onPreview:
                                      entry.photos[index].signedUrl == null
                                      ? null
                                      : () => showJournalPhotoPreview(
                                          dialogContext,
                                          photo: entry.photos[index],
                                        ),
                                ),
                            ],
                          ),
                        ],
                        if (entry.symptoms.isNotEmpty ||
                            entry.activities.isNotEmpty ||
                            entry.tags.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 12),
                          if (entry.symptoms.isNotEmpty)
                            _DetailGroup(
                              label: 'Symptoms',
                              values: entry.symptoms,
                            ),
                          if (entry.activities.isNotEmpty)
                            _DetailGroup(
                              label: 'Activities',
                              values: entry.activities,
                            ),
                          if (entry.tags.isNotEmpty)
                            _DetailGroup(
                              label: 'Personal details',
                              values: entry.tags,
                            ),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _DetailGroup extends StatelessWidget {
  const _DetailGroup({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values
                .map(
                  (value) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFCEE3D7)),
                    ),
                    child: Text(value, style: AppTextStyles.small),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
