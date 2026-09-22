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
  requestAiStructuredJson,
} from "./ai.ts";

const groqUrl = "https://api.groq.com/openai/v1/chat/completions";
const nvidiaUrl = "https://integrate.api.nvidia.com/v1/chat/completions";
const schema = {
  type: "object",
  additionalProperties: false,
  required: ["answer"],
  properties: { answer: { type: "string" } },
};
const messages = [
  { role: "system" as const, content: "Trusted instructions and BP context." },
  { role: "user" as const, content: "Could coffee affect it?" },
  {
    role: "assistant" as const,
    content: "Caffeine can temporarily affect BP.",
  },
  { role: "user" as const, content: "I had two cups earlier." },
  { role: "assistant" as const, content: "That could contribute." },
  {
    role: "user" as const,
    content: "How long should I wait before checking again?",
  },
];
const request = () => requestAiStructuredJson({ schema, messages });

function completion(answer = "Connected answer") {
  return Response.json({
    choices: [{
      finish_reason: "stop",
      message: {
        role: "assistant",
        content: JSON.stringify({ answer }),
        reasoning: "Private reasoning must not be exposed.",
      },
    }],
  });
}

async function withFetch(
  fetcher: typeof fetch,
  run: () => Promise<void>,
  nvidiaKey?: string,
) {
  const originalFetch = globalThis.fetch;
  const env: Record<string, string | undefined> = {
    GROQ_API_KEY: "synthetic-groq-key",
    NVIDIA_API_KEY: nvidiaKey,
    GEMINI_API_KEY: undefined,
  };
  const originalEnv = Object.fromEntries(
    Object.keys(env).map((name) => [name, Deno.env.get(name)]),
  );
  for (const [name, value] of Object.entries(env)) {
    if (value === undefined) Deno.env.delete(name);
    else Deno.env.set(name, value);
  }
  globalThis.fetch = fetcher;
  try {
    await run();
  } finally {
    globalThis.fetch = originalFetch;
    for (const name of Object.keys(env)) {
      if (originalEnv[name] === undefined) Deno.env.delete(name);
      else Deno.env.set(name, originalEnv[name]!);
    }
  }
}

Deno.test("Groq uses the source model, server-only authorization, structured output, and original conversation roles", async () => {
  let calls = 0;
  await withFetch((url, init) => {
    calls++;
    equal(url, groqUrl);
    const headers = new Headers(init?.headers);
    equal(headers.get("authorization"), "Bearer synthetic-groq-key");
    equal(headers.get("x-goog-api-key"), null);
    const body = JSON.parse(init!.body as string);
    equal(body.model, "openai/gpt-oss-120b");
    deepStrictEqual(body.messages, messages);
    deepStrictEqual(body.response_format, {
      type: "json_schema",
      json_schema: { name: "evercare_response", schema, strict: true },
    });
    equal(body.temperature, 0.5);
    equal(body.top_p, 0.95);
    equal(body.stream, false);
    equal(body.max_completion_tokens, 2048);
    equal(body.reasoning_effort, "medium");
    equal(body.include_reasoning, false);
    ok(!("tools" in body) && !("service_tier" in body));
    ok(!JSON.stringify(body).includes("synthetic-groq-key"));
    ok(!String(url).includes("synthetic-groq-key"));
    return Promise.resolve(completion());
  }, async () => {
    deepStrictEqual(await request(), { answer: "Connected answer" });
    equal(calls, 1);
  });
});

Deno.test("429, unavailable models, and transient failures fall back once to 20b without contacting Gemini or NVIDIA", async () => {
  for (const status of [429, 404, 408, 410, 413, 500, 502, 503, 504]) {
    const models: string[] = [];
    await withFetch((url, init) => {
      equal(url, groqUrl);
      const body = JSON.parse(init!.body as string);
      models.push(body.model);
      deepStrictEqual(body.messages, messages);
      return Promise.resolve(
        models.length === 1
          ? new Response("private provider detail", { status })
          : completion("Recovered"),
      );
    }, async () => {
      deepStrictEqual(await request(), { answer: "Recovered" });
      deepStrictEqual(models, ["openai/gpt-oss-120b", "openai/gpt-oss-20b"]);
    });
  }
});

