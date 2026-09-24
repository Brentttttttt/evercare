# Private profile photos

## Using the redesigned pages

Login and Register share a calm green/white layout with a fixed EverCare logo and
title. Only the form scrolls; the header becomes compact when the keyboard opens.
Existing email/password and Google authentication use the same services and routes.

Open **Profile > Edit profile > Add Photo / Change Photo**. Choose from Gallery
or take a photo on Android, review the preview, then press **Save Changes**.
**Keep previous photo** discards only the pending selection. A photo is optional
when completing a new Google user's required name/date-of-birth/care-role fields.

Profile now has an identity card, personal details, and the existing care,
sharing, settings, support, and logout destinations. No new package is required.

## Storage contract

The `20260923090000_profile_picture_storage.sql` migration adds the private
`profile-pictures` bucket. It uses the existing nullable `profiles.avatar_path`
column and does not change profile values or profile access policies.

- Maximum stored object size: 5 MiB (5,242,880 bytes).
- Allowed content types: `image/jpeg`, `image/png`, and `image/webp`.
- App-generated object path: `<authenticated user UUID>/<unique filename>.png`.
- `avatar_path` stores that relative object path, never image bytes, a device
  filename, a public URL, or a signed URL.
- Authenticated users may insert, read, and delete objects only in their own
  first-level folder. There is no object-update policy; upload replacements with
  `upsert: false` to new names.

The local migration audit found only bucket-scoped, owner-checked journal-photo
policies; none grants broad access to `storage.objects`. PostgreSQL policies are
additive, so independently added dashboard policies must also be reviewed before
deployment. This repository check cannot attest to the hosted policy state.
[Supabase Storage access-control documentation](https://supabase.com/docs/guides/storage/security/access-control)
describes the permissions used by uploads and overwrites.

## Safe app flow

1. Capture the signed-in account ID. Let the user choose an image; cancellation
   makes no storage or profile changes. Decode and resize/re-encode accepted image
   bytes before upload; do not trust only a filename or declared MIME type.
2. Upload the processed image to a new owner-scoped path with the correct content
   type, at most 5 MiB, and `upsert: false`. Recheck the account around asynchronous
   work; never continue an old user's operation under a different login.
3. The existing Save action persists the user's edited form to their authenticated
   profile ID. It includes `avatar_path` only when a new photo was explicitly
   selected. A text-only edit therefore preserves a newer photo from another
   device. Concurrent form edits retain the app's existing last-save behavior;
   this change does not introduce cross-device conflict resolution.
4. Confirm the database points to the new path before displaying success or
   deleting the old object. A network error is not proof that a database write
   failed: reread the profile before cleanup. If the outcome cannot be verified,
   retain the private uploaded object rather than risk deleting the active photo.
5. Clean up the superseded object only after successful replacement, only in the
   same account's folder. Cleanup failure must not undo a successful profile save.

Storage and profile writes are separate operations, not an atomic transaction.
Interrupted uploads or failed cleanup can leave private orphan files. Do not run
bulk cleanup from a mobile client or infer that old files are safe to delete from
an unverified network response. Uploading to new paths also avoids overwriting a
cached image. [Supabase standard-upload documentation](https://supabase.com/docs/guides/storage/uploads/standard-uploads)

## Reading and privacy

The app uses the existing `image_picker` dependency for gallery selection and
Android camera capture. A selected file is decoded, reduced to at most 768 pixels
on its longest side, and re-encoded as PNG to strip source EXIF/GPS metadata.
There is a 12 MiB source limit, 40-megapixel decode guard, and 5 MiB upload limit.
The editor previews selections without uploading; **Save Changes** (or **Save
and Continue**) commits the photo and edited profile. Cancellation leaves the
existing picture unchanged. Interrupted Android selections can be recovered
when Edit Profile reopens, but still require explicit saving.
Recovery is permitted only for the account that opened the profile picker; a
small owner marker is kept in preferences, never image bytes or OAuth tokens.

Google's trusted HTTPS `googleusercontent.com` metadata image is only a fallback
when no EverCare avatar path exists. Uploaded images always take priority. If an
uploaded image is unavailable, the app shows initials, not a different Google
photo. Neither temporary signed URLs nor Google image URLs are stored in the
profile row.

Read through authenticated Storage requests or short-lived signed URLs. Keep
signed URLs in memory, refresh them after expiry, and never log or persist them
as the profile path. A signed URL is a temporary bearer link: anyone receiving it
may use it until expiry. Do not imply that a private bucket makes a shared signed
URL private to the account. [Private-bucket documentation](https://supabase.com/docs/guides/storage/buckets/fundamentals)

On missing, expired, or failed images, show the existing initials/avatar fallback.
Clear account-specific image state on logout or account change. This migration
does not grant photo access to caregivers, other users, or unauthenticated clients;
that would require a separate deliberate sharing design.

## Verification

Validated on 2026-09-23:

- `flutter analyze`: no issues found.
- `flutter test`: all 411 tests passed, including fixed-header/keyboard/large-text
  layouts, existing authentication flows, photo previews, cancellation, upload
  failures, account-change guards, and Google-avatar precedence.
- The four storage migration-invariant tests below passed.
- `flutter build apk --dart-define-from-file=config/google_auth.json`: release
  APK compiled successfully at `build/app/outputs/flutter-apk/app-release.apk`.

No Android device was connected for physical gallery/camera or live photo-upload
testing. SDK/account chooser behavior and deployed Storage authorization still
need the real-device and isolated-account checks described below.

The migration was applied to EverCare's linked Supabase project on 2026-09-23.
It did not change any existing profile values. Other deployments must apply it
before using profile-photo uploads.

Run the bounded migration-invariant tests:

```powershell
npx --yes deno test --allow-read=supabase/migrations supabase/tests/profile_picture_storage_test.ts
```

These tests inspect migration text; they do not execute PostgreSQL or prove
deployed authorization. After applying the migration, verify using isolated test
accounts that an owner can upload/read/delete their own image, a second account
cannot access that path, unauthenticated reads fail, overwrites fail, and oversized
or disallowed MIME uploads fail. Also verify picker cancellation, profile-update
failure, offline display fallback, and replacement cleanup without altering real
users' records or photos.
