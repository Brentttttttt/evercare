# EverCare AI setup

EverCare adapts Inaagapay's conversational approach and GPT-OSS provider setup
to older adults, caregivers, and families. The primary model is
**`openai/gpt-oss-120b` on Groq**, with a smaller Groq model and optional NVIDIA
backup. It no longer sends requests to Gemini.

`Flutter → authenticated Supabase Edge Function → Groq (optional NVIDIA fallback)`

Provider keys belong only in Supabase Function secrets or the ignored
`supabase/functions/.env` for local server development. Never put them in
Flutter, `--dart-define`, an APK asset, a committed file, or client configuration.
Inaagapay's patient records, saved conversations, and maternal-health prompts
are not copied into EverCare.

## Provider routing

The shared `requestAiStructuredJson` client in `_shared/ai.ts` tries:

1. Groq: `openai/gpt-oss-120b`.
2. Groq: `openai/gpt-oss-20b` if the primary target is unavailable.
3. NVIDIA: `openai/gpt-oss-20b`, only when `NVIDIA_API_KEY` is configured and
   the Groq targets have failed.

Recoverable provider failures include rate limits, server errors, network
failures, timeouts, context-limit errors, and unavailable models. Each target
is attempted at most once per request. Groq attempts have a 15-second timeout;
the final NVIDIA attempt can use the remaining time in the shared 45-second
provider budget. There is no unbounded retry loop.

