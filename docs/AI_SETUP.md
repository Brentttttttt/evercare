# EverCare AI setup

Provider: **Google Gemini Developer API**. Model: **`gemini-3.8-flash`**.

`Flutter → authenticated Supabase Edge Function → Gemini API`

`GEMINI_API_KEY` belongs only in Supabase Function secrets (or the ignored
`supabase/functions/.env` for local server development). Never put it in Flutter,
`--dart-define`, an APK asset, a committed file, or a client configuration.

## Features and shared implementation

- `health-bp-insight` computes the existing adult BP category, explanation, and
  urgent next step on the server. Gemini selects IDs from reviewed tips.
- `health-bp-chat` receives corrected systolic/diastolic/pulse values and the
  current question. The backend adds the actual result status and category as
  context. Gemini can answer normal BP, lifestyle, symptoms, and
  medication-education questions; a single reading never establishes a diagnosis.
- `care-book-ai` prioritizes the 12 local Care Book topics and labels chapter
  sources only when used. General guidance is allowed without claiming it is
  Care Book content. It has no access to the NIA PDF, profiles, journals, saved
  health records, or medication records.
- `_shared/ai.ts` is the only provider transport. It uses REST
  `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent`,
  an `x-goog-api-key` header, JSON Schema output, and medium thinking by default.
  Output budgets allow room for thinking and the final answer.
- All three functions verify the bearer token with Supabase Auth. The legacy
  gateway JWT check is disabled in `config.toml` to support asymmetric signing
  keys; the application-level user verification remains mandatory.

## Configure and deploy

