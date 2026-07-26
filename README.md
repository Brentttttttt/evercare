# EverCare

EverCare is a Flutter mobile UI prototype designed to help Filipino senior
citizens and their families keep blood-pressure information, medicines,
appointments, emergency details, and caregiver access organized in one
accessible interface.

## Sustainable Development Goal

EverCare supports **United Nations SDG 3: Good Health and Well-Being**. The
project focuses on making everyday health information easier for older adults
to review and share with trusted family members or caregivers.

## Current Week 2 Features

- Welcome, onboarding, login, registration, and password-recovery screens
- Five-tab navigation for Home, My Health, Medications, Appointments, and Profile
- Blood-pressure dashboard, history, trend, record, and device-preview screens
- Medication schedules and medicine detail forms
- Appointment lists, details, add/edit forms, and rescheduling previews
- Emergency information, accessibility settings, notifications, and reports
- Family and caregiver access under the Profile section
- Responsive, senior-friendly UI with local project images and mock content

## Development Scope

This repository currently implements **UI and navigation only**. All health
records, device states, medicines, appointments, profiles, and reports are
hardcoded sample content. The application does not connect to medical devices,
request Bluetooth permissions, call external APIs, authenticate users, or save
personal data.

## Project Structure

```text
lib/
  data/       Hardcoded sample content
  models/     UI data models
  routes/     Named application routes
  screens/    Feature and page widgets
  theme/      Shared colors, typography, and theme
  widgets/    Reusable interface components
assets/
  images/     Local healthcare imagery
  logo/       EverCare brand mark
test/         Phone-sized UI smoke tests
```

## Run the Project

```bash
flutter pub get
flutter run
```

## Verify the Project

```bash
flutter analyze
flutter test
```
