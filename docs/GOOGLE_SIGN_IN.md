# Google sign-in for EverCare

EverCare's Android Google sign-in uses the native account chooser, then exchanges
Google's ID token with Supabase Auth. It does not ask for a Google password,
read Gmail, or copy Google contacts. Existing email/password sign-in remains
available.

The code alone cannot create OAuth registrations or enable the hosted provider.
An owner must complete the Google Cloud and Supabase configuration below, then
build the app with the matching public Web client ID. No live Google credentials
or hosted provider settings were created or changed during implementation.

## 1. Register the Android app and a Web OAuth client

In the Google Cloud project intended for EverCare, configure Google Auth
Platform branding, audience, and basic identity scopes. Keep access limited to
`openid`, email, and basic profile; Google sign-in does not need Gmail, Drive,
Calendar, or People API access.

Create both OAuth client types in that same project:

| OAuth client | Purpose | Required configuration |
| --- | --- | --- |
| Android | Identifies the installed EverCare app | Package `com.example.evercare` and its signing certificate SHA-1 |
| Web application | Identifies Supabase/the token audience | Its client ID is the app's `GOOGLE_WEB_CLIENT_ID` and native `serverClientId` |

Do not change EverCare's Android application ID merely to make OAuth work. Its
actual package is `com.example.evercare` in `android/app/build.gradle.kts`.

Obtain the signing certificate fingerprints for the build you will install by
running this from the repository's `android` directory:

```powershell
.\gradlew.bat :app:signingReport --console=plain
```

On the current development workstation, the report returned this debug SHA-1
(also used by its present release configuration):

```text
75:EB:04:C8:DD:B0:8B:86:60:10:01:11:2F:F7:95:FD:02:26:80:6E
```

Use the SHA-1 for the appropriate variant. This repository currently signs both
debug and release builds with the local debug signing configuration. Before a
production release, register the actual production certificate as well. Google
Play App Signing uses the app-signing certificate for Play-installed builds,
which can differ from the upload certificate and local debug certificate.
Re-run the report if your signing configuration changes; fingerprints are public
identifiers, not private signing keys.

The same signing report also prints SHA-256. The Android OAuth client used here
requires SHA-1; this integration does not require Firebase/SHA-256 registration.
Use the actual reported SHA-256 if another Google service explicitly requests it.

