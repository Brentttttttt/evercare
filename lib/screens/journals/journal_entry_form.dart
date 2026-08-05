import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/journal_options.dart';
import '../../models/journal_entry.dart';
import '../../models/journal_photo.dart';
import '../../repositories/journal_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../authentication/auth_widgets.dart';
import 'custom_journal_tag_dialog.dart';
import 'journal_paper.dart';
import 'journal_photo_picker_service.dart';
import 'journal_photo_widgets.dart';
import 'journal_ui_helpers.dart';

class JournalEntryForm extends StatefulWidget {
  const JournalEntryForm({super.key, this.entry});

  final JournalEntry? entry;

  @override
  State<JournalEntryForm> createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends State<JournalEntryForm> {
  static const _maximumPhotos = 5;

  final _formKey = GlobalKey<FormState>();
  final _photoPicker = JournalPhotoPickerService();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final _JournalDraftSnapshot _initialDraft;
  late DateTime _entryAt;
  late String _mood;
  late Set<String> _symptoms;
  late Set<String> _activities;
  late Set<String> _customTags;
  late List<JournalPhoto> _existingPhotos;
  final Set<String> _removedPhotoIds = <String>{};
  final List<JournalPhotoUpload> _pendingPhotos = <JournalPhotoUpload>[];
  JournalRepository? _repository;
  bool _saving = false;
  bool _pickingPhotos = false;
  bool _allowPop = false;
  String? _error;
  String? _photoError;

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
    _customTags = {...?entry?.tags};
    _existingPhotos = [...?entry?.photos];
    _initialDraft = _JournalDraftSnapshot(
      entryAt: _entryAt,
      mood: _mood,
      title: _titleController.text,
      body: _bodyController.text,
      symptoms: _symptoms,
      activities: _activities,
      customTags: _customTags,
      photoIds: _existingPhotos.map((photo) => photo.id).toSet(),
    );
    _titleController.addListener(_onWritingChanged);
    _bodyController.addListener(_onWritingChanged);
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
    _titleController
      ..removeListener(_onWritingChanged)
      ..dispose();
    _bodyController
      ..removeListener(_onWritingChanged)
      ..dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges =>
      !_entryAt.isAtSameMomentAs(_initialDraft.entryAt) ||
      _mood != _initialDraft.mood ||
      _titleController.text != _initialDraft.title ||
      _bodyController.text != _initialDraft.body ||
      !setEquals(_symptoms, _initialDraft.symptoms) ||
      !setEquals(_activities, _initialDraft.activities) ||
      !setEquals(_customTags, _initialDraft.customTags) ||
      !setEquals(
        _existingPhotos.map((photo) => photo.id).toSet(),
        _initialDraft.photoIds,
      ) ||
      _pendingPhotos.isNotEmpty;

  int get _photoCount => _existingPhotos.length + _pendingPhotos.length;

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: _allowPop || !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmDiscard());
      },
      child: JournalPaper(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPaperHeader(),
              const SizedBox(height: 22),
              _buildDateRow(),
              const SizedBox(height: 22),
              TextFormField(
                controller: _titleController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Entry title',
                  hintText: 'Give this memory a title…',
                  prefixIcon: Icon(Icons.title_rounded),
                  filled: false,
                  border: UnderlineInputBorder(),
                ),
                validator: (value) =>
                    validateRequiredText(value, 'Entry title'),
              ),
              const SizedBox(height: 24),
              const Text('How do you feel?', style: AppTextStyles.label),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: JournalOptions.moods
                    .map(
                      (mood) => JournalOptionChip(
                        label: mood,
                        icon: journalMoodIcon(mood),
                        selected: _mood == mood,
                        singleChoice: true,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _mood = mood),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 24),
              Text(
                'Today’s journal',
                style: AppTextStyles.label.copyWith(color: AppColors.darkGreen),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bodyController,
                enabled: !_saving,
                minLines: 10,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                scrollPadding: const EdgeInsets.only(bottom: 220),
                style: AppTextStyles.body.copyWith(fontSize: 16, height: 2),
                decoration: const InputDecoration(
                  hintText:
                      'Write about today, a special memory, changes you noticed, or anything you want to remember…',
                  alignLabelWithHint: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                validator: (value) =>
                    validateRequiredText(value, 'Journal note'),
              ),
              const SizedBox(height: 24),
              JournalSection(
                title: 'Add details to this memory',
                subtitle: 'Symptoms, activities, and your own labels',
                icon: Icons.tune_rounded,
                collapsible: true,
                initiallyExpanded:
                    _symptoms.isNotEmpty ||
                    _activities.isNotEmpty ||
                    _customTags.isNotEmpty,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OptionSelector(
                      title: 'Symptoms',
                      values: JournalOptions.symptoms,
                      selected: _symptoms,
                      enabled: !_saving,
                      onSelected: _toggleSymptom,
                    ),
                    const SizedBox(height: 18),
                    _OptionSelector(
                      title: 'Activities',
                      values: JournalOptions.activities,
                      selected: _activities,
                      enabled: !_saving,
                      onSelected: (value, selected) {
                        setState(() {
                          selected
                              ? _activities.add(value)
                              : _activities.remove(value);
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    Text('Your own details', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in _customTags)
                          InputChip(
                            label: Text(tag),
                            onDeleted: _saving
                                ? null
                                : () => setState(() => _customTags.remove(tag)),
                            deleteIcon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                            ),
                            deleteButtonTooltipMessage: 'Remove $tag',
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add your own'),
                          onPressed: _saving ? null : _addCustomTag,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              JournalSection(
                title: 'Add Photos',
                subtitle: 'Up to 5 private photo memories',
                icon: Icons.photo_library_outlined,
                child: _buildPhotoSection(),
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
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _repository == null || _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 19,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.menu_book_rounded),
                  label: Text(
                    _saving
                        ? 'Saving…'
                        : widget.entry == null
                        ? 'Save Journal Entry'
                        : 'Update Journal Entry',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaperHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.auto_stories_outlined,
            color: AppColors.darkGreen,
            size: 27,
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
                    : 'Edit Journal Entry',
                style: AppTextStyles.pageTitle,
              ),
              const SizedBox(height: 4),
              const Text(
                'Write down today’s memories, feelings, and observations.',
                style: AppTextStyles.bodyMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow() {
    return Semantics(
      button: true,
      label: 'Journal date, ${journalDateLabel(_entryAt)}',
      child: InkWell(
        onTap: _saving ? null : _chooseDate,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  journalDateLabel(_entryAt),
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.darkGreen,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const Icon(Icons.edit_calendar_outlined, size: 21),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final canAdd = _photoCount < _maximumPhotos && !_saving && !_pickingPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attach a meal, activity, document, or meaningful moment. Photos are resized before upload.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: canAdd
                  ? () => _pickPhotos(JournalPhotoSource.camera)
                  : null,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Camera'),
            ),
            OutlinedButton.icon(
              onPressed: canAdd
                  ? () => _pickPhotos(JournalPhotoSource.gallery)
                  : null,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_pickingPhotos) ...[
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '$_photoCount of $_maximumPhotos photos',
              style: AppTextStyles.small,
            ),
          ],
        ),
        if (_photoError != null) ...[
          const SizedBox(height: 10),
          _FormNotice(message: _photoError!, isError: true),
        ],
        if (_photoCount > 0) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var index = 0; index < _existingPhotos.length; index++)
                JournalPhotoAttachment(
                  photo: _existingPhotos[index],
                  semanticLabel:
                      'Saved journal photo ${index + 1} of $_photoCount',
                  onPreview: _existingPhotos[index].signedUrl == null
                      ? null
                      : () => showJournalPhotoPreview(
                          context,
                          photo: _existingPhotos[index],
                        ),
                  onRemove: _saving ? null : () => _removeExistingPhoto(index),
                ),
              for (var index = 0; index < _pendingPhotos.length; index++)
                JournalPhotoAttachment(
                  bytes: _pendingPhotos[index].bytes,
                  uploading: _saving,
                  semanticLabel:
                      'New journal photo ${_existingPhotos.length + index + 1} of $_photoCount',
                  onPreview: () => showJournalPhotoPreview(
                    context,
                    bytes: _pendingPhotos[index].bytes,
                  ),
                  onRemove: _saving
                      ? null
                      : () => setState(() => _pendingPhotos.removeAt(index)),
                ),
            ],
          ),
        ],
      ],
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

  Future<void> _addCustomTag() async {
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => CustomJournalTagDialog(existingTags: _customTags),
    );
    if (tag == null || !mounted) return;
    setState(() => _customTags.add(tag));
  }

  Future<void> _pickPhotos(JournalPhotoSource source) async {
    final remaining = _maximumPhotos - _photoCount;
    if (remaining <= 0 || _pickingPhotos) return;
    setState(() {
      _pickingPhotos = true;
      _photoError = null;
    });
    try {
      final result = await _photoPicker.pick(source, limit: remaining);
      if (!mounted) return;
      setState(() {
        _pendingPhotos.addAll(result.uploads);
        _photoError = result.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photoError =
            'The selected photo is unavailable. Your writing is still safe.';
      });
    } finally {
      if (mounted) setState(() => _pickingPhotos = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = _repository!;
      final entry = widget.entry;
      if (entry == null) {
        await repository.createEntry(
          entryAt: _entryAt,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          mood: _mood,
          symptoms: _symptoms.toList(growable: false),
          activities: _activities.toList(growable: false),
          tags: _customTags.toList(growable: false),
          newPhotos: List<JournalPhotoUpload>.unmodifiable(_pendingPhotos),
        );
      } else {
        await repository.updateEntry(
          original: entry,
          entryAt: _entryAt,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          mood: _mood,
          symptoms: _symptoms.toList(growable: false),
          activities: _activities.toList(growable: false),
          tags: _customTags.toList(growable: false),
          newPhotos: List<JournalPhotoUpload>.unmodifiable(_pendingPhotos),
          removedPhotoIds: Set<String>.unmodifiable(_removedPhotoIds),
        );
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _allowPop = true;
      });
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } on JournalPhotoStorageException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            '${error.message} Your writing and photo selections are still here—please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'EverCare could not save this entry. Your writing is still here—please try again.';
      });
    }
  }

  Future<void> _confirmDiscard() async {
    if (_saving) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this journal entry?'),
        content: const Text('Your unsaved writing and changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Writing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  void _toggleSymptom(String value, bool selected) {
    setState(() {
      if (value == 'No symptoms') {
        _symptoms.clear();
        if (selected) _symptoms.add(value);
        return;
      }
      _symptoms.remove('No symptoms');
      selected ? _symptoms.add(value) : _symptoms.remove(value);
    });
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      final removed = _existingPhotos.removeAt(index);
      _removedPhotoIds.add(removed.id);
    });
  }

  void _onWritingChanged() {
    if (mounted) setState(() {});
  }
}

class _OptionSelector extends StatelessWidget {
  const _OptionSelector({
    required this.title,
    required this.values,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String title;
  final List<String> values;
  final Set<String> selected;
  final bool enabled;
  final void Function(String value, bool selected) onSelected;

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
                (value) => JournalOptionChip(
                  label: value,
                  selected: selected.contains(value),
                  onSelected: enabled
                      ? (isSelected) => onSelected(value, isSelected)
                      : null,
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
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.lock_outline_rounded,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalDraftSnapshot {
  _JournalDraftSnapshot({
    required this.entryAt,
    required this.mood,
    required this.title,
    required this.body,
    required Set<String> symptoms,
    required Set<String> activities,
    required Set<String> customTags,
    required Set<String> photoIds,
  }) : symptoms = Set<String>.unmodifiable(symptoms),
       activities = Set<String>.unmodifiable(activities),
       customTags = Set<String>.unmodifiable(customTags),
       photoIds = Set<String>.unmodifiable(photoIds);

  final DateTime entryAt;
  final String mood;
  final String title;
  final String body;
  final Set<String> symptoms;
  final Set<String> activities;
  final Set<String> customTags;
  final Set<String> photoIds;
}
