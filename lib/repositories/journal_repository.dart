import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal_entry.dart';

class JournalRepository {
  JournalRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Sign in to use journals.');
    return id;
  }

  Future<List<JournalEntry>> fetchEntries() async {
    final rows = await _client
        .from('journal_entries')
        .select()
        .eq('user_id', _userId)
        .order('entry_at', ascending: false);
    return rows.map(JournalEntry.fromMap).toList(growable: false);
  }

  Future<JournalEntry> createEntry({
    required DateTime entryAt,
    required String title,
    required String body,
    required String mood,
    required List<String> symptoms,
    required List<String> activities,
  }) async {
    final row = await _client
        .from('journal_entries')
        .insert({
          'user_id': _userId,
          'entry_at': entryAt.toUtc().toIso8601String(),
          'title': title.trim(),
          'body': body.trim(),
          'mood': mood,
          'symptoms': symptoms,
          'activities': activities,
          'tags': <String>[],
          'bookmarked': false,
        })
        .select()
        .single();
    return JournalEntry.fromMap(row);
  }

  Future<JournalEntry> updateEntry({
    required String id,
    required DateTime entryAt,
    required String title,
    required String body,
    required String mood,
    required List<String> symptoms,
    required List<String> activities,
  }) async {
    final row = await _client
        .from('journal_entries')
        .update({
          'entry_at': entryAt.toUtc().toIso8601String(),
          'title': title.trim(),
          'body': body.trim(),
          'mood': mood,
          'symptoms': symptoms,
          'activities': activities,
        })
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();
    return JournalEntry.fromMap(row);
  }

  Future<void> setBookmarked(String id, {required bool bookmarked}) async {
    await _client
        .from('journal_entries')
        .update({'bookmarked': bookmarked})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> deleteEntry(String id) async {
    await _client
        .from('journal_entries')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
