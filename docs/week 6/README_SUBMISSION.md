# EverCare - Week 6 Midterm Evidence Pack

**Project:** EverCare  
**Student:** Brent Lawrence C. Bernardo  
**Section:** ITE231  
**Instructor:** Mr. Paul John DC Cabance  
**Prepared:** August 26, 2026

This folder turns the Week 6 checklist into a practical, honest demonstration package. It supplements the existing Week 4 CRUD and Week 5 API submissions; it does not replace them.

## Contents

| Artifact | Purpose |
| --- | --- |
| `MIDTERM_READINESS.md` | Rubric-by-rubric readiness, evidence, and a live demo sequence. |
| `system_architecture.mmd` and `.png` | Updated system flowchart / architecture diagram. |
| `database_erd.mmd` and `.png` | Detailed database ERD derived from the versioned Supabase migrations. |
| `database_schema_overview.mmd` and `.png` | Slide-friendly overview of the owner-scoped data model. |
| `sample_data/` | Clearly fictional, non-personal records for a disposable demo account. |
| `verify_supabase_journal_crud.ps1` | Safe, authenticated Supabase REST verification for GET, POST, PATCH, and DELETE. |

## Before the midterm presentation

Run these commands from the project root:

```powershell
flutter pub get
flutter analyze
flutter test
supabase migration list --linked
```

The migration command should show each local migration with a matching remote migration. It verifies that the versioned database schema used by the app is also applied to the linked Supabase project.

### Verify every CRUD HTTP method

The Hospital Finder uses public read-only OpenStreetMap services, so it appropriately uses only GET and POST. EverCare's private CRUD API is Supabase PostgREST. Use the supplied script with a **disposable signed-in test account** to make and clean up one temporary journal record:

```powershell
$env:SUPABASE_URL = 'https://wcssuruygqextigpobcb.supabase.co'
$env:SUPABASE_PUBLISHABLE_KEY = '<publishable key>'
$env:SUPABASE_ACCESS_TOKEN = '<test account access token>'
.\docs\week 6\verify_supabase_journal_crud.ps1 -Run
```

The script proves successful `GET`, `POST`, `PATCH`, and `DELETE` requests, then confirms that its temporary non-PHI record was removed. It never uses a service-role key and it refuses to run without the explicit `-Run` switch. Keep the console output as the Week 6 PATCH/DELETE evidence.

## Existing supporting evidence

- **Week 4:** `docs/week 4/` contains a live Journal Create/Read/Update/Delete walkthrough, validation screenshots, deletion confirmation, and verification results.
- **Week 5:** `docs/week 5/` contains genuine OpenStreetMap GET/POST request examples, JSON responses, UI screenshots, and error-handling evidence.
- **Current source:** the Flutter app, Supabase migrations, owner-scoped RLS, automated tests, BLE capture, Health, Care Book, medications, appointments, journals, emergency information, and caregiver features are all in this repository.

## Important privacy rule

Use only the supplied fictional records and a disposable test account for a classroom demonstration. Do not place a real person's health information, access token, password, API key, or private contact information in screenshots, slides, console logs, or submitted files.