Create a Gemini Developer API key in [Google AI Studio](https://aistudio.google.com/apikey)
using a project on the Free Tier, then set the hosted secret:

```powershell
supabase secrets set GEMINI_API_KEY=YOUR_GEMINI_API_KEY
supabase functions deploy health-bp-insight
supabase functions deploy health-bp-chat
supabase functions deploy care-book-ai
```

Deploy to the project configured in `lib/config/supabase_config.dart`. The model
is fixed in the shared server client; there is no model/provider fallback.
Old `GROQ_API_KEY` / `GROQ_MODEL` secrets are unused and may be removed after
verifying deployment. Do not rename a Groq key into a Gemini key.

For local development, copy `.env.example` to `supabase/functions/.env` and replace
the placeholder. Keep the real file ignored by Git. With Supabase running:

```powershell
supabase start
supabase functions serve --env-file supabase/functions/.env
```

The integration uses standard text generation. It enables no billing, paid
tools, search grounding, Vertex AI, persistent provider conversations, or context
caching. Google lists Gemini 3.8 Flash input/output as free on the Free Tier;
quotas and model availability still depend on the key's project. Using a key
from an already-paid project follows that project's billing settings: application
code cannot force a paid project onto the Free Tier.

## Conversation continuity and safety

Both chats remain in memory on the device. They send at most **16 prior
messages** (eight user/assistant exchanges), up to **16,000 characters** total.
Each user message is limited to 600 characters and each assistant message to
2,400. The Flutter client keeps complete recent exchanges rather than cutting
sentences; the server independently validates roles, fields, and size limits.
The current user question is sent once, after history.

Trusted instructions and BP/Care Book context go in Gemini's `systemInstruction`.
History retains separate `contents` entries, mapping `user → user` and
`assistant → model`. Old chat messages cannot become system instructions.
Generated thought text is not returned to Flutter or stored as conversation.

The previous repetition originated in backend `medical_redirect` routing and
fixed fallback templates, including lifestyle questions; it was not just a
model problem. Normal health questions now reach the conversational prompt,
which answers the newest question and avoids repeating classifications,
definitions, disclaimers, and generic referral closings. Medication education
is allowed, but the assistant must not prescribe or change prescribed treatment.
Service failures appear as retry notices and are not stored as assistant turns.

Existing BP classification thresholds and the one-time `-10 mmHg` BLE systolic
calibration are unchanged. The backend retains deterministic severe-reading
guidance and emergency handling. `Needs Attention` alone does not trigger an
emergency response. Its new Emergency shortcut opens the existing Emergency
page after confirmation; it does not place a phone call.

## Errors and operational privacy

- HTTP 429 returns a friendly busy message and `Retry-After`; there are no
  automatic paid-provider fallbacks or unbounded retries.
  A Google `QuotaFailure` whose quota ID identifies `PerDay` returns
  `code: AI_DAILY_QUOTA` instead of suggesting a momentary delay. Flutter shows
  "EverCare AI has reached its daily free limit. Please try again after the daily reset."
  A local tap cooldown returns `AI_COOLDOWN` and asks the user to wait a few
  seconds. Only these fixed codes are interpreted; raw provider text is never
  displayed. The live test runner stops on daily exhaustion without retrying.
  All three features and live tests share the Google project's model quota;
  an automatic BP insight also uses a request. Google documents daily quota
  renewal at midnight Pacific time (3 PM in the Philippines during Pacific
  daylight time, 4 PM during standard time). See [rate limits](https://ai.google.dev/gemini-api/docs/rate-limits).
- Network failures, a 45-second request timeout, and upstream non-success
  responses return a clean service error, never a medical refusal.
  HTTP 502/503/504 gets at most one short retry within that same deadline.
- Missing candidates, blocked output, incomplete generations, malformed JSON,
  and invalid schema output are rejected with a retry message.
- Logs contain generic failure categories and HTTP status, never provider
  response bodies, keys, full conversations, or identifying information.
- Flutter receives no provider URL, stack trace, or secret in error messages.

Google's Free Tier data handling differs from its paid service. Review the
[Gemini terms](https://ai.google.dev/gemini-api/terms) before any real-patient
rollout: unpaid services must not receive sensitive, confidential, or personal
information, and content may be reviewed and used to improve Google's products.
The terms also restrict clinical practice and medical-advice uses. This
integration is for general education and synthetic demonstrations; connecting
the API does not establish suitability for handling real patient information.
The app sends only the question, bounded history, and the explicitly described
context. Identifying information typed into a chat is still part of that text.
Use synthetic data for testing. The existing per-instance cooldown is not a
distributed production rate limiter.

## Verification

```powershell
npx --yes deno test --allow-env supabase/functions
npx --yes deno check supabase/functions/health-bp-insight/index.ts supabase/functions/health-bp-chat/index.ts supabase/functions/care-book-ai/index.ts
flutter analyze
flutter test
flutter build apk --debug
```

Backend tests mock the provider to verify payloads, routing, safety, authentication,
and error handling; these alone do not prove live model answer quality. Live
verification should use a test account and synthetic 123/96, pulse 77 data:
ask about worry, immediate advice, then long-term improvement, and also run the
coffee / two cups / waiting-time follow-ups. Confirm distinct relevant answers
and verify both automatic insights and Care Book responses.

`supabase/tests/ai_live_smoke.ts` is an explicit live regression runner. Set
`SUPABASE_URL`, `SUPABASE_TEST_ADMIN_KEY`, and `SUPABASE_TEST_PUBLIC_KEY` only in
your server shell, then run `npx --yes deno run --allow-env --allow-net
supabase/tests/ai_live_smoke.ts`. It creates a temporary synthetic test account,
uses fabricated readings, verifies all three hosted functions and follow-ups,
and deletes that account in cleanup. It never uses an existing person's data.
Do not put the test administrator key into Flutter or a committed file.

### Verification recorded on 2026-09-21

- Configured the Gemini secret and deployed all three functions to the existing
  linked EverCare Supabase project.
- All 188 Flutter tests, Flutter analysis, and the Android debug APK build passed.
- All 19 backend tests passed, including the exact six-message conversation
  regression with a mocked provider, actual Gemini role mapping, emergency
  handling, authentication, and clean provider-error responses.
- Live authenticated Supabase calls produced automatic insights and distinct
  BP replies to the worry and immediate-advice questions. All three hosted
  functions rejected unauthenticated calls with HTTP 401.
- Full live acceptance is **not yet complete**: Gemini returned intermittent
  HTTP 503 high-demand errors, then HTTP 429 with
  `GenerateRequestsPerDayPerProjectPerModel-FreeTier`, limit **20** for the
  configured project. This is the observed project quota, not a promise about
  all accounts. No billing or alternate provider was enabled.
- Remaining live checks after quota renewal: the long-term lifestyle answer,
  the coffee follow-up sequence, and Care Book responses. The live test runner
  is available above. Avoid repeatedly rerunning it while the daily quota is
  exhausted; even failed attempts may consume quota.
- Temporary synthetic test users and their generated profiles were removed.

References: [Gemini REST](https://ai.google.dev/api/generate-content),
[Gemini structured output](https://ai.google.dev/gemini-api/docs/structured-output),
[Gemini pricing](https://ai.google.dev/gemini-api/docs/pricing),
[Supabase secrets](https://supabase.com/docs/guides/functions/secrets).
