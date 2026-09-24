# Authentication UI assets

## Background

`assets/images/auth_background.png` was generated with the built-in image
generation tool on 2026-09-24. It is a static 1024 × 1536 decorative image shared
by Login and Register through `AuthBackground`. The real Flutter logo, text,
inputs, and controls remain separate, accessible widgets. It uses no runtime
blur, network image request, or continuous animation. A quiet gradient remains
available if the image cannot be decoded.

The `assets/images/` declaration in `pubspec.yaml` includes both images; the
generated background also has an explicit entry for reliable incremental builds.

Final generation prompt:

```text
Use case: stylized-concept
Asset type: portrait background bitmap for EverCare mobile login and registration screens, not a UI mockup.
Primary request: a soft, subtle, elegant, minimal caregiving/elderly-healthcare background. Warm ivory and soft white base with light green, muted sage and pastel cream. Delicate pale leaf silhouettes, gentle abstract curves and organic circles at the outer edges, plus one or two very faint tiny heart/care motifs. Comforting, calm and trustworthy, refined matte illustration with barely perceptible paper texture.
Composition: portrait 1024x1536. Keep the central 75 percent almost plain warm off-white because a real white Flutter form will overlay it. Keep the top center pale and quiet for a real app logo/title. Decoration gently hugs corners and outer margins, still attractive when cropped for a phone.
Constraints: background illustration only, no text, no letters, no logos, no UI controls or forms, no people, no photographs, no watermark. Very low contrast and low visual density; avoid busy patterns, dark outlines, harsh gradients or strong shadows.
```

## Google sign-in branding

The button uses the unmodified official gradient Google G, downloaded from
[Google Identity's asset](https://developers.google.com/static/identity/images/g-logo.png)
to `assets/images/google_g.png`. Its proportions and colors are preserved on a
white outlined button. The text remains a scalable Flutter widget, not baked
into an image. See [Google's branding guidance](https://developers.google.com/identity/branding-guidelines).

`assets/fonts/google_sans_auth_medium.ttf` is the Google Fonts-served 500-weight
TrueType subset for **Continue with Google** and **Signing in with Google…**,
obtained from the official Google Fonts CSS endpoint for `Google Sans` using its
`text` parameter. Only these button labels use the `GoogleSansAuth` Flutter font
family; the rest of EverCare keeps its existing typography. If those labels are
localized or changed, refresh the subset to include the new characters.

The font's original SIL OFL license and trademark notice are bundled beside it.
Source: [Google Fonts' Google Sans files](https://github.com/google/fonts/tree/main/ofl/googlesans).
No additional Dart packages or authentication credentials are required.

## Layout and behavior

- Fixed EverCare logo, wordmark, and tagline; only the form below scrolls.
- Compact spacing, opaque white form card, and comfortable button targets.
- Shared Google control retains cancellation, loading, errors, and existing flow.
- Logout uses an opaque pink, zero-elevation action tile so no shadow can show
  through its fill; its confirmation and sign-out logic are unchanged.

## Validation (2026-09-24)

`flutter pub get` resolved without package upgrades, `flutter analyze` reported
no issues, and all 421 Flutter tests passed. After the final divider-alignment
adjustment, all 31 focused auth/assets/logout tests passed again. Coverage
includes both auth screens at 320px/3× text with keyboard insets, fixed branding,
Google cancellation/loading/routing, bundled image decoding, and the logout
tile's shadow-free surface and disabled state. Physical-device testing was not
performed in this UI pass. The final Android release APK built successfully with
`flutter build apk --dart-define-from-file=config/google_auth.json` at
`build/app/outputs/flutter-apk/app-release.apk`; the generated background, Google
icon, and button font were also verified inside the APK's bundled assets.

Optional synthetic-data visual captures are provided by
`test/screens/edit_profile_photo_test.dart` with `CAPTURE_EVERCARE_UI=true` and
`UI_REVIEW_FONT` pointing to a local Roboto font. Capture one page per invocation
(`--plain-name='visual capture register'`, for example) to avoid retained-layer
artifacts in sequential widget-test captures. These are test renders, not phone
screenshots; unspecified fonts can still use the test runner's Ahem fallback.
