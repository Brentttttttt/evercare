import 'package:flutter/material.dart';

import '../../data/journal_mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../authentication/auth_widgets.dart';

class JournalEntryForm extends StatefulWidget {
  const JournalEntryForm({super.key});

  @override
  State<JournalEntryForm> createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends State<JournalEntryForm> {
  String _mood = 'Calm';
  final Set<String> _symptoms = {'No symptoms'};
  final Set<String> _activities = {};

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFFFCF3),
      borderColor: const Color(0xFFE8DFC8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Journal Entry', style: AppTextStyles.cardTitle),
                    SizedBox(height: 3),
                    Text(
                      'Take a quiet moment to write.',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => showMockDialog(
              context,
              title: 'Choose a journal date',
              message:
                  'A date selector would appear here. No journal information is changed.',
              icon: Icons.calendar_month_outlined,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.today_outlined, color: AppColors.primaryGreen),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Sunday, July 26, 2026',
                      style: AppTextStyles.body,
                    ),
                  ),
                  Icon(Icons.expand_more_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('How do you feel?', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: JournalMockData.moods
                .map(
                  (mood) => ChoiceChip(
                    label: Text(mood),
                    selected: _mood == mood,
                    avatar: Icon(_moodIcon(mood), size: 18),
                    onSelected: (_) => setState(() => _mood = mood),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          const MockTextField(
            label: 'Entry title',
            hint: 'Give today a short title',
            icon: Icons.title_rounded,
          ),
          const MockTextField(
            label: 'What would you like to remember?',
            hint: 'Write about your thoughts, symptoms, or special moments…',
            icon: Icons.menu_book_outlined,
            maxLines: 6,
          ),
          _TagSelector(
            title: 'Symptoms (optional)',
            values: JournalMockData.symptoms,
            selected: _symptoms,
            onChanged: (value) {
              setState(() {
                if (value == 'No symptoms') _symptoms.clear();
                _toggle(_symptoms, value);
                if (value != 'No symptoms') _symptoms.remove('No symptoms');
              });
            },
          ),
          const SizedBox(height: 16),
          _TagSelector(
            title: 'Activities (optional)',
            values: JournalMockData.activities,
            selected: _activities,
            onChanged: (value) => setState(() => _toggle(_activities, value)),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Add an image picker in a future implementation.
                showMockDialog(
                  context,
                  title: 'Add a photo',
                  message:
                      'A photo picker would open here. EverCare is not accessing photos or files in this prototype.',
                  icon: Icons.add_photo_alternate_outlined,
                );
              },
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add Photo Placeholder'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                // TODO: Persist journal entries in a future implementation.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Journal preview complete. No entry was saved.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save Entry'),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(Set<String> values, String value) {
    values.contains(value) ? values.remove(value) : values.add(value);
  }

  IconData _moodIcon(String mood) => switch (mood) {
    'Happy' => Icons.sentiment_very_satisfied_rounded,
    'Calm' => Icons.spa_outlined,
    'Tired' => Icons.bedtime_outlined,
    'Sad' => Icons.sentiment_dissatisfied_rounded,
    'Worried' => Icons.sentiment_neutral_rounded,
    _ => Icons.healing_outlined,
  };
}

class _TagSelector extends StatelessWidget {
  const _TagSelector({
    required this.title,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<String> values;
  final Set<String> selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => FilterChip(
                  label: Text(value),
                  selected: selected.contains(value),
                  onSelected: (_) => onChanged(value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}
