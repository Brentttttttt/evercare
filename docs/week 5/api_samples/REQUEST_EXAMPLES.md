# EverCare Week 5 - HTTP Request Examples

Captured: August 15, 2026 (Asia/Manila)

These commands use a generic public location in Guiguinto, Bulacan. They do
not contain patient details, account credentials, API keys, or a user's precise
location.

## GET - Nominatim hospital search

```powershell
$headers = @{
  'User-Agent' = 'EverCare/0.1.0 (https://github.com/Brentttttttt/evercare)'
  'Accept' = 'application/json'
  'Accept-Language' = 'en'
}
$uri = 'https://nominatim.openstreetmap.org/search?format=jsonv2&q=hospital%2C%20Bulacan%2C%20Philippines&countrycodes=ph&addressdetails=1&limit=15&dedupe=1'
Invoke-WebRequest -Uri $uri -Headers $headers -Method Get -TimeoutSec 30
```

## POST - Overpass nearby hospitals

```powershell
$query = @'
[out:json][timeout:25];
(
  nwr["amenity"="hospital"](around:15000,14.8333,120.8833);
  nwr["healthcare"="hospital"](around:15000,14.8333,120.8833);
);
out center tags;
'@
Invoke-WebRequest `
  -Uri 'https://overpass-api.de/api/interpreter' `
  -Headers $headers `
  -Method Post `
  -ContentType 'application/x-www-form-urlencoded; charset=UTF-8' `
  -Body @{ data = $query } `
  -TimeoutSec 35
```

## Expected response shapes

- Nominatim GET: a JSON array of place objects.
- Overpass POST: a JSON object containing an `elements` array.
