# PATCH and DELETE API evidence

## Why this is separate from the Hospital Finder

The Hospital Finder correctly uses public read-only OpenStreetMap endpoints:

- GET for Nominatim and Photon search
- POST for Overpass nearby-hospital queries

It must not send PATCH or DELETE requests to those public data sources. The
app's own authenticated data API is Supabase PostgREST, which is where
EverCare's Create, Read, Update, and Delete operations occur.

## HTTP method map

| EverCare operation | Flutter/Supabase SDK call | HTTP method | Evidence |
| --- | --- | --- | --- |
| Read a journal | `.select()` | GET | `test/repositories/postgrest_http_method_test.dart` and Week 4 read evidence |
| Create a journal | `.insert()` | POST | `test/repositories/postgrest_http_method_test.dart` and Week 4 create evidence |
| Edit a journal | `.update()` | PATCH | `test/repositories/postgrest_http_method_test.dart` and `verify_supabase_journal_crud.ps1` |
| Delete a journal | `.delete()` | DELETE | `test/repositories/postgrest_http_method_test.dart` and `verify_supabase_journal_crud.ps1` |

The repository calls are owner-scoped and protected by Supabase Row Level
Security. The manual script does not use a service-role key; it uses only a
test user's access token and creates a temporary record that it removes.

## Capture the live evidence

1. Create a disposable EverCare account.
2. Obtain that account's short-lived access token from a local debug session.
3. Run `verify_supabase_journal_crud.ps1 -Run` using the commands in
   `README_SUBMISSION.md`.
4. Capture only the PASS lines. Do not capture the token, Authorization header,
   or a real user's record.
5. Confirm that no `EverCare Demo API verification` record remains.

This gives the instructor a reproducible transport-level PATCH and DELETE
verification without fabricating unsupported operations against the
OpenStreetMap API.
