import 'package:flutter/material.dart';

import '../../models/care_book_chapter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class CareBookCover extends StatelessWidget {
  const CareBookCover({
    required this.onStartReading,
    required this.onDownload,
    required this.downloading,
    super.key,
  });

  final VoidCallback onStartReading;
  final VoidCallback? onDownload;
  final bool downloading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.darkGreen,
      borderColor: AppColors.darkGreen,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .14),
                  ),
                ),
                child: const Icon(
                  Icons.local_library_rounded,
                  color: Color(0xFFE6F4EB),
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Caregiver’s Handbook',
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Official reference for family caregivers',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: const Color(0xFFD7EADF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'NIA',
                  style: AppTextStyles.eyebrow.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
            ),
            child: Text(
              'Published by the National Institute on Aging. The PDF is an NIA publication—not an EverCare book; EverCare provides simplified notes based on it.',
              style: AppTextStyles.small.copyWith(
                color: const Color(0xFFD7EADF),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final start = FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF8E9),
                  foregroundColor: AppColors.darkGreen,
                ),
                onPressed: onStartReading,
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Start Reading'),
              );
              final download = OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: .56)),
                ),
                onPressed: onDownload,
                icon: downloading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  downloading ? 'Preparing PDF…' : 'Download NIA PDF',
                ),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [start, const SizedBox(height: 9), download],
                );
              }
              return Row(
                children: [
                  Expanded(child: start),
                  const SizedBox(width: 10),
                  Expanded(child: download),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class CareBookChapterNavigator extends StatelessWidget {
  const CareBookChapterNavigator({
    required this.chapter,
    required this.totalChapters,
    required this.onBrowse,
    super.key,
  });

  final CareBookChapter chapter;
  final int totalChapters;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onBrowse,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  careBookChapterIcon(chapter.iconName),
                  color: AppColors.darkGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TABLE OF CONTENTS · ${chapter.number}/$totalChapters',
                      style: AppTextStyles.eyebrow,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.unfold_more_rounded, color: AppColors.darkGreen),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: chapter.number / totalChapters,
              backgroundColor: AppColors.surfaceMuted,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class CareBookContentsSheet extends StatelessWidget {
  const CareBookContentsSheet({
    required this.chapters,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<CareBookChapter> chapters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: .82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 12, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Table of contents', style: AppTextStyles.pageTitle),
                      SizedBox(height: 3),
                      Text(
                        'Choose a chapter to continue reading.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close table of contents',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
              itemCount: chapters.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 62),
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final selected = index == selectedIndex;
                return Material(
                  color: selected ? AppColors.lightGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onSelected(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.card
                                  : AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(
                              careBookChapterIcon(chapter.iconName),
                              color: AppColors.darkGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chapter ${chapter.number} · ${chapter.readingTime}',
                                  style: AppTextStyles.small,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  chapter.title,
                                  style: AppTextStyles.cardTitle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.chevron_right_rounded,
                            color: selected
                                ? AppColors.primaryGreen
                                : AppColors.secondaryText,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CareBookReader extends StatelessWidget {
  const CareBookReader({
    required this.chapter,
    required this.totalChapters,
    required this.textScale,
    required this.onPrevious,
    required this.onNext,
    required this.onTextSmaller,
    required this.onTextLarger,
    super.key,
  });

  final CareBookChapter chapter;
  final int totalChapters;
  final double textScale;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onTextSmaller;
  final VoidCallback onTextLarger;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x12493C24),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF1),
            border: Border.all(color: const Color(0xFFE9DFC9)),
          ),
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFD9C59B), Color(0xFFF4E8CB)],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(27, 20, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            careBookChapterIcon(chapter.iconName),
                            color: AppColors.darkGreen,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'CHAPTER ${chapter.number} OF $totalChapters · ${chapter.readingTime}',
                            style: AppTextStyles.eyebrow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(chapter.title, style: AppTextStyles.pageTitle),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: chapter.number / totalChapters,
                        backgroundColor: const Color(0xFFECE4D2),
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...chapter.paragraphs.map(
                      (paragraph) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          paragraph,
                          style: AppTextStyles.body.copyWith(
                            fontSize: AppTextStyles.body.fontSize! * textScale,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ),
                    if (chapter.highlight != null) ...[
                      const SizedBox(height: 2),
                      _BookCallout(
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'Remember',
                        message: chapter.highlight!,
                      ),
                    ],
                    if (chapter.tips.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Care tips',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 9),
                      ...chapter.tips.map(
                        (tip) => _BookListItem(
                          text: tip,
                          icon: Icons.favorite_outline_rounded,
                        ),
                      ),
                    ],
                    if (chapter.checklist.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Helpful checklist',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 9),
                      ...chapter.checklist.map(
                        (item) => _BookListItem(
                          text: item,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                    ],
                    if (chapter.disclaimer != null) ...[
                      const SizedBox(height: 16),
                      _BookCallout(
                        icon: Icons.health_and_safety_outlined,
                        title: 'Safety note',
                        message: chapter.disclaimer!,
                        warning: true,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 17),
                      child: Divider(),
                    ),
                    Text('Reading size', style: AppTextStyles.label),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ReaderControl(
                          icon: Icons.text_decrease_rounded,
                          label: 'Smaller',
                          onTap: onTextSmaller,
                        ),
                        _ReaderControl(
                          icon: Icons.text_increase_rounded,
                          label: 'Larger',
                          onTap: onTextLarger,
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onPrevious,
                            child: const Text('← Previous'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: onNext,
                            child: const Text('Next →'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Chapter ${chapter.number} of $totalChapters',
                        style: AppTextStyles.small,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CareBookReferenceCard extends StatelessWidget {
  const CareBookReferenceCard({
    required this.onOpenOfficialSource,
    required this.onOpenGettingStarted,
    required this.onDownloadLocal,
    required this.downloading,
    super.key,
  });

  final VoidCallback onOpenOfficialSource;
  final VoidCallback onOpenGettingStarted;
  final VoidCallback? onDownloadLocal;
  final bool downloading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFFF8E9),
      borderColor: const Color(0xFFE9D5AA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.library_books_outlined, color: AppColors.darkGreen),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Official NIA Reference',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Text(
            'National Institute on Aging.\nThe Caregiver’s Handbook.',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 7),
          const Text(
            'The bundled PDF is the original NIA handbook used as a reference. It is not owned or published by EverCare.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 15),
          _ReferenceLink(
            icon: Icons.public_rounded,
            title: 'Official Source Website',
            url: 'order.nia.nih.gov/publication/caregivers-handbook',
            onTap: onOpenOfficialSource,
          ),
          const SizedBox(height: 9),
          _ReferenceLink(
            icon: Icons.health_and_safety_outlined,
            title: 'Getting Started With Caregiving',
            url: 'nia.nih.gov/health/caregiving/getting-started-caregiving',
            onTap: onOpenGettingStarted,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(),
          ),
          const Text(
            'EverCare provides simplified educational summaries for general caregiving support. This content does not replace medical advice, diagnosis, treatment, or instructions from qualified healthcare professionals.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 10),
          const Text(
            'The summaries shown in EverCare are original simplified adaptations and are not a replacement for reading the complete handbook.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onDownloadLocal,
              icon: downloading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(
                downloading ? 'Preparing PDF…' : 'Download Original NIA PDF',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceLink extends StatelessWidget {
  const _ReferenceLink({
    required this.icon,
    required this.title,
    required this.url,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.darkGreen, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(url, style: AppTextStyles.small),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.open_in_new_rounded,
                  color: AppColors.darkGreen,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCallout extends StatelessWidget {
  const _BookCallout({
    required this.icon,
    required this.title,
    required this.message,
    this.warning = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.warning : AppColors.primaryGreen;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .23)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookListItem extends StatelessWidget {
  const _BookListItem({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _ReaderControl extends StatelessWidget {
  const _ReaderControl({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

IconData careBookChapterIcon(String name) => switch (name) {
  'start' => Icons.volunteer_activism_outlined,
  'needs' => Icons.person_search_outlined,
  'routine' => Icons.schedule_outlined,
  'medicine' => Icons.medication_outlined,
  'meals' => Icons.restaurant_outlined,
  'movement' => Icons.directions_walk_rounded,
  'communication' => Icons.forum_outlined,
  'visit' => Icons.medical_services_outlined,
  'organize' => Icons.folder_copy_outlined,
  'selfCare' => Icons.spa_outlined,
  'help' => Icons.groups_outlined,
  _ => Icons.emergency_outlined,
};
