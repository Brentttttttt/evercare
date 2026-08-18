# EverCare - Week 5 Submission Package

**Activity:** API Integration & HTTP Requests - Week 5  
**Student:** Brent Lawrence C. Bernardo  
**Section:** ITE231  
**Professor:** Paul John Cabance  
**Prepared:** August 15, 2026  
**Due:** August 17, 2026 at 7:00 PM

## Submit these files

1. `EverCare_Week5_API_Integration_Documentation.pdf`
2. GitHub repository link: <https://github.com/Brentttttttt/evercare>

The editable DOCX, screenshots, request examples, and full JSON samples are
included in this folder as supporting evidence. A source-code ZIP is
intentionally not included because the GitHub link replaces that requirement.

## Implemented API feature

EverCare's OpenStreetMap Hospital Finder uses live public data to help a
caregiver search for hospitals, find hospitals near the device, view them on a
map, and choose a hospital for an appointment.

- **GET:** Nominatim hospital search and reverse address lookup
- **GET:** Photon search-as-you-type hospital suggestions
- **POST:** Overpass nearby-hospital lookup using coordinates and a 15 km radius
- **GET:** OpenStreetMap map tiles
- **JSON processing:** validates response shape, parses coordinates, names,
  addresses, and tags, removes duplicates, calculates distances, and maps
  results into `HospitalLocation` objects

## Folder contents

- `EverCare_Week5_API_Integration_Documentation.pdf` - final submission document
- `EverCare_Week5_API_Integration_Documentation.docx` - editable copy
- `VERIFICATION_RESULTS.txt` - analysis, test, build, and live HTTP results
- `api_samples/` - genuine GET/POST JSON evidence and reproducible requests
- `screenshots/` - implementation, UI, error-handling, and JSON evidence

## Important note

The evidence uses a generic public location in Guiguinto, Bulacan. It contains
no patient information, account credentials, tokens, API keys, or precise user
location. OpenStreetMap data may be incomplete or outdated, so hospital results
do not confirm availability, contact accuracy, emergency capacity, or quality
of care.
