/**
 * Explicit live smoke test. Creates one confirmed synthetic Auth user, sends
 * only fabricated health data, then deletes that user and its cascaded profile.
 * Requires SUPABASE_URL, SUPABASE_TEST_ADMIN_KEY and SUPABASE_TEST_PUBLIC_KEY.
 * Never prints credentials or accesses an existing user's data.
 */
import { equal, ok } from "node:assert/strict";

const base = Deno.env.get("SUPABASE_URL")?.replace(/\/$/, "");
const adminKey = Deno.env.get("SUPABASE_TEST_ADMIN_KEY");
const publicKey = Deno.env.get("SUPABASE_TEST_PUBLIC_KEY");
if (!base || !adminKey || !publicKey) {
  throw new Error(
    "Live smoke test requires the three documented server environment variables.",
  );
}
const runId = crypto.randomUUID();
const email = `evercare-ai-smoke-${runId}@example.invalid`;
const password = `Ec!${crypto.randomUUID()}a1`;
const headers = (key: string, bearer = key) => ({
  apikey: key,
  Authorization: `Bearer ${bearer}`,
  "Content-Type": "application/json",
});
const pause = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
const request = (url: string, init: RequestInit) =>
  fetch(url, {
    ...init,
    signal: AbortSignal.timeout(60000),
  });
let createdUserId: string | undefined;

