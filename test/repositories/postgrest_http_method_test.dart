import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  test(
    'EverCare CRUD builders send GET, POST, PATCH, and DELETE to PostgREST',
    () async {
      final methods = <String>[];
      final paths = <String>[];
      final client = PostgrestClient(
        'https://example.test/rest/v1',
        httpClient: MockClient((request) async {
          methods.add(request.method);
          paths.add(request.url.path);
          return http.Response(
            '[]',
            200,
            headers: const {'content-type': 'application/json'},
            request: request,
          );
        }),
      );

      addTearDown(client.dispose);

      await client.from('journal_entries').select('id,title');
      await client.from('journal_entries').insert({
        'title': 'EverCare Demo Entry',
        'body': 'Temporary non-PHI test entry.',
      });
      await client
          .from('journal_entries')
          .update({'title': 'EverCare Demo Entry Updated'})
          .eq('id', 'demo-entry-id');
      await client.from('journal_entries').delete().eq('id', 'demo-entry-id');

      expect(methods, ['GET', 'POST', 'PATCH', 'DELETE']);
      expect(paths, everyElement('/rest/v1/journal_entries'));
    },
  );
}
