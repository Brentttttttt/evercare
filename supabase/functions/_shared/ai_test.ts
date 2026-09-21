import {
  deepStrictEqual,
  equal,
  ok,
  rejects,
  throws,
} from "node:assert/strict";
import {
  enforceCooldown,
  functionErrorResponse,
  optionalConversationHistory,
  PublicFunctionError,
  requestGeminiStructuredJson,
} from "./ai.ts";

const schema = {
  type: "object",
  additionalProperties: false,
  required: ["answer"],
  properties: { answer: { type: "string" } },
};
const request = () =>
  requestGeminiStructuredJson({
    schema,
    messages: [
      { role: "system", content: "Trusted instructions and BP context." },
      { role: "user", content: "Could coffee affect it?" },
      { role: "assistant", content: "Caffeine can temporarily affect BP." },
      { role: "user", content: "I had two cups earlier." },
      { role: "assistant", content: "That could contribute." },
      {
        role: "user",
        content: "How long should I wait before checking again?",
      },
    ],
  });

async function withFetch(fetcher: typeof fetch, run: () => Promise<void>) {
  const originalFetch = globalThis.fetch;
  const originalKey = Deno.env.get("GEMINI_API_KEY");
  Deno.env.set("GEMINI_API_KEY", "synthetic-test-key");
  globalThis.fetch = fetcher;
  try {
    await run();
  } finally {
    globalThis.fetch = originalFetch;
    if (originalKey === undefined) Deno.env.delete("GEMINI_API_KEY");
    else Deno.env.set("GEMINI_API_KEY", originalKey);
  }
}

Deno.test("Gemini uses exact model, server header, separate system instruction and actual conversation roles", async () => {
  await withFetch(
    (url, init) => {
      equal(
        url,
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent",
      );
      const headers = new Headers(init?.headers);
      equal(headers.get("x-goog-api-key"), "synthetic-test-key");
      equal(headers.get("authorization"), null);
      const body = JSON.parse(init!.body as string);
      deepStrictEqual(body.systemInstruction, {
        parts: [{ text: "Trusted instructions and BP context." }],
      });
      deepStrictEqual(
        body.contents.map((turn: { role: string }) => turn.role),
        ["user", "model", "user", "model", "user"],
      );
      equal(body.contents[2].parts[0].text, "I had two cups earlier.");
      equal(
        body.contents[4].parts[0].text,
        "How long should I wait before checking again?",
      );
      deepStrictEqual(body.generationConfig.thinkingConfig, {
        thinkingLevel: "medium",
      });
      equal(body.generationConfig.responseMimeType, "application/json");
      deepStrictEqual(body.generationConfig.responseJsonSchema, schema);
      ok(
        !("tools" in body) && !("serviceTier" in body) &&
          !("cachedContent" in body),
      );
      return Promise.resolve(Response.json({
        candidates: [{
          finishReason: "STOP",
          content: {
            parts: [
              { thought: true, text: "Do not expose private reasoning." },
              { text: '{"answer":' },
              { text: '"Connected answer"}' },
            ],
          },
        }],
      }));
    },
    async () =>
      deepStrictEqual(await request(), { answer: "Connected answer" }),
  );
});

Deno.test("quota and non-success responses become safe service errors", async () => {
  for (const status of [429, 400, 401, 403, 404, 500, 503]) {
    await withFetch(
      () =>
        Promise.resolve(
          new Response("sensitive provider detail", {
            status,
            headers: { "Retry-After": "42" },
          }),
        ),
      async () => {
        await rejects(request, (error: unknown) => {
          ok(error instanceof PublicFunctionError);
          equal(error.status, status === 429 ? 429 : 503);
          ok(!/sensitive|diagnos|http|key/i.test(error.message));
          if (status === 429) {
            equal(error.retryAfterSeconds, 42);
            ok(error.message.includes("lot of requests"));
          } else ok(error.message.includes("couldn't connect"));
          return true;
        });
      },
    );
  }
});