Deno.test("recognized model and context errors permit a bounded fallback", async () => {
  for (
    const code of [
      "model_not_found",
      "context_length_exceeded",
      "request_too_large",
    ]
  ) {
    let calls = 0;
    await withFetch((url) => {
      equal(url, groqUrl);
      calls++;
      return Promise.resolve(
        calls === 1
          ? Response.json({ error: { code, message: "private diagnostic" } }, {
            status: 400,
          })
          : completion("Recovered"),
      );
    }, async () => {
      deepStrictEqual(await request(), { answer: "Recovered" });
      equal(calls, 2);
    });
  }
});

Deno.test("permanent request or authentication failures stop immediately with safe errors", async () => {
  for (const status of [400, 401, 403]) {
    let calls = 0;
    await withFetch(() => {
      calls++;
      return Promise.resolve(
        new Response("private provider credentials", { status }),
      );
    }, async () => {
      await rejects(request, (error: unknown) => {
        ok(error instanceof PublicFunctionError);
        equal(error.status, 503);
        ok(error.message.includes("couldn't connect"));
        ok(!/private|credentials/.test(error.message));
        return true;
      });
      equal(calls, 1);
    }, "synthetic-nvidia-key");
  }
});

Deno.test("exhausted targets return the final safe service error and never retry a target", async () => {
  for (const status of [429, 404, 500, 503]) {
    const models: string[] = [];
    await withFetch((url, init) => {
      equal(url, groqUrl);
      models.push(JSON.parse(init!.body as string).model);
      return Promise.resolve(
        new Response("sensitive provider detail", {
          status,
          headers: { "Retry-After": "42" },
        }),
      );
    }, async () => {
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
      deepStrictEqual(models, ["openai/gpt-oss-120b", "openai/gpt-oss-20b"]);
    });
  }
});

Deno.test("authentication failures cannot trigger fallback through a misleading provider error code", async () => {
  for (const status of [401, 403]) {
    let calls = 0;
    await withFetch(() => {
      calls++;
      return Promise.resolve(Response.json({
        error: {
          code: "model_not_found",
          message: "private credential details",
        },
      }, { status }));
    }, async () => {
      await rejects(
        request,
        (error: unknown) =>
          error instanceof PublicFunctionError && error.status === 503,
      );
      equal(calls, 1);
    }, "synthetic-nvidia-key");
  }
});

Deno.test("optional NVIDIA is the third target with its own key, JSON mode, trusted schema, and no Groq-only fields", async () => {
  const targets: string[] = [];
  await withFetch((url, init) => {
    targets.push(String(url));
    const body = JSON.parse(init!.body as string);
    const headers = new Headers(init?.headers);
    if (targets.length < 3) {
      equal(url, groqUrl);
      equal(headers.get("authorization"), "Bearer synthetic-groq-key");
      return Promise.resolve(new Response(null, { status: 429 }));
    }
    equal(url, nvidiaUrl);
    equal(headers.get("authorization"), "Bearer synthetic-nvidia-key");
    equal(body.model, "openai/gpt-oss-20b");
    deepStrictEqual(body.response_format, { type: "json_object" });
    equal(body.max_tokens, 2048);
    ok(!("max_completion_tokens" in body));
    ok(!("include_reasoning" in body));
    const system = body.messages.filter((item: { role: string }) =>
      item.role === "system"
    )
      .map((item: { content: string }) => item.content).join("\n");
    ok(system.includes(messages[0].content));
    ok(system.includes(JSON.stringify(schema)));
    deepStrictEqual(
      body.messages.filter((item: { role: string }) => item.role !== "system"),
      messages.filter((item) => item.role !== "system"),
    );
    ok(!JSON.stringify(body).includes("synthetic-nvidia-key"));
    return Promise.resolve(completion("NVIDIA recovered"));
  }, async () => {
    deepStrictEqual(await request(), { answer: "NVIDIA recovered" });
    deepStrictEqual(targets, [groqUrl, groqUrl, nvidiaUrl]);
  }, "synthetic-nvidia-key");
});

