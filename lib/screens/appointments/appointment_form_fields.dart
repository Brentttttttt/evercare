import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../models/hospital_location.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../hospitals/hospital_finder_screen.dart';

enum _LocationEntryMode { manual, googleMaps }

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
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
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
        ),
        _HospitalEntryChoice(
          selected: _locationMode,
          onChanged: (mode) => setState(() => _locationMode = mode),
        ),
        const SizedBox(height: 14),
        if (_locationMode == _LocationEntryMode.googleMaps) ...[
          _GoogleHospitalPicker(
            selectedHospital: _selectedHospital,
            existingHospitalName: controller.clinic.text,
            onPick: _pickHospital,
          ),
          const SizedBox(height: 16),
        ],
        _field(
          controller: controller.clinic,
          label: 'Clinic or hospital',
          hint: _locationMode == _LocationEntryMode.manual
              ? 'Enter the clinic name'
              : 'Choose a hospital from Google Maps',
          icon: Icons.local_hospital_outlined,
          required: true,
          readOnly: _locationMode == _LocationEntryMode.googleMaps,
        ),
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
        ),
        _field(
          controller: controller.address,
          label: 'Address',
          hint: _locationMode == _LocationEntryMode.manual
              ? 'Clinic address'
              : 'Filled from your Google Maps selection',
          icon: Icons.location_on_outlined,
          readOnly: _locationMode == _LocationEntryMode.googleMaps,
        ),
        _field(
          controller: controller.notes,
          label: 'Notes',
          hint: 'Optional reminders for this visit',
          icon: Icons.notes_rounded,
          maxLines: 4,
        ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
    setState(() {
      _selectedHospital = hospital;
      widget.controller.clinic.text = hospital.name;
      widget.controller.address.text = hospital.address;
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
    return AppCard(
      padding: const EdgeInsets.all(15),
      color: AppColors.lightGreen,
      borderColor: const Color(0xFFC8E3D5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How would you like to add the hospital?',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 5),
          const Text(
            'Type the details yourself or find a hospital with Google Maps.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_LocationEntryMode>(
              showSelectedIcon: true,
              selected: {selected},
              onSelectionChanged: (selection) => onChanged(selection.first),
              segments: const [
                ButtonSegment(
                  value: _LocationEntryMode.manual,
                  icon: Icon(Icons.edit_location_alt_outlined),
                  label: Text('Type manually'),
                ),
                ButtonSegment(
                  value: _LocationEntryMode.googleMaps,
                  icon: Icon(Icons.map_outlined),
                  label: Text('Google Maps'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleHospitalPicker extends StatelessWidget {
  const _GoogleHospitalPicker({
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
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: selectedHospital == null
          ? AppColors.border
          : AppColors.primaryGreen,
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
                  borderRadius: BorderRadius.circular(14),
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
            child: FilledButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.map_rounded),
              label: Text(
                selectedHospital == null
                    ? 'Find a Hospital on Google Maps'
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
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
