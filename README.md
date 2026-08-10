# EverCare

EverCare is a Flutter care companion for Filipino seniors, family members, and
caregivers. It organizes blood-pressure readings, medicines, appointments,
journals, emergency details, and trusted-care relationships in one accessible
interface.

The project supports **United Nations SDG 3: Good Health and Well-Being** by
making everyday care information easier to record and review. EverCare is not
a diagnostic tool, and saved blood-pressure readings are never presented as
medically verified.

## Current Features

- Supabase email/password accounts and private user profiles
- Owner-scoped medications, appointments, journals, contacts, and notifications
- Real YK-IBPA1 Bluetooth Low Energy measurement capture
- Intentional saving of completed BLE or manually entered BP readings
- Saved BP history, trend, and seven-day summary
- Emergency medical information and caregiver connections
- OpenStreetMap hospital search for appointments and emergency directions
- The official NIA Caregiver's Handbook reference and download
- Responsive, elderly-friendly Flutter UI with local healthcare artwork

Empty accounts show genuine empty states. The database seed is intentionally
blank; the application does not insert sample patients or fabricated health
records.

## Project Structure

```text
lib/
  config/        Public runtime configuration
  decoders/      Provisional YK-IBPA1 packet decoding
  models/        Typed application records
  repositories/  Owner-scoped Supabase data access
  routes/        Application navigation
  screens/       Feature pages
  services/      Authentication, BLE, and handbook services
  theme/         Shared colors, typography, and motion
  widgets/       Reusable interface components
assets/
  images/        Local healthcare artwork
  logo/          EverCare brand assets
supabase/
  migrations/    Versioned PostgreSQL schema and RLS policies
  seed.sql        Intentionally empty seed
test/             UI and logic tests
```

## Supabase Setup

The Flutter app uses only the project's public URL and publishable key. Never
put a database password, secret key, or service-role key in the mobile app.

```powershell
supabase login
supabase link --project-ref wcssuruygqextigpobcb
supabase db push
```

The first migration creates the EverCare tables, indexes, account-profile
trigger, and Row Level Security policies. All personal tables require an
authenticated user and are restricted to their owner. No seed records are
uploaded.

The checked-in URL and publishable key can be overridden per build:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

## OpenStreetMap Hospital Finder

The hospital finder uses `flutter_map` with OpenStreetMap tiles, Overpass for
nearby hospital data, and Nominatim for an explicitly submitted name or city
search. It does not need a map-provider account, billing setup, or API key.
Location access is requested only when the user asks EverCare to find nearby
hospitals; no background location is used.

EverCare identifies its network requests, displays OpenStreetMap attribution,
caches repeated lookups, limits nearby results, automatically tries additional
public Overpass instances after a timeout or temporary server error, and
rate-limits Nominatim searches. Search happens only after submission, never on
each keystroke. The public OpenStreetMap, Nominatim, and Overpass services have
usage policies and no availability guarantee, so this configuration is
intended for low-volume development and classroom demonstration. A production
deployment should use a provider or hosted infrastructure with an appropriate
service agreement.

Emergency hospital results can open directions or a hospital-details search
using external Google Maps URLs. Maps URLs do not require an embedded Google
SDK or API key; the OpenStreetMap map remains inside EverCare.

OpenStreetMap data can be incomplete or outdated. Nearby results do not imply
that a hospital is open, has emergency capacity, or is the best medical option.

## Run and Verify

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```
