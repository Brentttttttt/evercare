import 'package:flutter/material.dart';

import '../../widgets/app_page.dart';
import 'journal_entry_form.dart';

class AddJournalEntryScreen extends StatelessWidget {
  const AddJournalEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DetailPage(
      title: 'Write a Journal Entry',
      child: JournalEntryForm(),
    );
  }
}
