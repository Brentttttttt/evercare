import 'package:flutter/material.dart';

import '../../data/journal_mock_data.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_page.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/section_header.dart';
import 'journal_entry_card.dart';

class JournalsScreen extends StatefulWidget {
  const JournalsScreen({super.key});

  @override
  State<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends State<JournalsScreen> {
  String _filter = 'All Entries';

  @override
  Widget build(BuildContext context) {
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
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.addJournal),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Journal Entry'),
            ),
          ),
          const SizedBox(height: 27),
          const SectionHeader(
            title: 'Recent Entries',
            subtitle: 'Moments and health notes from recent days',
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: JournalMockData.filters
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
          const SizedBox(height: 14),
          ...JournalMockData.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: JournalEntryCard(
                entry: entry,
                onAction: (action) {
                  // TODO: Implement journal actions after persistence is added.
                  showMockDialog(
                    context,
                    title: '$action journal entry',
                    message:
                        '$action is a visual preview only. No journal entry was changed.',
                    icon: Icons.auto_stories_outlined,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
