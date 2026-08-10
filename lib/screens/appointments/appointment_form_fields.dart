import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../models/hospital_location.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../hospitals/hospital_finder_screen.dart';

enum _LocationEntryMode { manual, openStreetMap }

class AppointmentFormController {
  AppointmentFormController([Appointment? appointment])
    : title = TextEditingController(text: appointment?.title),
      doctorName = TextEditingController(text: appointment?.doctorName),
      clinic = TextEditingController(text: appointment?.clinic),
      address = TextEditingController(text: appointment?.address),
      notes = TextEditingController(text: appointment?.notes),
      specialty = appointment?.specialty ?? specialties.first,
      date = appointment == null
          ? DateUtils.dateOnly(DateTime.now())
          : DateUtils.dateOnly(appointment.startsAt),
      time = appointment == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(appointment.startsAt);

  static const specialties = [
    'General Physician',
    'Internal Medicine',
    'Dentist',
    'Endocrinologist',
    'Ophthalmologist',
    'Cardiologist',
    'Other',
  ];

  final TextEditingController title;
  final TextEditingController doctorName;
  final TextEditingController clinic;
  final TextEditingController address;
  final TextEditingController notes;
  String specialty;
  DateTime date;
  TimeOfDay time;

  DateTime get startsAt =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  void dispose() {
    title.dispose();
    doctorName.dispose();
    clinic.dispose();
    address.dispose();
    notes.dispose();
  }
}

class AppointmentFormFields extends StatefulWidget {
  const AppointmentFormFields({required this.controller, super.key});

  final AppointmentFormController controller;

  @override
  State<AppointmentFormFields> createState() => _AppointmentFormFieldsState();
}

class _AppointmentFormFieldsState extends State<AppointmentFormFields> {
  _LocationEntryMode _locationMode = _LocationEntryMode.manual;
  HospitalLocation? _selectedHospital;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final specialties =
        AppointmentFormController.specialties.contains(controller.specialty)
        ? AppointmentFormController.specialties
        : [controller.specialty, ...AppointmentFormController.specialties];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppointmentFormSection(
          title: 'Visit details',
          description: 'Name the visit and care provider.',
          children: [
            _field(
              controller: controller.title,
              label: 'Appointment title',
              hint: 'e.g. General check-up',
              icon: Icons.event_note_outlined,
              required: true,
            ),
            _field(
              controller: controller.doctorName,
              label: 'Doctor or provider name',
              hint: 'Enter the provider name',
              icon: Icons.person_outline_rounded,
              required: true,
            ),
            DropdownButtonFormField<String>(
              initialValue: controller.specialty,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Specialty',
                prefixIcon: Icon(
                  Icons.medical_services_outlined,
                  color: AppColors.primaryGreen,
                ),
              ),
              items: specialties
                  .map(
                    (specialty) => DropdownMenuItem(
                      value: specialty,
                      child: Text(specialty, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) controller.specialty = value;
              },
            ),
          ],
        ),
        const SizedBox(height: 22),
        _AppointmentFormSection(
          title: 'Hospital',
          description: 'Enter a location or choose one from the map.',
          children: [
            _HospitalEntryChoice(
              selected: _locationMode,
              onChanged: (mode) => setState(() => _locationMode = mode),
            ),
            const SizedBox(height: 14),
            if (_locationMode == _LocationEntryMode.openStreetMap) ...[
              _MapHospitalPicker(
                selectedHospital: _selectedHospital,
                existingHospitalName: controller.clinic.text,
                onPick: _pickHospital,
              ),
              const SizedBox(height: 14),
            ],
            _field(
              controller: controller.clinic,
              label: 'Clinic or hospital',
              hint: _locationMode == _LocationEntryMode.manual
                  ? 'Enter the clinic name'
                  : 'Choose a hospital from OpenStreetMap',
              icon: Icons.local_hospital_outlined,
              required: true,
              readOnly: _locationMode == _LocationEntryMode.openStreetMap,
            ),
            _field(
              controller: controller.address,
              label: 'Address',
              hint: _locationMode == _LocationEntryMode.manual
                  ? 'Clinic address'
                  : 'Filled from your map selection',
              icon: Icons.location_on_outlined,
              readOnly: _locationMode == _LocationEntryMode.openStreetMap,
              bottomPadding: 0,
            ),
          ],
        ),
        const SizedBox(height: 22),
        _AppointmentFormSection(
          title: 'Date and time',
          description: 'Choose when the visit is scheduled.',
          children: [
            _PickerField(
              label: 'Date',
              value: _dateLabel(controller.date),
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),
            _PickerField(
              label: 'Time',
              value: controller.time.format(context),
              icon: Icons.schedule_rounded,
              onTap: _pickTime,
              bottomPadding: 0,
            ),
          ],
        ),
        const SizedBox(height: 22),
        _AppointmentFormSection(
          title: 'Notes',
          description: 'Add anything helpful to remember before the visit.',
          children: [
            _field(
              controller: controller.notes,
              label: 'Notes',
              hint: 'Optional reminders for this visit',
              icon: Icons.notes_rounded,
              maxLines: 4,
              bottomPadding: 0,
            ),
          ],
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    bool readOnly = false,
    double bottomPadding = 14,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
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

  Future<void> _pickHospital() async {
    final hospital = await Navigator.push<HospitalLocation>(
      context,
      EverCarePageRoute(
        builder: (_) => const HospitalFinderScreen(allowSelection: true),
      ),
    );
    if (hospital == null || !mounted) return;
    final hospitalName = hospital.name.trim();
    final hospitalAddress = hospital.address.trim();
    setState(() {
      _selectedHospital = hospital;
      widget.controller.clinic.text = hospitalName;
      widget.controller.address.text = hospitalAddress;
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: widget.controller.date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() => widget.controller.date = selected);
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: widget.controller.time,
    );
    if (selected != null && mounted) {
      setState(() => widget.controller.time = selected);
    }
  }
}

class _HospitalEntryChoice extends StatelessWidget {
  const _HospitalEntryChoice({required this.selected, required this.onChanged});

