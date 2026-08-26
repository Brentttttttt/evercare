# EverCare Week 6 live demo runbook

## Before class

1. Install the latest debug APK or run the Flutter app on a phone/emulator.
2. Sign in using a disposable demo account.
3. Enter a few records from `sample_data/evercare_demo_dataset.json` through the normal UI.
4. Confirm internet access if you plan to demonstrate Hospital Finder or AI.
5. Run `flutter analyze`, `flutter test`, and `supabase migration list --linked`.
6. Run `verify_supabase_journal_crud.ps1 -Run` with the disposable account and save only its PASS output.
7. Capture a scrubbed Supabase Table Editor/schema screenshot. Do not show user rows, email addresses, IDs, health data, keys, or tokens.

## Demo path

| Time | Show | Key point |
| ---: | --- | --- |
| 0:00 | Home dashboard | Quick actions and the purpose of EverCare. |
| 0:30 | Bottom navigation | Eight organized feature areas; the arrow moves between labeled groups. |
| 1:00 | Journal create/read/update/delete | Validation, persistence, confirmation before deletion, and a refreshed list. |
| 3:00 | Hospital Finder | Real public API data with loading/retry/error handling. |
| 4:00 | Health result/history | BLE/manual capture, app-displayed corrected systolic, supportive range wording, and no diagnosis claim. |
| 5:00 | Care Book/Emergency | Older-adult care guidance, trusted contacts, and safe emergency direction. |
| 5:45 | Architecture + ERD | Flutter, Supabase/RLS, APIs, device integration, and data ownership. |
| 6:30 | Source/tests | Routes, Journal repository, hospital service, migration, and current test results. |

## If a live dependency fails

- **No internet:** show the Week 5 JSON/screenshot evidence and explain the retry/error UI.
- **No BP monitor:** use a saved fictional manual reading or Health UI test evidence; do not pretend a live BLE packet was received.
- **Supabase session expired:** sign in again. Do not bypass authentication or use a privileged key in the mobile app.
- **AI provider unavailable:** show the friendly on-screen fallback and explain that health safety guidance remains non-diagnostic.

## After the presentation

Delete all `EverCare Demo` entries, sign out of the disposable account, and remove any screenshots or logs that accidentally include private information.