Deno.test("NVIDIA fallback is attempted only once even if every configured target is unavailable", async () => {
  const targets: string[] = [];
  await withFetch((url) => {
    targets.push(String(url));
    return Promise.resolve(new Response(null, { status: 503 }));
  }, async () => {
    await rejects(request, PublicFunctionError);
    deepStrictEqual(targets, [groqUrl, groqUrl, nvidiaUrl]);
  }, "synthetic-nvidia-key");
});

Deno.test("missing, refused, tool, incomplete, and malformed completions fail without retry or a medical fallback", async () => {
  const candidate = (
    content: unknown,
    finishReason = "stop",
    extras: Record<string, unknown> = {},
  ) => ({
    choices: [{ finish_reason: finishReason, message: { content, ...extras } }],
  });
  for (
    const payload of [
      {},
      { choices: [] },
      candidate('{"answer":"partial"}', "length"),
      candidate('{"answer":"blocked"}', "content_filter"),
      candidate('{"answer":"tool"}', "tool_calls"),
      candidate('{"answer":"unsafe"}', "stop", { refusal: "Refused" }),
      candidate('{"answer":"tool"}', "stop", {
        tool_calls: [{ type: "function" }],
      }),
      candidate(null),
      candidate(""),
      candidate([{ type: "text", text: '{"answer":"array"}' }]),
      candidate(null, "stop", { reasoning: '{"answer":"reasoning"}' }),
      candidate("not json"),
      candidate("null"),
      candidate('{"answer":4}'),
      candidate('{"unexpected":"value"}'),
      candidate('{"answer":"ok","extra":"untrusted"}'),
    ]
  ) {
    let calls = 0;
    await withFetch(() => {
      calls++;
      return Promise.resolve(Response.json(payload));
    }, async () => {
      await rejects(
        request,
        (error: unknown) =>
          error instanceof PublicFunctionError && error.status === 503,
      );
      equal(calls, 1);
    }, "synthetic-nvidia-key");
  }
  let calls = 0;
  await withFetch(() => {
    calls++;
    return Promise.resolve(new Response("not a JSON envelope"));
  }, async () => {
    await rejects(request, PublicFunctionError);
    equal(calls, 1);
  });
});

Deno.test("network exceptions permit a bounded fallback but their details stay private", async () => {
  let calls = 0;
  await withFetch(() => {
    calls++;
    return Promise.reject(new Error("private URL and credential"));
  }, async () => {
    await rejects(
      request,
      (error: unknown) =>
        error instanceof PublicFunctionError &&
        !error.message.includes("private"),
    );
    equal(calls, 2);
  });
});

Deno.test("daily quota is explicit only after all permitted targets exhaust their daily limits", async () => {
  for (
    const message of [
      "Tokens per day exhausted",
      "Requests per day exhausted",
      "Limit TPD reached",
      "Limit RPD reached",
    ]
  ) {
    for (const nvidiaKey of [undefined, "synthetic-nvidia-key"]) {
      let calls = 0;
      await withFetch(() => {
        calls++;
        return Promise.resolve(Response.json({ error: { message } }, {
          status: 429,
          headers: { "Retry-After": "24" },
        }));
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
        equal(calls, nvidiaKey ? 3 : 2);
      }, nvidiaKey);
    }
  }
});

Deno.test("mixed daily and temporary quotas are not mislabeled as daily exhaustion", async () => {
  for (const dailyFirst of [true, false]) {
    let calls = 0;
    await withFetch(() => {
      calls++;
      const daily = (calls === 1) === dailyFirst;
      return Promise.resolve(Response.json({
        error: {
          message: daily
            ? "Tokens per day exhausted"
            : "Tokens per minute exhausted",
        },
      }, { status: 429, headers: { "Retry-After": "12" } }));
    }, async () => {
      await rejects(request, (error: unknown) => {
        ok(error instanceof PublicFunctionError);
        equal(error.status, 429);
        equal(error.code, undefined);
        equal(error.retryAfterSeconds, 12);
        return true;
      });
      equal(calls, 2);
    });
  }
});

