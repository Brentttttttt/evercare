import 'package:flutter/material.dart';

import '../../data/care_book_data.dart';
import '../../widgets/app_page.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/section_header.dart';
import 'care_book_widgets.dart';

class CareBookScreen extends StatefulWidget {
  const CareBookScreen({super.key});

  @override
  State<CareBookScreen> createState() => _CareBookScreenState();
}

class _CareBookScreenState extends State<CareBookScreen> {
  final _scrollController = ScrollController();
  final _readerKey = GlobalKey();
  int _selectedChapter = 0;
  bool _bookmarked = false;
  double _textScale = 1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapters = CareBookData.chapters;
    final chapter = chapters[_selectedChapter];
    return SingleChildScrollView(
      controller: _scrollController,
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CarePhotoBanner(
            assetPath: 'assets/images/care_book_reading.png',
            semanticLabel:
                'A caregiver and an older man reading a caregiving book together',
            title: 'Care knowledge, shared with warmth',
            subtitle: 'Simple guidance for safer and more confident care.',
            height: 168,
          ),
          const SizedBox(height: 20),
          CareBookCover(
            onStartReading: () {
              setState(() => _selectedChapter = 0);
              _scrollToReader();
            },
            onDownload: () => _showSourcePreview('Download Original PDF'),
          ),
          const SizedBox(height: 28),
          KeyedSubtree(
            key: _readerKey,
            child: CareBookReader(
              chapter: chapter,
              totalChapters: chapters.length,
              textScale: _textScale,
              bookmarked: _bookmarked,
              onPrevious: _selectedChapter == 0
                  ? null
                  : () => _selectChapter(_selectedChapter - 1),
              onNext: _selectedChapter == chapters.length - 1
                  ? null
                  : () => _selectChapter(_selectedChapter + 1),
              onBookmark: () {
                // TODO: Persist chapter bookmarks in a future implementation.
                setState(() => _bookmarked = !_bookmarked);
              },
              onListen: () {
                // TODO: Add text-to-speech in a future implementation.
                _showMockMessage(
                  'Listen preview',
                  'EverCare is not playing audio in this prototype.',
                );
              },
              onTextSmaller: () => setState(
                () => _textScale = (_textScale - .1).clamp(.9, 1.2).toDouble(),
              ),
              onTextLarger: () => setState(
                () => _textScale = (_textScale + .1).clamp(.9, 1.2).toDouble(),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const SectionHeader(
            title: 'Book Contents',
            subtitle: 'Choose one of 12 short caregiving lessons',
          ),
          const SizedBox(height: 13),
          ...chapters.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: CareBookChapterCard(
                chapter: item,
                selected: item.number - 1 == _selectedChapter,
                onTap: () => _selectChapter(item.number - 1),
              ),
            ),
          ),
          const SizedBox(height: 17),
          CareBookReferenceCard(
            onViewSource: () => _showSourcePreview('View Original Source'),
          ),
        ],
      ),
    );
  }

  void _selectChapter(int index) {
    setState(() {
      _selectedChapter = index;
      _bookmarked = false;
    });
    _scrollToReader();
  }

  void _scrollToReader() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _readerKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: .02,
        );
      }
    });
  }

  void _showSourcePreview(String title) {
    // TODO: Open or download the bundled PDF in a future implementation.
    _showMockMessage(
      title,
      'The original handbook is bundled for a future phase. EverCare does not open, download, or share PDF files in this prototype.',
    );
  }

  void _showMockMessage(String title, String message) {
    showMockDialog(
      context,
      title: title,
      message: message,
      icon: Icons.menu_book_outlined,
    );
  }
}