  final _LocationEntryMode selected;
  final ValueChanged<_LocationEntryMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How would you like to add the hospital?',
          style: AppTextStyles.label,
        ),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
            // Keep the two choices beside each other on standard phone widths.
            // Stacking is reserved for genuinely constrained accessibility
            // layouts, where two readable touch targets can no longer fit.
            final vertical = constraints.maxWidth < 220 || textScale > 1.8;
            final options = [
              _LocationModeOption(
                label: 'Type manually',
                icon: Icons.edit_location_alt_outlined,
                selected: selected == _LocationEntryMode.manual,
                onTap: () => onChanged(_LocationEntryMode.manual),
              ),
              _LocationModeOption(
                label: 'OpenStreetMap',
                icon: Icons.map_outlined,
                selected: selected == _LocationEntryMode.openStreetMap,
                onTap: () => onChanged(_LocationEntryMode.openStreetMap),
              ),
            ];
            return Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: vertical
                  ? Column(
                      children: [
                        options.first,
                        const SizedBox(height: 3),
                        options.last,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: options.first),
                        const SizedBox(width: 3),
                        Expanded(child: options.last),
                      ],
                    ),
            );
          },
        ),
        const SizedBox(height: 7),
        const Text(
          'You can type the details yourself or search nearby hospitals.',
          style: AppTextStyles.small,
        ),
      ],
    );
  }
}

class _LocationModeOption extends StatelessWidget {
  const _LocationModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.card : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        elevation: selected ? .8 : 0,
        shadowColor: AppColors.shadow,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? AppColors.primaryGreen
                        : AppColors.secondaryText,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label.copyWith(
                        color: selected
                            ? AppColors.primaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapHospitalPicker extends StatelessWidget {
  const _MapHospitalPicker({
    required this.selectedHospital,
    required this.existingHospitalName,
    required this.onPick,
  });

  final HospitalLocation? selectedHospital;
  final String existingHospitalName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hasExistingName = existingHospitalName.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selectedHospital == null
            ? AppColors.muted
            : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selectedHospital == null
              ? AppColors.border
              : AppColors.primaryGreen.withValues(alpha: .45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedHospital?.name ??
                          (hasExistingName
                              ? existingHospitalName
                              : 'No hospital selected'),
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      selectedHospital?.address.isNotEmpty == true
                          ? selectedHospital!.address
                          : 'Search nearby hospitals or look up a hospital by name.',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.map_rounded),
              label: Text(
                selectedHospital == null
                    ? 'Find a Hospital on OpenStreetMap'
                    : 'Change Hospital',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.bottomPadding = 14,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
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
            prefixIcon: Icon(icon, color: AppColors.primaryGreen),
            suffixIcon: const Icon(Icons.chevron_right_rounded),
          ),
          child: Text(value),
        ),
      ),
    );
  }
}

class _AppointmentFormSection extends StatelessWidget {
  const _AppointmentFormSection({
    required this.title,
    required this.description,
    required this.children,
  });

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
          child: Text(title, style: AppTextStyles.cardTitle),
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(description, style: AppTextStyles.bodyMuted),
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

String _dateLabel(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
