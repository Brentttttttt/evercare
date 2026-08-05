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
- Google Maps hospital search for appointments and emergency directions
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

## Google Maps Hospital Finder

The hospital finder uses the native Google Maps and Places SDKs. In Google
Cloud, enable **Maps SDK for Android** and **Places API (New)**, then create an
API key restricted to Android app package `com.example.evercare` and the SHA-1
fingerprint of the signing certificate. Do not commit the key.

Pass the restricted key when running or building:

```powershell
flutter run --dart-define=GOOGLE_MAPS_API_KEY=your-restricted-key
```

The same build-time value configures the Android map and the native Places
client. A build without the key remains usable and shows a setup message only
when the hospital map is opened. Location access is requested at that time and
is used to perform the nearby-hospital search; no background location is used.

## Run and Verify

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```