The app passes the Web client ID programmatically, so `google-services.json`,
Firebase Auth, a Google Services Gradle plugin, and `GET_ACCOUNTS` permission are
not required for this integration. See the official
[Flutter Android integration instructions](https://pub.dev/packages/google_sign_in_android#integration).

For an External project in Testing, review Audience and add intended test users
where applicable. Google documents an exception to the test-user allowlist for
apps requesting only basic identity scopes; Workspace administrator policies can
still restrict access. Do not broaden scopes to solve an account-picker problem.
See [Google OAuth app states](https://developers.google.com/identity/protocols/oauth2/production-readiness/overview).

## 2. Configure the Supabase Google provider

Open Authentication > Sign In / Providers > Google for EverCare's Supabase
project, `wcssuruygqextigpobcb`. Enable Google and enter the Web application's
OAuth client ID and client secret. If multiple accepted client IDs are needed,
follow Supabase's comma-separated configuration with the Web client ID first.
The native ID token's audience must be one of the accepted IDs.

For browser OAuth configuration, the Google Web client's authorized redirect URI
is the Supabase callback, not an arbitrary page in the Flutter application:

```text
https://wcssuruygqextigpobcb.supabase.co/auth/v1/callback
```

If supporting browser redirects, separately configure the actual app origin and
Supabase's Site URL/redirect allowlist. The Android native ID-token exchange does
not require launching a browser or adding a new deep-link scheme. This change
does not claim an iOS or desktop Google integration.

The OAuth **client secret belongs only in trusted server/provider settings**.
Do not put it in Dart, app assets, a dart-define file, logs, or the APK. The public
client ID may be supplied to the app. See
[Supabase's Google provider setup](https://supabase.com/docs/guides/auth/social-login/auth-google).

## 3. Apply the OAuth profile migration

The database must include
`supabase/migrations/20260922090000_allow_incomplete_oauth_profiles.sql` before
testing new Google registrations. Review the normal migration plan first:

```powershell
supabase db push --linked --dry-run
```

Apply reviewed migrations through the project's normal deployment workflow;
`supabase db push --linked` applies all pending migrations, not only this one.
Do not assume a local migration file has already been deployed.

Deployment record: this migration was applied to linked project
`wcssuruygqextigpobcb` on September 22, 2026, after a dry run listed it as the only
pending migration. Other projects/environments still need their own migration
review and deployment.

This migration preserves existing profile values. It allows an initially unset
`profiles.user_type` and updates the
new-user trigger to use Google's supplied name when available. It does not guess
that every new Google user is a senior, and it does not overwrite existing
profile rows or roles. New/incomplete Google profiles must complete their name,
date of birth, and Senior/Caregiver/Family Member choice in EverCare before
entering the home screen. Google does not supply those EverCare-specific choices.

## 4. Supply the public ID to Flutter

The app reads a compile-time `GOOGLE_WEB_CLIENT_ID` through
`String.fromEnvironment`. Flutter does not automatically import shell `.env`
files. In particular, `supabase/functions/.env` is for server-side AI secrets and
must never become a Flutter asset or mobile configuration file.

Run with the public Web client ID:

```powershell
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com
```

Or build an APK with it:

```powershell
flutter build apk --debug --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com
```

Use `--release` instead of `--debug` for a release build, retaining the same
public client-ID argument and registering that build's signing certificate.

For a local file, copy the shape of `config/google_auth.example.json` into your
ignored `config/google_auth.json`, replace the placeholder with the Web client
ID, and run:

```powershell
flutter run --dart-define-from-file=config/google_auth.json
flutter build apk --debug --dart-define-from-file=config/google_auth.json
```

That JSON contains public build configuration only, never an OAuth client
secret, Supabase service-role key, or AI API key. Rebuild/restart after changing
compile-time configuration; merely editing a server `.env` does not change an
installed app. A build without a valid client ID still compiles and keeps
email/password sign-in working, but its Google button displays a setup message
instead of launching an unconfigured account chooser.

## Accounts and troubleshooting

Supabase performs supported identity linking and session verification. A Google
identity with a matching verified email can link through Supabase's normal
identity rules. EverCare must not merge users, profiles, or health records by
performing its own email-string match. Different email addresses are not
automatically the same account. See
[Supabase identity linking](https://supabase.com/docs/guides/auth/auth-identity-linking).

Check these points if Google sign-in fails:

- Missing setup: confirm the installed APK was built with the **Web** client ID,
  not the Android client ID or client secret.
- Account chooser closes unexpectedly: verify package name, SHA-1, and both OAuth
  clients' Google project. Native configuration errors can resemble user
  cancellation in Android Credential Manager.
- Chooser succeeds but EverCare login fails: verify the Supabase Google provider
  is enabled and accepts the exact Web client ID used in the build.
- Only some accounts work: review Google Audience/Testing settings and any
  Workspace administrator restrictions.
- Debug works but release/Play does not: register the certificate that actually
  signed that installed build.

The plugin's [Android troubleshooting guide](https://pub.dev/packages/google_sign_in_android#troubleshooting)
covers package, signing, and client-ID mismatches. This integration uses
`google_sign_in` 7.2.0: initialize `GoogleSignIn.instance` once, then call
`authenticate()` from a user action; the account's `authentication.idToken` is
sent to Supabase. Older tutorials using a `GoogleSignIn()` constructor and
`signIn()` do not describe this version's API. See the
[current plugin usage guide](https://pub.dev/packages/google_sign_in/versions/7.2.0).

## Verification status

Package resolution, the Gradle signing report, and Android AAR compatibility
checks passed with the existing Flutter 3.44.6 / Dart 3.12.2 toolchain. On
2026-09-23, `flutter analyze` reported no issues and the full Flutter test suite
passed all 332 tests. These include native-flow service contract tests, safe
cancellation/errors, existing-profile preservation, conflict-safe creation,
required setup, logout, and both authentication screens. `flutter build apk`
also succeeded; the release APK is at `build/app/outputs/flutter-apk/app-release.apk`.
It uses the existing debug signing configuration and has no Google client ID
embedded until rebuilt with the configuration above. Actual Google account
selection and Supabase session creation require
valid project credentials and an Android device with Google Play services. No
device was connected during this setup work, so live Google sign-in has not been
verified. A successful build or mocked test is not proof that hosted OAuth
configuration is complete.
