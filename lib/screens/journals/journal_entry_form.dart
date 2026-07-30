import 'package:flutter/material.dart';

import '../../data/journal_options.dart';
import '../../models/journal_entry.dart';
import '../../repositories/journal_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../authentication/auth_widgets.dart';

class JournalEntryForm extends StatefulWidget {
  const JournalEntryForm({super.key, this.entry});

  final JournalEntry? entry;

  @override
  State<JournalEntryForm> createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends State<JournalEntryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late DateTime _entryAt;
  late String _mood;
  late Set<String> _symptoms;
  late Set<String> _activities;
  JournalRepository? _repository;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _titleController = TextEditingController(text: entry?.title);
    _bodyController = TextEditingController(text: entry?.body);
    _entryAt = entry?.entryAt ?? DateTime.now();
    _mood = entry?.mood.isNotEmpty == true ? entry!.mood : 'Calm';
    _symptoms = {...?entry?.symptoms};
    _activities = {...?entry?.activities};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final client = EverCareBackendScope.maybeClient(context);
    _repository = client?.auth.currentUser == null
        ? null
        : JournalRepository(client!);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFFFCF3),
      borderColor: const Color(0xFFE8DFC8),
      child: Form(
        key: _formKey,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry == null
                            ? 'New Journal Entry'
                            : 'Update Journal Entry',
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 3),
                      const Text(
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
              onTap: _saving ? null : _chooseDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.today_outlined,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        _dateLabel(_entryAt),
                        style: AppTextStyles.body,
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded),
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
              children: JournalOptions.moods
                  .map(
                    (mood) => ChoiceChip(
                      label: Text(mood),
                      selected: _mood == mood,
                      avatar: Icon(_moodIcon(mood), size: 18),
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _mood = mood),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: _titleController,
              label: 'Entry title',
              hint: 'Give today a short title',
              icon: Icons.title_rounded,
              validator: (value) => validateRequiredText(value, 'Entry title'),
              enabled: !_saving,
            ),
            AppTextField(
              controller: _bodyController,
              label: 'What would you like to remember?',
              hint: 'Write about your thoughts, symptoms, or special moments…',
              icon: Icons.menu_book_outlined,
              maxLines: 6,
              validator: (value) => validateRequiredText(value, 'Journal note'),
              enabled: !_saving,
            ),
            _TagSelector(
              title: 'Symptoms (optional)',
              values: JournalOptions.symptoms,
              selected: _symptoms,
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        if (value == 'No symptoms') _symptoms.clear();
                        _toggle(_symptoms, value);
                        if (value != 'No symptoms') {
                          _symptoms.remove('No symptoms');
                        }
                      });
                    },
            ),
            const SizedBox(height: 16),
            _TagSelector(
              title: 'Activities (optional)',
              values: JournalOptions.activities,
              selected: _activities,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _toggle(_activities, value)),
            ),
            if (_repository == null) ...[
              const SizedBox(height: 18),
              const _FormNotice(
                message: 'Sign in to save journal entries to EverCare.',
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 18),
              _FormNotice(message: _error!, isError: true),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _repository == null || _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_add_outlined),
                label: Text(_saving ? 'Saving…' : 'Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _entryAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _entryAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _entryAt.hour,
        _entryAt.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final entry = widget.entry;
      if (entry == null) {
        await _repository!.createEntry(
          entryAt: _entryAt,
          title: _titleController.text,
          body: _bodyController.text,
          mood: _mood,
          symptoms: _symptoms.toList(growable: false),
          activities: _activities.toList(growable: false),
        );
      } else {
        await _repository!.updateEntry(
          id: entry.id,
          entryAt: _entryAt,
          title: _titleController.text,
          body: _bodyController.text,
          mood: _mood,
          symptoms: _symptoms.toList(growable: false),
          activities: _activities.toList(growable: false),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'EverCare could not save this entry. Please try again.';
      });
    }
  }

  void _toggle(Set<String> values, String value) {
    values.contains(value) ? values.remove(value) : values.add(value);
  }

  String _dateLabel(DateTime value) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
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
  final ValueChanged<String>? onChanged;

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
                  onSelected: onChanged == null
                      ? null
                      : (_) => onChanged!(value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _FormNotice extends StatelessWidget {
  const _FormNotice({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.primaryGreen;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: AppTextStyles.body.copyWith(color: color)),
    );
  }
}