try {
  for (const name of ["health-bp-chat", "health-bp-insight", "care-book-ai"]) {
    const unauthorized = await request(`${base}/functions/v1/${name}`, {
      method: "POST",
      headers: { apikey: publicKey, "Content-Type": "application/json" },
      body: "{}",
    });
    equal(unauthorized.status, 401, `${name} must require a signed-in user`);
    await unauthorized.arrayBuffer();
  }
  console.log("PASS: all three hosted functions reject unauthenticated calls");
  const created = await request(`${base}/auth/v1/admin/users`, {
    method: "POST",
    headers: headers(adminKey),
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: "Synthetic AI smoke test",
        ai_smoke_run: runId,
      },
    }),
  });
  if (!created.ok) {
    throw new Error(
      `Synthetic test user creation failed: HTTP ${created.status}`,
    );
  }
  const user = await created.json();
  ok(typeof user.id === "string" && /^[0-9a-f-]{36}$/i.test(user.id));
  createdUserId = user.id;
  equal(user.user_metadata.ai_smoke_run, runId);
  const login = await request(`${base}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: headers(publicKey),
    body: JSON.stringify({ email, password }),
  });
  if (!login.ok) {
    throw new Error(`Synthetic test sign-in failed: HTTP ${login.status}`);
  }
  const session = await login.json();
  ok(typeof session.access_token === "string");

  const invoke = async (name: string, body: Record<string, unknown>) => {
    // Each hosted request already has a bounded provider fallback chain.
    // One whole-request retry is enough to check transient availability.
    for (let attempt = 0; attempt < 2; attempt++) {
      const response = await request(`${base}/functions/v1/${name}`, {
        method: "POST",
        headers: headers(publicKey!, session.access_token),
        body: JSON.stringify(body),
      });
      const data = await response.json();
      if (response.status === 429 && data.code === "AI_DAILY_QUOTA") {
        throw new Error(
          "AI provider daily quotas are exhausted. Stop live testing until they reset.",
        );
      }
      if ((response.status === 429 || response.status === 503) && attempt < 1) {
        const seconds = Math.min(
          60,
          Math.max(3, Number(response.headers.get("retry-after")) || 15),
        );
        console.log(
          `Temporary service error ${response.status}: ${name}, waiting ${seconds}s`,
        );
        await pause(seconds * 1000);
        continue;
      }
      if (!response.ok) {
        throw new Error(`${name} failed: HTTP ${response.status}`);
      }
      return data;
    }
    throw new Error("Quota retries exhausted");
  };

  const reading = { systolic: 123, diastolic: 96, pulse: 77 };
  const insight = await invoke("health-bp-insight", reading);
  equal(insight.status, "hypertension_stage_2");
  equal(insight.systolic, 123);
  equal(insight.diastolic, 96);
  ok(insight.tips.length >= 2);
  console.log("PASS: hosted automatic insight with reviewed tips");

  const questions = [
    "should I worry about my BP result?",
    "could you give me simple advice for now?",
    "how could I keep and better myself to stop getting results like these?",
    "Could coffee affect it?",
    "I had two cups earlier.",
    "How long should I wait before checking again?",
  ];
  const history: { role: string; content: string }[] = [];
  const answers: string[] = [];
  for (const [index, message] of questions.entries()) {
    if (index) await pause(3000);
    const data = await invoke("health-bp-chat", {
      ...reading,
      message,
      history,
    });
    equal(data.status, "answered");
    equal(data.category, "hypertension_stage_2");
    equal(data.urgentGuidance, null);
    equal(
      data.disclaimer,
      "This chat explains this reading only and is not a medical diagnosis.",
    );
    ok(
      typeof data.answer === "string" && data.answer.length > 20 &&
        data.answer.length <= 2400,
    );
    ok(!/glad you asked/i.test(data.answer));
    if (index === 1) ok(/rest|sit|quiet|relax/i.test(data.answer));
    if (index === 2) ok(/sleep|salt|sodium|activ|exercise/i.test(data.answer));
    if (index >= 3) {
      ok(/caffein|coffee|cup|wait|hour|minute/i.test(data.answer));
      ok(
        !/\b(?:likely|probabl[ey]) (?:the )?(?:reason|cause)\b/i.test(
          data.answer,
        ),
      );
      ok(
        !/\b(?:snack|meal|food|water)\b[^.!?]{0,100}\b(?:blunt|neutraliz|counteract)\b/i
          .test(data.answer),
      );
      ok(
        !/enough time[^.!?]{0,100}(?:wearing off|worn off)/i.test(data.answer),
      );
    }
    console.log(
      JSON.stringify({
        syntheticTurn: index + 1,
        question: message,
        answer: data.answer,
      }),
    );
    answers.push(data.answer);
    history.push({ role: "user", content: message }, {
      role: "assistant",
      content: data.answer,
    });
  }
  equal(new Set(answers).size, questions.length);
  console.log(
    "PASS: exact BP conversation and coffee follow-ups produce distinct answers",
  );

  const care = await invoke("care-book-ai", {
    selectedChapter: 8,
    message:
      "How can I prepare my father's medication list for a clinic appointment?",
    history: [],
  });
  equal(care.status, "answered");
  ok(care.answer.length > 20 && Array.isArray(care.sources));
  console.log(
    JSON.stringify({
      feature: "care-book-ai",
      syntheticAnswer: care.answer,
      sources: care.sources,
    }),
  );
  await pause(3000);
  const careFollowup = await invoke("care-book-ai", {
    selectedChapter: 8,
    message: "Should I include the vitamins too?",
    history: [{
      role: "user",
      content:
        "How can I prepare my father's medication list for a clinic appointment?",
    }, { role: "assistant", content: care.answer }],
  });
  equal(careFollowup.status, "answered");
  ok(/vitamin|supplement/i.test(careFollowup.answer));
  console.log(
    JSON.stringify({
      feature: "care-book-ai-followup",
      syntheticAnswer: careFollowup.answer,
    }),
  );

  await pause(3000);
  const taglish = await invoke("care-book-ai", {
    selectedChapter: 4,
    message:
      "Paano ko matutulungan si lola na maalala ang clinic appointment niya? Simple Tagalog lang please.",
    history: [],
  });
  equal(taglish.status, "answered");
  ok(/\b(?:ang|ng|mga|niya|lola|para|puwede|pwede)\b/i.test(taglish.answer));
  console.log(
    JSON.stringify({
      feature: "care-book-ai-language",
      syntheticAnswer: taglish.answer,
    }),
  );
  console.log("PASS: Care Book follow-up and Tagalog language matching");

  const emergency = await invoke("health-bp-chat", {
    ...reading,
    message: "I have chest pain now.",
    history: [],
  });
  equal(emergency.status, "emergency_redirect");
  console.log("PASS: hosted emergency safeguard");
} finally {
  if (createdUserId) {
    const cleanup = await request(
      `${base}/auth/v1/admin/users/${createdUserId}`,
      {
        method: "DELETE",
        headers: headers(adminKey),
      },
    );
    if (!cleanup.ok) {
      console.error(
        `Synthetic user cleanup failed for ${createdUserId}: HTTP ${cleanup.status}`,
      );
      Deno.exitCode = 1;
    } else {
      console.log(
        "Removed the temporary synthetic Auth user and its cascaded profile.",
      );
    }
    await cleanup.arrayBuffer();
  }
}
