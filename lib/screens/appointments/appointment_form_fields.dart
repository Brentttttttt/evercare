import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../theme/app_colors.dart';

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
        _field(
          controller: controller.clinic,
          label: 'Clinic or hospital',
          hint: 'Enter the clinic name',
          icon: Icons.local_hospital_outlined,
          required: true,
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
          hint: 'Clinic address',
          icon: Icons.location_on_outlined,
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
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
