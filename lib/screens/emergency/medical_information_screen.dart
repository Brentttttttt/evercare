import 'package:flutter/material.dart';

import '../../models/emergency_contact.dart';
import '../../repositories/emergency_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';

class MedicalInformationScreen extends StatefulWidget {
  const MedicalInformationScreen({super.key});

  @override
  State<MedicalInformationScreen> createState() =>
      _MedicalInformationScreenState();
}

class _MedicalInformationScreenState extends State<MedicalInformationScreen> {
  EmergencyRepository? _repository;
  EmergencyMedicalProfile? _profile;
  bool _initialized = false;
  bool _loading = true;
  bool _saving = false;
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
    _repository = EmergencyRepository(client!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Medical Information',
      actions: [
        if (_repository != null && !_loading && _profile != null)
          IconButton(
            tooltip: 'Edit medical information',
            onPressed: _saving ? null : _openEditor,
            icon: const Icon(Icons.edit_outlined),
          ),
      ],
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(36),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_repository == null) {
      return const EmptyStateCard(
        title: 'Sign in to see your medical ID',
        message:
            'Your emergency health details are stored with your EverCare account.',
        icon: Icons.lock_outline_rounded,
      );
    }
    if (_error != null) {
      return _MedicalError(message: _error!, onRetry: _load);
    }
    final profile = _profile!;
    if (!profile.hasMedicalDetails) {
      return Column(
        children: [
          const EmptyStateCard(
            title: 'Medical ID not set up',
            message:
                'Add allergies, conditions, and other details that may help in an emergency.',
            icon: Icons.medical_information_outlined,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _openEditor,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Medical Information'),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.danger, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryText.withValues(alpha: .08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.medical_information_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'EMERGENCY HEALTH CARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeader(
                  title: profile.fullName.isEmpty
                      ? 'EverCare Member'
                      : profile.fullName,
                  subtitle: profile.birthDate == null
                      ? 'Personal emergency medical information'
                      : 'Born ${_formatDate(profile.birthDate!)}',
                  trailing: CircleAvatar(
                    radius: 29,
                    backgroundColor: AppColors.lightGreen,
                    child: Text(
                      _initials(profile.fullName),
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (profile.bloodType.isNotEmpty)
                  _MedicalRow(label: 'Blood type', value: profile.bloodType),
                if (profile.allergies.isNotEmpty)
                  _MedicalRow(
                    label: 'Allergies',
                    value: profile.allergies.join(', '),
                  ),
                if (profile.conditions.isNotEmpty)
                  _MedicalRow(
                    label: 'Medical conditions',
                    value: profile.conditions.join(', '),
                  ),
                if (profile.preferredHospital.isNotEmpty)
                  _MedicalRow(
                    label: 'Preferred hospital',
                    value: profile.preferredHospital,
                  ),
                if (profile.medicalNotes.isNotEmpty)
                  _MedicalRow(
                    label: 'Medical notes',
                    value: profile.medicalNotes,
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Keep this information accurate. It does not replace professional medical records or advice.',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _repository!.fetchMedicalProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'EverCare could not load your medical information.';
      });
    }
  }

  Future<void> _openEditor() async {
    final result = await showDialog<_MedicalEditorResult>(
      context: context,
      builder: (_) => _MedicalEditorDialog(profile: _profile!),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await _repository!.saveMedicalProfile(
        bloodType: result.bloodType,
        allergies: result.allergies,
        conditions: result.conditions,
        preferredHospital: result.preferredHospital,
        medicalNotes: result.medicalNotes,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('EverCare could not save your medical information.'),
        ),
      );
    }
  }

  String _initials(String name) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return initials.isEmpty ? 'EC' : initials;
  }

  String _formatDate(DateTime value) {
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
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class _MedicalRow extends StatelessWidget {
  const _MedicalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _MedicalEditorDialog extends StatefulWidget {
  const _MedicalEditorDialog({required this.profile});

  final EmergencyMedicalProfile profile;

  @override
  State<_MedicalEditorDialog> createState() => _MedicalEditorDialogState();
}

class _MedicalEditorDialogState extends State<_MedicalEditorDialog> {
  late final TextEditingController _bloodType;
  late final TextEditingController _allergies;
  late final TextEditingController _conditions;
  late final TextEditingController _preferredHospital;
  late final TextEditingController _medicalNotes;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _bloodType = TextEditingController(text: profile.bloodType);
    _allergies = TextEditingController(text: profile.allergies.join(', '));
    _conditions = TextEditingController(text: profile.conditions.join(', '));
    _preferredHospital = TextEditingController(text: profile.preferredHospital);
    _medicalNotes = TextEditingController(text: profile.medicalNotes);
  }

  @override
  void dispose() {
    _bloodType.dispose();
    _allergies.dispose();
    _conditions.dispose();
    _preferredHospital.dispose();
    _medicalNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit medical information'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_bloodType, 'Blood type', Icons.bloodtype_outlined),
            _field(
              _allergies,
              'Allergies (separate with commas)',
              Icons.warning_amber_rounded,
            ),
            _field(
              _conditions,
              'Conditions (separate with commas)',
              Icons.monitor_heart_outlined,
            ),
            _field(
              _preferredHospital,
              'Preferred hospital',
              Icons.local_hospital_outlined,
            ),
            _field(
              _medicalNotes,
              'Medical notes',
              Icons.notes_rounded,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _MedicalEditorResult(
              bloodType: _bloodType.text.trim(),
              allergies: _split(_allergies.text),
              conditions: _split(_conditions.text),
              preferredHospital: _preferredHospital.text.trim(),
              medicalNotes: _medicalNotes.text.trim(),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  List<String> _split(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

class _MedicalEditorResult {
  const _MedicalEditorResult({
    required this.bloodType,
    required this.allergies,
    required this.conditions,
    required this.preferredHospital,
    required this.medicalNotes,
  });

  final String bloodType;
  final List<String> allergies;
  final List<String> conditions;
  final String preferredHospital;
  final String medicalNotes;
}

class _MedicalError extends StatelessWidget {
  const _MedicalError({required this.message, required this.onRetry});

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
