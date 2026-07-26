import 'package:flutter/material.dart';

import '../../models/care_book_chapter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class CareBookCover extends StatelessWidget {
  const CareBookCover({
    required this.onStartReading,
    required this.onDownload,
    super.key,
  });

  final VoidCallback onStartReading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x24172D20),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Container(
          color: AppColors.darkGreen,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .16),
                    border: Border(
                      right: BorderSide(
                        color: Colors.white.withValues(alpha: .10),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 28,
                top: 0,
                child: ClipPath(
                  clipper: _RibbonClipper(),
                  child: Container(
                    width: 38,
                    height: 64,
                    color: const Color(0xFFE6A65D),
                    child: const Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: 11),
                        child: Icon(
                          Icons.bookmark_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(29, 30, 25, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 59,
                      height: 59,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.local_library_rounded,
                        color: Color(0xFFE6F4EB),
                        size: 31,
                      ),
                    ),
                    const SizedBox(height: 23),
                    Text(
                      'The EverCare\nCare Book',
                      style: AppTextStyles.display.copyWith(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Simple guidance for caring for and supporting older adults',
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFFD7EADF),
                      ),
                    ),
                    const SizedBox(height: 21),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Based on The Caregiver’s Handbook by the National Institute on Aging',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Adapted into short, easy-to-read caregiving lessons.',
                            style: TextStyle(
                              color: Color(0xFFC9DED2),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF8E9),
                          foregroundColor: AppColors.darkGreen,
                        ),
                        onPressed: onStartReading,
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text('Start Reading'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: .65),
                          ),
                        ),
                        onPressed: onDownload,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Download Original PDF'),
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

class CareBookChapterCard extends StatelessWidget {
  const CareBookChapterCard({
    required this.chapter,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final CareBookChapter chapter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: selected ? const Color(0xFFFFF6DF) : Colors.white,
      borderColor: selected ? const Color(0xFFE6C88B) : null,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF4DDAE) : AppColors.lightGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              careBookChapterIcon(chapter.iconName),
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHAPTER ${chapter.number}', style: AppTextStyles.eyebrow),
                const SizedBox(height: 4),
                Text(chapter.title, style: AppTextStyles.cardTitle),
              ],
            ),
          ),
          const SizedBox(width: 7),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.secondaryText,
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
    required this.bookmarked,
    required this.onPrevious,
    required this.onNext,
    required this.onBookmark,
    required this.onListen,
    required this.onTextSmaller,
    required this.onTextLarger,
    super.key,
  });

  final CareBookChapter chapter;
  final int totalChapters;
  final double textScale;
  final bool bookmarked;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onBookmark;
  final VoidCallback onListen;
  final VoidCallback onTextSmaller;
  final VoidCallback onTextLarger;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x1C493C24),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Container(
          color: const Color(0xFFFFFBF1),
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
                padding: const EdgeInsets.fromLTRB(29, 23, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'CHAPTER ${chapter.number} · ${chapter.readingTime}',
                            style: AppTextStyles.eyebrow,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Bookmark chapter',
                          onPressed: onBookmark,
                          icon: Icon(
                            bookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: bookmarked
                                ? AppColors.warning
                                : AppColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(chapter.title, style: AppTextStyles.pageTitle),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ReaderControl(
                          icon: Icons.volume_up_outlined,
                          label: 'Listen',
                          onTap: onListen,
                        ),
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
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Page ${chapter.number} of $totalChapters',
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
  const CareBookReferenceCard({required this.onViewSource, super.key});

  final VoidCallback onViewSource;

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
                  'Primary Reference',
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
            'Original PDF included at assets/care_book/caregivers-book.pdf',
            style: AppTextStyles.bodyMuted,
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
            child: OutlinedButton.icon(
              onPressed: onViewSource,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('View Original Source'),
            ),
          ),
        ],
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

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(size.width / 2, size.height - 12)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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
