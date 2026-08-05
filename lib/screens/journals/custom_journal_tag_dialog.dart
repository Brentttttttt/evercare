import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

class CustomJournalTagDialog extends StatefulWidget {
  const CustomJournalTagDialog({required this.existingTags, super.key});

  final Iterable<String> existingTags;

  @override
  State<CustomJournalTagDialog> createState() => _CustomJournalTagDialogState();
}

class _CustomJournalTagDialogState extends State<CustomJournalTagDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.sell_outlined),
      title: const Text('Add your own detail'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a short label that helps you remember this moment.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _controller,
              autofocus: true,
              maxLength: 30,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Journal detail',
                hintText: 'Example: Family gathering',
              ),
              validator: _validate,
              onFieldSubmitted: (_) => _add(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _add, child: const Text('Add')),
      ],
    );
  }

  String? _validate(String? value) {
    final tag = value?.trim() ?? '';
    if (tag.isEmpty) return 'Enter a journal detail.';
    final duplicate = widget.existingTags.any(
      (existing) => existing.trim().toLowerCase() == tag.toLowerCase(),
    );
    if (duplicate) return 'That detail is already added.';
    return null;
  }

  void _add() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _controller.text.trim());
  }
}
