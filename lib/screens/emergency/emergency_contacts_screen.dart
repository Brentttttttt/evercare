import 'package:flutter/material.dart';

import '../../models/emergency_contact.dart';
import '../../repositories/emergency_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  EmergencyRepository? _repository;
  List<EmergencyContact> _contacts = const [];
  bool _initialized = false;
  bool _loading = true;
  bool _busy = false;
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
      title: 'Emergency Contacts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Save the people you trust to contact during an emergency.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(36),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_repository == null)
            const EmptyStateCard(
              title: 'Sign in to manage contacts',
              message:
                  'Your emergency contacts are stored with your EverCare account.',
              icon: Icons.lock_outline_rounded,
            )
          else if (_error != null)
            _ContactsError(message: _error!, onRetry: _load)
          else if (_contacts.isEmpty)
            const EmptyStateCard(
              title: 'No emergency contacts yet',
              message: 'Add a trusted person and choose a primary contact.',
              icon: Icons.contact_emergency_outlined,
            )
          else
            ..._contacts.map(
              (contact) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ContactCard(
                  contact: contact,
                  onEdit: _busy ? null : () => _openEditor(contact),
                ),
              ),
            ),
          const SizedBox(height: 6),
          if (_repository != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _openEditor(null),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1_outlined),
                label: Text(_busy ? 'Saving…' : 'Add Contact'),
              ),
            ),
          const SizedBox(height: 16),
          const AppCard(
            color: Color(0xFFFFF8EB),
            borderColor: Color(0xFFF8E1B6),
            child: Row(
              children: [
                Icon(Icons.support_agent_rounded, color: AppColors.warning),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency hotline', style: AppTextStyles.cardTitle),
                      SizedBox(height: 4),
                      Text(
                        'Use your Phone app to dial 911 for an immediate emergency.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
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
      final contacts = await repository.fetchContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'EverCare could not load your contacts. Please try again.';
      });
    }
  }

  Future<void> _openEditor(EmergencyContact? contact) async {
    final result = await showDialog<_ContactEditorResult>(
      context: context,
      builder: (_) => _ContactEditorDialog(contact: contact),
    );
    if (result == null || !mounted) return;
    if (result.deleteContact) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove this contact?'),
          content: const Text(
            'This permanently removes the contact from EverCare.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      if (result.deleteContact) {
        await _repository!.deleteContact(contact!.id);
      } else {
        await _repository!.saveContact(
          id: contact?.id,
          name: result.name,
          relationship: result.relationship,
          phoneNumber: result.phoneNumber,
          isPrimary: result.isPrimary,
        );
      }
      if (!mounted) return;
      setState(() => _busy = false);
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('EverCare could not save this contact.')),
      );
    }
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.onEdit});

  final EmergencyContact contact;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: contact.isPrimary ? AppColors.lightGreen : null,
      borderColor: contact.isPrimary ? AppColors.lightGreen : null,
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: Colors.white,
            child: Text(
              contact.initials,
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(contact.name, style: AppTextStyles.cardTitle),
                    ),
                    if (contact.isPrimary)
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.warning,
                        size: 19,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(contact.relationship, style: AppTextStyles.bodyMuted),
                const SizedBox(height: 5),
                Text(contact.phoneNumber, style: AppTextStyles.body),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit contact',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _ContactEditorDialog extends StatefulWidget {
  const _ContactEditorDialog({this.contact});

  final EmergencyContact? contact;

  @override
  State<_ContactEditorDialog> createState() => _ContactEditorDialogState();
}

class _ContactEditorDialogState extends State<_ContactEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _relationship;
  late final TextEditingController _phone;
  late bool _isPrimary;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.contact?.name);
    _relationship = TextEditingController(text: widget.contact?.relationship);
    _phone = TextEditingController(text: widget.contact?.phoneNumber);
    _isPrimary = widget.contact?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.contact == null ? 'Add emergency contact' : 'Edit contact',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _relationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.family_restroom_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: _required,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Primary contact'),
                subtitle: const Text('Contact this person first'),
                value: _isPrimary,
                onChanged: (value) => setState(() => _isPrimary = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.contact != null)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              const _ContactEditorResult(deleteContact: true),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(
              context,
              _ContactEditorResult(
                name: _name.text.trim(),
                relationship: _relationship.text.trim(),
                phoneNumber: _phone.text.trim(),
                isPrimary: _isPrimary,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
}

class _ContactEditorResult {
  const _ContactEditorResult({
    this.name = '',
    this.relationship = '',
    this.phoneNumber = '',
    this.isPrimary = false,
    this.deleteContact = false,
  });

  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isPrimary;
  final bool deleteContact;
}

class _ContactsError extends StatelessWidget {
  const _ContactsError({required this.message, required this.onRetry});

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
