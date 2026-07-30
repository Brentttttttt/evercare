import 'package:flutter/material.dart';

import '../../models/journal_entry.dart';
import '../../widgets/app_page.dart';
import 'journal_entry_form.dart';

class AddJournalEntryScreen extends StatelessWidget {
  const AddJournalEntryScreen({super.key, this.entry});

  final JournalEntry? entry;

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: entry == null ? 'Write a Journal Entry' : 'Edit Journal Entry',
      child: JournalEntryForm(entry: entry),
    );
  }
}