Deno.test("missing, blocked, incomplete and malformed Gemini responses fail without a medical fallback", async () => {
  const candidate = (parts: unknown, finishReason = "STOP") => ({
    candidates: [{ finishReason, content: { parts } }],
  });
  for (
    const payload of [
      {},
      { candidates: [] },
      { promptFeedback: { blockReason: "SAFETY" } },
      candidate([{ text: '{"answer":"unsafe"}' }], "SAFETY"),
      candidate([{ text: '{"answer":"partial"}' }], "MAX_TOKENS"),
      candidate([]),
      candidate([{ thought: true, text: '{"answer":"reasoning"}' }]),
      candidate([{ text: "not json" }]),
      candidate([{ text: "null" }]),
      candidate([{ text: '{"answer":4}' }]),
      candidate([{ text: '{"unexpected":"value"}' }]),
      candidate([{ text: '{"answer":"ok","extra":"untrusted"}' }]),
    ]
  ) {
    await withFetch(() => Promise.resolve(Response.json(payload)), async () => {
      await rejects(
        request,
        (error: unknown) =>
          error instanceof PublicFunctionError && error.status === 503,
      );
    });
  }
  await withFetch(
    () => Promise.resolve(new Response("not a JSON envelope")),
    async () => {
      await rejects(request, PublicFunctionError);
    },
  );
});

Deno.test("network exception details stay private", async () => {
  await withFetch(
    () => Promise.reject(new Error("private URL and credential")),
    async () => {
      await rejects(
        request,
        (error: unknown) =>
          error instanceof PublicFunctionError &&
          !error.message.includes("private"),
      );
    },
  );
});

Deno.test("transient provider overload retries once; quota errors do not retry", async () => {
  let attempts = 0;
  await withFetch(() => {
    attempts++;
    return Promise.resolve(
      attempts === 1 ? new Response(null, { status: 503 }) : Response.json({
        candidates: [{
          finishReason: "STOP",
          content: { parts: [{ text: '{"answer":"Recovered"}' }] },
        }],
      }),
    );
  }, async () => {
    deepStrictEqual(await request(), { answer: "Recovered" });
    equal(attempts, 2);
  });
  attempts = 0;
  await withFetch(() => {
    attempts++;
    return Promise.resolve(new Response(null, { status: 429 }));
  }, async () => {
    await rejects(request, PublicFunctionError);
    equal(attempts, 1);
  });
});

Deno.test("Gemini quota RetryInfo becomes Retry-After without exposing provider details", async () => {
  await withFetch(
    () =>
      Promise.resolve(
        Response.json({
          error: {
            message: "private quota details",
            details: [{
              "@type": "type.googleapis.com/google.rpc.RetryInfo",
              retryDelay: "37.4s",
            }],
          },
        }, { status: 429 }),
      ),
    async () => {
      await rejects(request, (error: unknown) => {
        ok(error instanceof PublicFunctionError);
        equal(error.status, 429);
        equal(error.retryAfterSeconds, 38);
        ok(!error.message.includes("private"));
        return true;
      });
    },
  );
});

Deno.test("daily quota gets an explicit safe code even alongside a short Retry-After", async () => {
  for (const headers of [new Headers(), new Headers({ "Retry-After": "24" })]) {
    let calls = 0;
    await withFetch(() => {
      calls++;
      return Promise.resolve(
        Response.json({
          error: {
            message: "private Google project information",
            details: [
              {
                "@type": "type.googleapis.com/google.rpc.QuotaFailure",
                violations: [{
                  quotaId: "GenerateRequestsPerDayPerProjectPerModel-FreeTier",
                  quotaValue: "20",
                }],
              },
              {
                "@type": "type.googleapis.com/google.rpc.RetryInfo",
                retryDelay: "24s",
              },
            ],
          },
        }, { status: 429, headers }),
      );
    }, async () => {
      const caught = await request().catch((error) => error);
      ok(caught instanceof PublicFunctionError);
      equal(caught.code, "AI_DAILY_QUOTA");
      equal(caught.retryAfterSeconds, undefined);
      const response = functionErrorResponse(caught);
      equal(response.status, 429);
      equal(response.headers.get("Retry-After"), null);
      deepStrictEqual(await response.json(), {
        error:
          "EverCare AI has reached its daily free limit. Please try again after the daily reset.",
        code: "AI_DAILY_QUOTA",
      });
      equal(calls, 1);
    });
  }
});