Models are fixed in the server code; `GROQ_MODEL` is not an override. Requests
use standard non-streaming chat completions, temperature `0.5`, top-p `0.95`,
medium reasoning, and a default output budget of 2,048 tokens. Groq uses strict
JSON Schema output; NVIDIA uses JSON-object output with the required schema in
the instructions. The server validates every response before returning it.
See [Groq structured outputs](https://console.groq.com/docs/structured-outputs)
and [NVIDIA's GPT-OSS endpoint](https://docs.api.nvidia.com/nim/reference/openai-gpt-oss-20b).

The source project's NVIDIA 120B model returned HTTP 410 (retired). The optional
integration therefore targets the listed NVIDIA 20B endpoint instead. Its live
requests repeatedly exceeded the 45-second budget, so **NVIDIA is not enabled in
the current hosted deployment**. No NVIDIA key was copied into EverCare's files
or hosted secrets. Stale source-model identifiers are not copied into the chain.

## Configure and deploy

Use EverCare's Groq key. Configure an NVIDIA key only if you want requests to
fall back to that separate provider:

```powershell
supabase secrets set GROQ_API_KEY=YOUR_GROQ_API_KEY
# Optional backup:
supabase secrets set NVIDIA_API_KEY=YOUR_NVIDIA_API_KEY
supabase functions deploy health-bp-insight
supabase functions deploy health-bp-chat
supabase functions deploy care-book-ai
```

Deploy to the project configured in `lib/config/supabase_config.dart`.
`GEMINI_API_KEY` and legacy `GROQ_MODEL` secrets are unused by this integration.
Never rename one provider's key into another provider's key.

For local development, copy `supabase/functions/.env.example` to
`supabase/functions/.env`, replace the Groq placeholder, and optionally add the
NVIDIA key. Keep the real file ignored by Git. With Supabase running:

```powershell
supabase start
supabase functions serve --env-file supabase/functions/.env
```

This change does not enable billing or change any provider account's plan.
Availability, quotas, credits, and charges follow the configured accounts; a
fallback is not a promise of unlimited or permanently free access. Both Groq
models may share account-level limits. Check the account dashboard and
[Groq rate limits](https://console.groq.com/docs/rate-limits).

## Features, context, and authentication

- `health-bp-insight` computes the existing adult BP category, explanation, and
  urgent next step on the server. The model selects IDs from reviewed tips;
  it does not calculate the category or invent replacement instructions.
- `health-bp-chat` receives corrected systolic/diastolic/pulse values and the
  current question. The backend adds the actual result status and category.
  Ordinary BP, lifestyle, symptom, and medication-education questions reach
  the conversational model; one reading never establishes a diagnosis.
- `care-book-ai` prioritizes the 12 local Care Book topics and labels chapter
  sources only when used. General guidance is allowed without claiming it is
  Care Book content. It has no access to the NIA PDF, profiles, journals, saved
  health records, or medication records.
- All three functions verify the bearer token with Supabase Auth. The legacy
  gateway JWT check is disabled in `config.toml` to support asymmetric signing
  keys; application-level user verification remains mandatory.

Both chats remain in memory on the device. Requests include at most **16 prior
messages** (eight user/assistant exchanges), up to **16,000 characters** total.
Each user message is limited to 600 characters and each assistant message to
2,400. Flutter keeps complete recent exchanges instead of cutting sentences;
the server independently validates roles, fields, and sizes. The current user
question is sent once, after history.

Trusted instructions and BP/Care Book context are system messages. History
retains separate `user` and `assistant` messages and cannot supply a system
role. Only the final structured answer is returned: internal reasoning is not
shown in Flutter or saved as conversation. Requests do not create persistent
provider conversation objects.

## Conversational behavior and safety

The prompt borrows Inaagapay's warm, mobile-friendly style and naturally
mirrors English, Tagalog, or Taglish, while retaining EverCare's health and
caregiving scope. It answers the newest question first, uses prior turns, and
usually gives two to four focused sentences. Follow-up questions are optional
and useful, not a required closing on every answer.

The previous backend's blanket medical redirects and fixed reply templates
remain removed. The assistant should not repeat BP definitions, classifications,
disclaimers, or generic referrals on every turn. Medication education is
allowed, but it must not prescribe or change prescribed treatment. Failures
appear as retry notices, not fabricated medical answers, and are excluded
from conversation history.

Live answer review also tightened uncertainty about caffeine: temporal
association is not an established cause, and food or water must not be presented
as a way to neutralize its BP effects. Routine measurement guidance is grounded
in [AHA home monitoring guidance](https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings/monitoring-your-blood-pressure-at-home)
and [Mayo Clinic's caffeine explanation](https://www.mayoclinic.org/diseases-conditions/high-blood-pressure/expert-answers/blood-pressure/faq-20058543).
Potassium advice must respect kidney and medication restrictions; see
[AHA potassium guidance](https://www.heart.org/en/health-topics/high-blood-pressure/changes-you-can-make-to-manage-high-blood-pressure/how-potassium-can-help-control-high-blood-pressure).
These are prompt safeguards, not a guarantee that every generated answer is
clinically correct.

Existing BP thresholds and the one-time `-10 mmHg` BLE systolic calibration are
unchanged. Deterministic severe-reading guidance and emergency handling remain
in place. `Needs Attention` alone is not an emergency. Its Emergency shortcut
opens the existing Emergency page after confirmation; it does not place a
phone call.

## Errors and privacy

- Rate-limit errors reach Flutter only after applicable fallback targets fail.
  Daily exhaustion returns `AI_DAILY_QUOTA` when the relevant failures identify
  daily request/token limits, rather than promising recovery in a few seconds.
  Other rate limits use a friendly busy message and available retry timing.
- The local tap cooldown remains separate (`AI_COOLDOWN`). It is a per-instance
  safeguard, not a distributed production rate limiter.
- Exhausted timeout/network/server fallbacks return a clean service error.
  Incomplete generations, refusals, malformed JSON, and invalid response shapes
  are rejected rather than displayed as answers.
- Logs contain generic failure categories and status, not provider response
  bodies, keys, full conversations, or identifying information. Flutter never
  receives provider URLs, stack traces, or secrets in error messages.
- Enabling the NVIDIA backup means the same bounded request context may be
  sent to NVIDIA after Groq fails. A shared NVIDIA key also shares that account's
  quota/credits; use a dedicated EverCare key for independent operations when
  available. No database content is copied from Inaagapay.

The application sends only the question, bounded history, and the explicitly
described feature context. Identifying information typed into a chat is still
part of that text. Review both providers' account terms and data-handling
settings before handling real patient information; a working integration does
not establish clinical suitability or privacy compliance. Use synthetic data
for testing.

## Verification

```powershell
npx --yes deno test --allow-env supabase/functions
npx --yes deno check supabase/functions/health-bp-insight/index.ts supabase/functions/health-bp-chat/index.ts supabase/functions/care-book-ai/index.ts
flutter analyze
flutter test
flutter build apk --debug
```

Mocked backend tests verify transport payloads, fallback handling, routing,
safety, authentication, and response validation; they do not prove live answer
quality. Live verification should use synthetic 123/96, pulse 77 data: ask about
worry, immediate advice, long-term improvement, and the coffee / two cups /
waiting-time follow-ups. Confirm distinct, relevant answers and verify both
automatic insights and Care Book replies. Include English and Tagalog/Taglish
checks for language matching.

`supabase/tests/ai_live_smoke.ts` is an explicit live regression runner. Set
`SUPABASE_URL`, `SUPABASE_TEST_ADMIN_KEY`, and `SUPABASE_TEST_PUBLIC_KEY` only in
your server shell, then run:

```powershell
npx --yes deno run --allow-env --allow-net supabase/tests/ai_live_smoke.ts
```

It creates a temporary synthetic account, checks all three hosted functions and
follow-ups, then deletes that account in cleanup. It never uses an existing
person's data. Do not put its administrator key in Flutter or a committed file.
The runner stops on daily exhaustion; avoid repeated live runs against an
exhausted account.

### Migration verification — 2026-09-22

The former Gemini deployment encountered intermittent high-demand errors and an
observed daily free-project quota of 20 requests. This motivates moving to the
requested Inaagapay-style provider setup; it is not a statement about every
Gemini account.

- Deployed all three functions to the existing EverCare Supabase project,
  using EverCare's existing Groq key. Gemini is no longer called. No account
  billing settings were changed.
- Direct live checks returned valid structured answers from Groq 120B and from
  Groq 20B after a simulated primary-model HTTP 429.
- All 30 backend tests passed, including bounded fallbacks, malformed output,
  deadlines, history, authentication, and emergency handling. Deno type checks,
  formatting, and lint passed.
- All 192 Flutter tests and Flutter analysis passed. Flutter behavior and wire
  contracts are unchanged, so this server-side update does not require a new APK.
- Hosted synthetic checks passed automatic BP insights, all six BP conversation
  turns, Care Book follow-ups, Tagalog responses, emergency handling, and HTTP
  401 for unauthenticated access to all three functions.
  The final run encountered one short HTTP 429 and succeeded after a five-second
  retry; provider rate limits still apply even with the model fallback.
- Live answer review prompted additional brevity and caffeine-uncertainty
  instructions. These sampled checks are not a clinical validation or a
  guarantee of future model accuracy or availability.
- NVIDIA 120B returned a retirement error; NVIDIA 20B requests timed out.
  Optional NVIDIA transport has mocked coverage but failed live availability
  checks and remains disabled. The working hosted fallback is Groq 20B.
- Temporary synthetic test accounts and their generated profiles were removed.
  Inaagapay's source project and patient data were not modified or imported.
