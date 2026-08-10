import 'package:flutter/material.dart';

import '../../models/medication.dart';
import '../../repositories/medication_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_backend_scope.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({
    super.key,
    this.medication,
    this.isEditing = false,
  });

  final Medication? medication;
  final bool isEditing;

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dosage;
  late final TextEditingController _purpose;
  late final TextEditingController _frequency;
  late final TextEditingController _instructions;
  final _reminderTimeKey = GlobalKey<FormFieldState<TimeOfDay>>();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _scheduleTime;
  late bool _isActive;
  bool _saving = false;

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    final item = widget.medication;
    _name = TextEditingController(text: item?.name);
    _dosage = TextEditingController(text: item?.dosage);
    _purpose = TextEditingController(text: item?.purpose);
    _frequency = TextEditingController(text: item?.frequency);
    _instructions = TextEditingController(text: item?.instructions);
    _startDate = item?.startDate;
    _endDate = item?.endDate;
    _scheduleTime = _parseTime(item?.scheduleTime);
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _purpose.dispose();
    _frequency.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && widget.medication == null) {
      return const DetailPage(
        title: 'Edit Medication',
        child: _UnavailableEditCard(),
      );
    }

    final client = EverCareBackendScope.maybeClient(context);
    final canSave = client?.auth.currentUser != null;
    return DetailPage(
      title: _isEditing ? 'Edit Medication' : 'Add Medication',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MedicationSafetyNotice(),
            const SizedBox(height: 24),
            _MedicationFormSection(
              icon: Icons.medication_outlined,
              title: 'Medicine',
              description: 'Name, dose, and reason for taking it.',
              children: [
                _field(
                  controller: _name,
                  label: 'Medicine name',
                  hint: 'Enter the medicine name',
                  icon: Icons.medication_outlined,
                  required: true,
                ),
                _field(
                  controller: _dosage,
                  label: 'Dosage',
                  hint: 'e.g. 5 mg · One tablet',
                  icon: Icons.scale_outlined,
                  required: true,
                ),
                _field(
                  controller: _purpose,
                  label: 'Purpose',
                  hint: 'What was it prescribed for?',
                  icon: Icons.health_and_safety_outlined,
                  bottomPadding: 0,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _MedicationFormSection(
              icon: Icons.schedule_outlined,
              title: 'Schedule',
              description: 'When this medicine should be taken.',
              children: [
                _field(
                  controller: _frequency,
                  label: 'Frequency',
                  hint: 'e.g. Once daily',
                  icon: Icons.repeat_rounded,
                  required: true,
                ),
                _DateTile(
                  label: 'Start date',
                  value: _startDate,
                  icon: Icons.event_outlined,
                  onTap: () => _pickDate(isStart: true),
                ),
                _DateTile(
                  label: 'End date (optional)',
                  value: _endDate,
                  icon: Icons.event_available_outlined,
                  onTap: () => _pickDate(isStart: false),
                  onClear: _endDate == null
                      ? null
                      : () => setState(() => _endDate = null),
                ),
                FormField<TimeOfDay>(
                  key: _reminderTimeKey,
                  initialValue: _scheduleTime,
                  validator: (value) =>
                      value == null ? 'Reminder time is required.' : null,
                  builder: (field) => _DateTile(
                    label: 'Reminder time',
                    valueLabel: _scheduleTime?.format(context),
                    emptyLabel: 'Select reminder time',
                    errorText: field.errorText,
                    icon: Icons.schedule_rounded,
                    onTap: _pickTime,
                    bottomPadding: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _MedicationFormSection(
              icon: Icons.notes_rounded,
              title: 'Instructions and status',
              description: 'Add care notes and choose where it appears.',
              children: [
                _field(
                  controller: _instructions,
                  label: 'Instructions',
                  hint: 'Add label or care-team instructions',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
                Material(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.fromLTRB(14, 4, 10, 4),
                    title: const Text('Active medication'),
                    subtitle: const Text(
                      'Show this medicine in the active list',
                    ),
                    secondary: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.primaryGreen,
                    ),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!canSave)
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text(
                  'Sign in before saving medication information.',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canSave && !_saving ? _submit : null,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _saving
                      ? 'Saving…'
                      : _isEditing
                      ? 'Save Changes'
                      : 'Save Medication',
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    double bottomPadding = 14,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        scrollPadding: const EdgeInsets.only(bottom: 140),
        textInputAction: maxLines == 1
            ? TextInputAction.next
            : TextInputAction.newline,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryGreen),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? '$label is required.'
                  : null
            : null,
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime(2000) : (_startDate ?? DateTime(2000));
    final lastDate = DateTime(2100);
    final candidate = current ?? _startDate ?? DateTime.now();
    final initialDate = candidate.isBefore(firstDate) ? firstDate : candidate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = selected;
        if (_endDate != null && _endDate!.isBefore(selected)) _endDate = null;
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _scheduleTime ?? TimeOfDay.now(),
    );
    if (selected == null || !mounted) return;
    setState(() => _scheduleTime = selected);
    _reminderTimeKey.currentState?.didChange(selected);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final scheduleTime = _scheduleTime;
    if (scheduleTime == null) return;
    final client = EverCareBackendScope.maybeClient(context);
    if (client?.auth.currentUser == null) return;
    setState(() => _saving = true);
    final repository = MedicationRepository(client!);
    final time =
        '${scheduleTime.hour.toString().padLeft(2, '0')}:'
        '${scheduleTime.minute.toString().padLeft(2, '0')}:00';
    try {
      final item = widget.medication;
      if (item == null) {
        await repository.create(
          name: _name.text,
          dosage: _dosage.text,
          purpose: _purpose.text,
          frequency: _frequency.text,
          instructions: _instructions.text,
          scheduleTime: time,
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
        );
      } else {
        await repository.update(
          item.id,
          name: _name.text,
          dosage: _dosage.text,
          purpose: _purpose.text,
          frequency: _frequency.text,
          instructions: _instructions.text,
          scheduleTime: time,
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the medication. Please try again.'),
        ),
      );
    }
  }
}

class _MedicationSafetyNotice extends StatelessWidget {
  const _MedicationSafetyNotice();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.primaryContainer,
      borderColor: AppColors.primaryGreen.withValues(alpha: .18),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              size: 21,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep details accurate',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.primaryContainerForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Save only the details shown on your medicine label or provided by your care team.',
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: AppColors.primaryContainerForeground.withValues(
                      alpha: .78,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationFormSection extends StatelessWidget {
  const _MedicationFormSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: AppColors.darkGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(description, style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.value,
    this.valueLabel,
    this.emptyLabel = 'Not set',
    this.errorText,
    this.onClear,
    this.bottomPadding = 14,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final DateTime? value;
  final String? valueLabel;
  final String emptyLabel;
  final String? errorText;
  final VoidCallback? onClear;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: errorText,
            prefixIcon: Icon(icon, color: AppColors.primaryGreen),
            suffixIcon: onClear == null
                ? const Icon(Icons.chevron_right_rounded)
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          child: Text(
            valueLabel ?? (value == null ? emptyLabel : _dateLabel(value)),
          ),
        ),
      ),
    );
  }
}

class _UnavailableEditCard extends StatelessWidget {
  const _UnavailableEditCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Text(
        'This medication record is no longer available. Return to Medications and select a saved record.',
        style: AppTextStyles.bodyMuted,
      ),
    );
  }
}

TimeOfDay? _parseTime(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'Not set';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
