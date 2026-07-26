import 'package:flutter/material.dart';

import '../../data/care_book_data.dart';
import '../../services/care_book_service.dart';
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
  bool _downloading = false;
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
            downloading: _downloading,
            onStartReading: () {
              setState(() => _selectedChapter = 0);
              _scrollToReader();
            },
            onDownload: _downloading ? null : _downloadHandbook,
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
            title: 'Simplified Caregiving Notes',
            subtitle: 'EverCare summaries based on the official NIA handbook',
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
            downloading: _downloading,
            onDownloadLocal: _downloading ? null : _downloadHandbook,
            onOpenOfficialSource: () => _openReference(
              CareBookService.officialSource,
              'Official Source Website',
            ),
            onOpenGettingStarted: () => _openReference(
              CareBookService.gettingStartedGuide,
              'Getting Started With Caregiving',
            ),
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

  Future<void> _downloadHandbook() async {
    setState(() => _downloading = true);
    try {
      final savedPath = await CareBookService.saveHandbookCopy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedPath == null
                ? 'The NIA handbook could not be saved.'
                : 'Original NIA handbook saved successfully:\n$savedPath',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showMockMessage(
        'Could not save the PDF',
        'Please check that a save location is available, then try again.',
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _openReference(Uri uri, String title) async {
    try {
      final opened = await CareBookService.openReference(uri);
      if (!opened && mounted) {
        _showMockMessage(
          'Could not open $title',
          'Please check your browser connection and try again.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showMockMessage(
        'Could not open $title',
        'Please check your browser connection and try again.',
      );
    }
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