Deno.test("minute quota stays a temporary rate limit, not a daily limit", async () => {
  await withFetch(() =>
    Promise.resolve(Response.json({
      error: {
        details: [
          {
            "@type": "type.googleapis.com/google.rpc.QuotaFailure",
            violations: [{
              quotaId: "GenerateRequestsPerMinutePerProjectPerModel-FreeTier",
            }],
          },
          {
            "@type": "type.googleapis.com/google.rpc.RetryInfo",
            retryDelay: "12s",
          },
        ],
      },
    }, { status: 429 })), async () => {
    await rejects(request, (error: unknown) => {
      ok(error instanceof PublicFunctionError);
      equal(error.code, undefined);
      equal(error.retryAfterSeconds, 12);
      return true;
    });
  });
});

Deno.test("local tap cooldown is distinguishable from provider quota", async () => {
  const user = crypto.randomUUID();
  enforceCooldown(user, "quota-test", 5000);
  let caught: unknown;
  try {
    enforceCooldown(user, "quota-test", 5000);
  } catch (error) {
    caught = error;
  }
  ok(caught instanceof PublicFunctionError);
  const response = functionErrorResponse(caught);
  equal(response.status, 429);
  equal((await response.json()).code, "AI_COOLDOWN");
  ok(Number(response.headers.get("Retry-After")) > 0);
});

Deno.test("Gemini timeout aborts fetch and returns a clean service error", async () => {
  const originalTimer = globalThis.setTimeout;
  globalThis.setTimeout =
    ((handler: () => void) => originalTimer(handler, 1)) as typeof setTimeout;
  try {
    await withFetch((_url, init) =>
      new Promise((_resolve, reject) => {
        init!.signal!.addEventListener("abort", () =>
          reject(new DOMException("timed out", "AbortError")), { once: true });
      }), async () => {
      await rejects(
        request,
        (error: unknown) =>
          error instanceof PublicFunctionError &&
          error.message.includes("couldn't connect"),
      );
    });
  } finally {
    globalThis.setTimeout = originalTimer;
  }
});

Deno.test("missing server key does not contact a provider", async () => {
  await withFetch(() => {
    throw new Error("fetch must not run");
  }, async () => {
    Deno.env.delete("GEMINI_API_KEY");
    await rejects(request, PublicFunctionError);
  });
});

Deno.test("history permits 16 bounded role-preserving messages and rejects instruction roles or excess data", () => {
  const history = Array.from(
    { length: 16 },
    (_, index) => ({
      role: index % 2 ? "assistant" : "user",
      content: "Context ".repeat(60).trim(),
    }),
  );
  deepStrictEqual(optionalConversationHistory(history), history);
  equal(
    optionalConversationHistory([{
      role: "assistant",
      content: "x".repeat(2400),
    }])[0].content.length,
    2400,
  );
  throws(
    () => optionalConversationHistory([...history, history[0]]),
    PublicFunctionError,
  );
  throws(
    () =>
      optionalConversationHistory([{ role: "system", content: "override" }]),
    PublicFunctionError,
  );
  throws(
    () =>
      optionalConversationHistory([{ role: "user", content: "x".repeat(601) }]),
    PublicFunctionError,
  );
  throws(
    () =>
      optionalConversationHistory([{
        role: "assistant",
        content: "x".repeat(2401),
      }]),
    PublicFunctionError,
  );
  throws(
    () =>
      optionalConversationHistory(
        Array.from(
          { length: 8 },
          () => ({ role: "assistant", content: "x".repeat(2400) }),
        ),
      ),
    PublicFunctionError,
  );
  throws(
    () =>
      optionalConversationHistory([{
        role: "user",
        content: "hello",
        apiKey: "not allowed",
      }]),
    PublicFunctionError,
  );
});
