import 'package:flutter/material.dart';

import '../../data/journal_options.dart';
import '../../models/journal_entry.dart';
import '../../repositories/journal_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../widgets/app_page.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/section_header.dart';
import 'add_journal_entry_screen.dart';
import 'journal_entry_card.dart';
import 'journal_entry_reader.dart';

class JournalsScreen extends StatefulWidget {
  const JournalsScreen({super.key});

  @override
  State<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends State<JournalsScreen> {
  String _filter = 'All Entries';
  JournalRepository? _repository;
  List<JournalEntry> _entries = const [];
  bool _initialized = false;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final client = EverCareBackendScope.maybeClient(context);
    if (client?.auth.currentUser == null) {
      _loading = false;
      return;
    }
    _repository = JournalRepository(client!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  List<JournalEntry> get _visibleEntries => _entries
      .where((entry) {
        return switch (_filter) {
          'Happy Moments' => entry.mood == 'Happy',
          'Health Notes' => entry.symptoms.isNotEmpty,
          'Symptoms' =>
            entry.symptoms.isNotEmpty &&
                !entry.symptoms.contains('No symptoms'),
          'Activities' => entry.activities.isNotEmpty,
          'Bookmarked' => entry.bookmarked,
          _ => true,
        };
      })
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final visibleEntries = _visibleEntries;
    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CarePhotoBanner(
            assetPath: 'assets/images/journal_reflection.png',
            semanticLabel:
                'An older woman writing in her journal beside her daughter caregiver',
            title: 'A gentle space to reflect',
            subtitle: 'Keep meaningful moments and daily feelings close.',
            height: 168,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addEntry,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Journal Entry'),
            ),
          ),
          const SizedBox(height: 27),
          const SectionHeader(
            title: 'Journal Entries',
            subtitle: 'Your saved moments and health notes',
          ),
          const SizedBox(height: 12),
          if (_entries.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: JournalOptions.filters
                    .map(
                      (filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          if (_entries.isNotEmpty) const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(36),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_repository == null)
            const EmptyStateCard(
              title: 'Sign in to use your journal',
              message:
                  'Your private journal entries will appear here after you sign in.',
              icon: Icons.lock_outline_rounded,
            )
          else if (_error != null)
            _LoadError(message: _error!, onRetry: _load)
          else if (_entries.isEmpty)
            const EmptyStateCard(
              title: 'Your journal is ready',
              message:
                  'Add your first entry when you have something to remember.',
              icon: Icons.auto_stories_outlined,
            )
          else if (visibleEntries.isEmpty)
            const EmptyStateCard(
              title: 'No matching entries',
              message: 'Try another filter to see your saved journal entries.',
              icon: Icons.filter_alt_off_outlined,
            )
          else
            ...visibleEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: JournalEntryCard(
                  entry: entry,
                  onAction: (action) => _handleAction(entry, action),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await repository.fetchEntries();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'EverCare could not load your journal. Please try again.';
      });
    }
  }

  Future<void> _addEntry() async {
    final changed = await Navigator.of(context).push<bool>(
      EverCarePageRoute(builder: (_) => const AddJournalEntryScreen()),
    );
    if (changed == true) await _load();
  }

  Future<void> _handleAction(JournalEntry entry, String action) async {
    switch (action) {
      case 'View':
        await showJournalEntryReader(context, entry);
        return;
      case 'Edit':
        final changed = await Navigator.of(context).push<bool>(
          EverCarePageRoute(
            builder: (_) => AddJournalEntryScreen(entry: entry),
          ),
        );
        if (changed == true) await _load();
        return;
      case 'Delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete this entry?'),
            content: const Text(
              'This permanently removes the journal entry and its attached photos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        try {
          await _repository!.deleteEntry(entry.id);
          await _load();
        } catch (_) {
          if (!mounted) return;
          _showError('EverCare could not delete this entry.');
        }
        return;
      case 'Bookmark':
        try {
          await _repository!.setBookmarked(
            entry.id,
            bookmarked: !entry.bookmarked,
          );
          if (!mounted) return;
          setState(() {
            _entries = _entries
                .map(
                  (item) => item.id == entry.id
                      ? item.copyWith(bookmarked: !item.bookmarked)
                      : item,
                )
                .toList(growable: false);
          });
        } catch (_) {
          if (!mounted) return;
          _showError('EverCare could not update this entry.');
        }
        return;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: AppColors.danger,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