Deno.test("a primary daily quota does not prevent a healthy fallback from answering", async () => {
  let calls = 0;
  await withFetch(() => {
    calls++;
    return Promise.resolve(
      calls === 1
        ? Response.json({ error: { message: "Tokens per day exhausted" } }, {
          status: 429,
        })
        : completion("Fallback remains available"),
    );
  }, async () => {
    deepStrictEqual(await request(), { answer: "Fallback remains available" });
    equal(calls, 2);
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

Deno.test("attempt timeout aborts stalled fetches and returns a safe bounded error", async () => {
  const originalTimer = globalThis.setTimeout;
  globalThis.setTimeout =
    ((handler: () => void) => originalTimer(handler, 1)) as typeof setTimeout;
  let calls = 0;
  try {
    await withFetch((_url, init) => {
      calls++;
      return new Promise((_resolve, reject) => {
        init!.signal!.addEventListener(
          "abort",
          () => reject(new DOMException("private timeout", "AbortError")),
          { once: true },
        );
      });
    }, async () => {
      await rejects(
        request,
        (error: unknown) =>
          error instanceof PublicFunctionError &&
          error.message.includes("couldn't connect"),
      );
      ok(calls >= 1 && calls <= 2);
    });
  } finally {
    globalThis.setTimeout = originalTimer;
  }
});

Deno.test("attempt deadline includes reading the response body", async () => {
  const originalTimer = globalThis.setTimeout;
  globalThis.setTimeout =
    ((handler: () => void) => originalTimer(handler, 1)) as typeof setTimeout;
  let aborts = 0;
  try {
    await withFetch((_url, init) => {
      const body = new ReadableStream<Uint8Array>({
        start(controller) {
          init!.signal!.addEventListener("abort", () => {
            aborts++;
            controller.error(
              new DOMException("private body timeout", "AbortError"),
            );
          }, { once: true });
        },
      });
      return Promise.resolve(
        new Response(body, { headers: { "Content-Type": "application/json" } }),
      );
    }, async () => {
      await rejects(request, PublicFunctionError);
      ok(aborts >= 1 && aborts <= 2);
    });
  } finally {
    globalThis.setTimeout = originalTimer;
  }
});

Deno.test("Groq gets bounded attempts while NVIDIA gets only the remaining overall time budget", async () => {
  const originalTimer = globalThis.setTimeout;
  const originalNow = Date.now;
  const timeouts: number[] = [];
  let clock = 100000;
  Date.now = () => clock;
  globalThis.setTimeout = ((handler: () => void, timeout: number) => {
    timeouts.push(timeout);
    return originalTimer(handler, 1000);
  }) as typeof setTimeout;
  let calls = 0;
  try {
    await withFetch(() => {
      calls++;
      clock += 1000;
      return Promise.resolve(
        calls < 3
          ? new Response(null, { status: 503 })
          : completion("Backup answered"),
      );
    }, async () => {
      deepStrictEqual(await request(), { answer: "Backup answered" });
      equal(calls, 3);
      deepStrictEqual(timeouts, [15000, 15000, 43000]);
    }, "synthetic-nvidia-key");
  } finally {
    globalThis.setTimeout = originalTimer;
    Date.now = originalNow;
  }
});

Deno.test("an exhausted overall deadline stops before another provider target", async () => {
  const originalNow = Date.now;
  let clock = 100000;
  Date.now = () => clock;
  let calls = 0;
  try {
    await withFetch(() => {
      calls++;
      clock += 45001;
      return Promise.resolve(new Response(null, { status: 503 }));
    }, async () => {
      await rejects(request, PublicFunctionError);
      equal(calls, 1);
    }, "synthetic-nvidia-key");
  } finally {
    Date.now = originalNow;
  }
});

Deno.test("missing Groq server key never falls back to a client or Gemini key", async () => {
  await withFetch(() => {
    throw new Error("fetch must not run");
  }, async () => {
    Deno.env.delete("GROQ_API_KEY");
    Deno.env.set("GEMINI_API_KEY", "unused-synthetic-key");
    await rejects(request, PublicFunctionError);
  }, "synthetic-nvidia-key");
});

Deno.test("history permits 16 bounded role-preserving messages and rejects instruction roles or excess data", () => {
  const history = Array.from({ length: 16 }, (_, index) => ({
    role: index % 2 ? "assistant" : "user",
    content: "Context ".repeat(60).trim(),
  }));
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
