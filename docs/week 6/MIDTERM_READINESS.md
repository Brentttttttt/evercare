# EverCare Week 6 Midterm Readiness

This report maps the practical Week 6 rubric to concrete, reviewable project evidence. It is intentionally careful to distinguish completed implementation from evidence that must still be captured during a signed-in demo.

## Rubric readiness

| Rubric area | Points | Current evidence | Readiness |
| --- | ---: | --- | --- |
| UI/UX implementation | 20 | Shared EverCare theme, reusable components, senior-friendly layout, responsive widget tests, validation, empty/loading/retry states, and accessibility settings. | Ready |
| Navigation and structure | 20 | Eight top-level areas in `MainShell`, centralized `AppRoutes`, labeled paged bottom navigation, Home quick actions, and route/widget tests. | Ready |
| CRUD features | 30 | Owner-scoped Journal Create/Read/Update/Delete, validation, destructive-delete confirmation, RLS, Week 4 walkthrough/screenshots, plus the current PostgREST method test. | Ready |
| API integration | 20 | OpenStreetMap GET/POST integration and tests; Supabase CRUD transport test covers GET/POST/PATCH/DELETE; signed-in proof script is included. | Ready after one live script capture |
| Presentation | 10 | `LIVE_DEMO_RUNBOOK.md`, architecture diagram, ERD, and code-walkthrough targets. | Ready to rehearse |

## Unchecked midterm checklist items

| Original checklist item | What is now available | Remaining presenter action |
| --- | --- | --- |
| Updated system flowchart / architecture diagram | `system_architecture.png` and editable `system_architecture.mmd` | Insert the PNG in the slides; retain the Mermaid source for editing. |
| PUT/PATCH requests tested | Automated mocked PostgREST transport test and authenticated live verification script | Run the script once with a disposable test account and retain the PASS output. EverCare uses PATCH; no PUT is required by its API. |
| DELETE requests tested | Automated mocked PostgREST transport test and authenticated live verification script | Run the script once with a disposable test account and retain the PASS output. |
| Sample data available for testing | `sample_data/evercare_demo_dataset.json` and safe-use instructions | Enter only fictional `EverCare Demo` records in a disposable account, then remove them. |
| Database screenshot | Accurate `database_erd.mmd`, derived from applied migrations | Capture one real Supabase Table Editor or schema screenshot after sign-in, with no user rows, identities, keys, or health data visible. Do not fabricate this evidence. |

## Architecture and database evidence

- `system_architecture.png` shows the Flutter presentation layer, repositories/services, BLE monitor path, Supabase Auth/PostgREST/RLS/Storage/Edge Functions, OpenStreetMap services, and AI provider boundary.
- `database_erd.png` reflects the 11 public tables in the five versioned migrations: profiles, medical profiles, medications, dose events, appointments, journals, journal photos, emergency contacts, caregiver relationships, blood-pressure readings, and notifications. `database_schema_overview.png` is the simpler presentation version.
- `supabase migration list --linked` verifies that all five local migrations are also applied to the linked remote project.

## Five-to-eight minute live demonstration

1. **Problem and scope (30 seconds):** EverCare supports Filipino seniors, family members, and caregivers; it is a care companion, not a diagnostic tool.
2. **Navigation and UI (45 seconds):** Open Home, point out quick actions, then use the labeled navigation arrows to show the 8 main areas.
3. **Journal CRUD (2 minutes):** Use one fictional `EverCare Demo` entry to create, open/read, edit, search or view in the list, and delete after the confirmation dialog.
4. **Health (1 minute):** Show a completed BLE or manual reading, its range-oriented explanation, saved history, and the non-diagnostic disclaimer. Never present sample data as a real diagnosis.
5. **Hospital Finder API (1 minute):** Search for a hospital or use nearby search. Explain that Nominatim/Photon use GET and Overpass uses POST; show loading/error handling if the network is unavailable.
6. **Database and security (45 seconds):** Open the ERD and explain owner-scoped Row Level Security and private journal photos.
7. **Code walkthrough (45 seconds):** Show `lib/routes/app_routes.dart`, `lib/repositories/journal_repository.dart`, `lib/services/hospital_finder_service.dart`, and `supabase/migrations/20260730140000_create_evercare_schema.sql`.
8. **Testing and remaining work (30 seconds):** Show the current verification file, explain the mock transport test plus live PATCH/DELETE script, and state only genuine remaining future scope.

## Questions to be ready for

| Likely question | Short answer |
| --- | --- |
| How is data protected? | Supabase Auth and Row Level Security scope private records to their owner. The mobile app has only the public project key, never a service-role key. |
| How do CRUD methods map to HTTP? | PostgREST maps select to GET, insert to POST, update to PATCH, and delete to DELETE. The project has an automated transport test and a signed-in cleanup script. |
| Why no PUT against OpenStreetMap? | The hospital services are public read-only search services. Sending update/delete requests there would be incorrect; EverCare's own Supabase API provides authenticated PATCH/DELETE. |
| Does one BP reading diagnose a person? | No. EverCare describes the range of that measurement only and asks users to repeat readings and consult a qualified professional when appropriate. |
| What happens if an API fails? | Screens show clear loading, retry, empty, permission, timeout, and network-error states rather than silently failing. |

## Presentation safeguards

- Use a disposable account and the supplied fictional sample data.
- Never show a password, access token, API key, service-role key, raw BLE packet with identity, or real health/contact record.
- Do not use the older Week 3 presentation as the current midterm deck; its dates and project state are outdated.
- Do not claim tablet/landscape support; the phone-first app is intentionally locked to portrait orientation.
