# EverCare Week 6 presentation outline

Use this as the current midterm presentation structure. It replaces the old Week 3 project-state narrative; do not reuse old screenshots, old test counts, or mock-data claims.

## Slide 1 - EverCare

- Care companion for Filipino seniors, family members, and caregivers
- SDG 3: Good Health and Well-Being
- Presenter, section, and date

## Slide 2 - Problem and project scope

- Daily care information is spread across notes, schedules, and appointments
- EverCare organizes medicines, appointments, journals, emergency details, care connections, and BP records
- It is not a diagnostic or emergency-replacement system

## Slide 3 - Current system architecture

- Use `system_architecture.png` (the `.mmd` source remains editable)
- Flutter UI and navigation
- Repositories/services, Supabase Auth/PostgREST/RLS/Storage/Edge Functions
- BLE BP monitor, OpenStreetMap APIs, and AI boundary

## Slide 4 - UI and navigation

- Consistent elderly-friendly design, readable type, empty/loading/error states
- Eight organized areas with labeled navigation groups and Home quick actions
- Responsive layout and large-text/reduced-motion support

## Slide 5 - CRUD demonstration

- Journal entry Create, Read, Update, Delete
- Required-field validation, unsaved-change protection, delete confirmation
- Owner-scoped data and row-level security
- Use Week 4 screenshots plus one fresh non-PHI demo record

## Slide 6 - Database design and security

- Use `database_schema_overview.png` for the slide and keep `database_erd.png` ready for detailed questions
- Explain user ownership, foreign keys, RLS, timestamps, and private journal photo storage
- Insert one scrubbed Supabase schema/Table Editor screenshot

## Slide 7 - API integration and testing

- Hospital Finder: Nominatim/Photon GET and Overpass POST
- Supabase PostgREST: GET, POST, PATCH, DELETE for private CRUD data
- Show the fresh verification output and one PATCH/DELETE proof capture

## Slide 8 - Health and care features

- BLE/manual BP capture, corrected app-displayed systolic, history and trend
- Friendly range wording: a reading category is not a diagnosis
- Care Book, emergency contacts, trusted caregivers, appointments, and medicine schedules

## Slide 9 - Testing, limits, and next steps

- `flutter analyze`, automated test suite, migration verification
- Current limits: phone-first portrait layout; public map/AI availability depends on network; BP data is not medically verified
- Remaining final-project scope only, not work already completed

## Slide 10 - Live walkthrough and questions

- Follow `LIVE_DEMO_RUNBOOK.md`
- Keep the source code, ERD, and API proof ready for questions
