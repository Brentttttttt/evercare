const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

const recentRequests = new Map<string, number>();

export type AiErrorCode = "AI_DAILY_QUOTA" | "AI_COOLDOWN";

export class PublicFunctionError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly retryAfterSeconds?: number,
    readonly code?: AiErrorCode,
  ) {
    super(message);
  }
}

export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), { status, headers: corsHeaders });
}

export function errorResponse(
  message: string,
  status: number,
  retryAfterSeconds?: number,
  code?: AiErrorCode,
): Response {
  return new Response(
    JSON.stringify({ error: message, ...(code ? { code } : {}) }),
    {
      status,
      headers: {
        ...corsHeaders,
        ...(retryAfterSeconds == null
          ? {}
          : { "Retry-After": retryAfterSeconds.toString() }),
      },
    },
  );
}

export function optionsResponse(): Response {
  return new Response("ok", { headers: corsHeaders });
}

export async function readJsonBody(
  req: Request,
): Promise<Record<string, unknown>> {
  try {
    const body = await req.json();
    if (body == null || typeof body !== "object" || Array.isArray(body)) {
      throw new PublicFunctionError(400, "A JSON object is required.");
    }
    return body as Record<string, unknown>;
  } catch (error) {
    if (error instanceof PublicFunctionError) throw error;
    throw new PublicFunctionError(400, "The request body must be valid JSON.");
  }
}

/// Verifies the caller independently in addition to the function gateway's
/// verify_jwt setting. No user id is ever accepted from a request body.
export async function requireUserId(req: Request): Promise<string> {
  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    throw new PublicFunctionError(401, "Sign in to use EverCare AI.");
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publishableKey = getSupabasePublishableKey();
  if (!supabaseUrl || !publishableKey) {
    console.error("Supabase function authentication is not configured.");
    throw new PublicFunctionError(
      503,
      "AI service is temporarily unavailable.",
    );
  }

  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      Authorization: authorization,
      apikey: publishableKey,
    },
  });
  if (response.status === 401 || response.status === 403) {
    throw new PublicFunctionError(401, "Your sign-in session has expired.");
  }
  if (!response.ok) {
    console.error(
      `Supabase Auth user lookup failed with HTTP ${response.status}.`,
    );
    throw new PublicFunctionError(
      503,
      "Account verification is temporarily unavailable.",
    );
  }
  const user = await response.json();
  if (typeof user?.id !== "string" || user.id.length === 0) {
    throw new PublicFunctionError(401, "Your sign-in session is invalid.");
  }
  return user.id;
}

function getSupabasePublishableKey(): string | undefined {
  const direct = Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (direct) return direct;

  const rawKeys = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (rawKeys) {
    try {
      const keys = JSON.parse(rawKeys) as Record<string, unknown>;
      if (typeof keys.default === "string") return keys.default;
    } catch (_) {
      console.error("SUPABASE_PUBLISHABLE_KEYS is not valid JSON.");
    }
  }

  // Compatibility fallback for projects that have not migrated from the
  // legacy JWT-based anon key.
  return Deno.env.get("SUPABASE_ANON_KEY");
}

/// A lightweight per-isolate cooldown that avoids accidental repeated taps.
/// Use an external shared rate limiter before relying on it for abuse control
/// across multiple production function instances.
export function enforceCooldown(
  userId: string,
  scope: string,
  cooldownMilliseconds: number,
): void {
  const key = `${scope}:${userId}`;
  const now = Date.now();
  const previous = recentRequests.get(key);
  if (previous != null && now - previous < cooldownMilliseconds) {
    const retryAfterSeconds = Math.max(
      1,
      Math.ceil((cooldownMilliseconds - (now - previous)) / 1000),
    );
    throw new PublicFunctionError(
      429,
      "Please wait a moment before asking EverCare AI again.",
      retryAfterSeconds,
      "AI_COOLDOWN",
    );
  }
  recentRequests.set(key, now);

  if (recentRequests.size > 1000) {
    const oldestAllowed = now - Math.max(cooldownMilliseconds * 4, 60000);
    for (const [requestKey, requestAt] of recentRequests) {
      if (requestAt < oldestAllowed) recentRequests.delete(requestKey);
    }
  }
}

export function requiredText(
  value: unknown,
  field: string,
  maximumLength: number,
): string {
  if (typeof value !== "string") {
    throw new PublicFunctionError(400, `${field} must be text.`);
  }
  const text = value.trim().replace(/\s+/g, " ");
  if (text.length === 0) {
    throw new PublicFunctionError(400, `${field} cannot be empty.`);
  }
  if (text.length > maximumLength) {
    throw new PublicFunctionError(
      400,
      `${field} must be ${maximumLength} characters or fewer.`,
    );
  }
  return text;
}

export function requiredInteger(
  value: unknown,
  field: string,
  minimum: number,
  maximum: number,
): number {
  if (
    typeof value !== "number" ||
    !Number.isInteger(value) ||
    value < minimum ||
    value > maximum
  ) {
    throw new PublicFunctionError(
      400,
      `${field} must be a whole number from ${minimum} to ${maximum}.`,
    );
  }
  return value;
}

export type ConversationHistoryMessage = {
  role: "user" | "assistant";
  content: string;
};

/// Accepts a small, in-memory conversation window from the app. System roles,
/// arbitrary metadata, and unbounded transcripts are rejected so callers
/// cannot expand the AI data boundary silently.
export function optionalConversationHistory(
  value: unknown,
): ConversationHistoryMessage[] {
  if (value == null) return [];
  if (!Array.isArray(value) || value.length > 16) {
    throw new PublicFunctionError(
      400,
      "history must contain 16 messages or fewer.",
    );
  }

  let totalCharacters = 0;
  return value.map((item, index) => {
    if (item == null || typeof item !== "object" || Array.isArray(item)) {
      throw new PublicFunctionError(
        400,
        `history item ${index + 1} must be an object.`,
      );
    }
    const record = item as Record<string, unknown>;
    const keys = Object.keys(record);
    if (
      keys.length !== 2 || !keys.includes("role") ||
      !keys.includes("content")
    ) {
      throw new PublicFunctionError(
        400,
        `history item ${index + 1} has unsupported fields.`,
      );
    }
    if (record.role !== "user" && record.role !== "assistant") {
      throw new PublicFunctionError(
        400,
        `history item ${index + 1} has an invalid role.`,
      );
    }
    const content = requiredText(
      record.content,
      `history item ${index + 1} content`,
      record.role === "user" ? 600 : 2400,
    );
    totalCharacters += content.length;
    if (totalCharacters > 16000) {
      throw new PublicFunctionError(
        400,
        "history must contain 16000 characters or fewer.",
      );
    }
    return { role: record.role, content };
  });
}

export type ChatMessage = {
  role: "system" | "user" | "assistant";
  content: string;
};
export const GROQ_MODEL = "openai/gpt-oss-120b";
const GROQ_FALLBACK_MODEL = "openai/gpt-oss-20b";
const connectionError =
  "EverCare AI couldn't connect right now. Please try again.";
const invalidOutputError =
  "EverCare AI couldn't generate a reply right now. Please try again.";

/**
 * Inaagapay's GPT-OSS conversation setup, adapted to authenticated server-side
 * use. Each target is tried at most once; fallbacks share a 45-second budget.
 * Keys, provider error bodies, and reasoning never cross the Flutter boundary.
 */
export async function requestAiStructuredJson({
  schema,
  messages,
  maxOutputTokens = 2048,
  reasoningEffort = "medium",
}: {
  schema: Record<string, unknown>;
  messages: ChatMessage[];
  maxOutputTokens?: number;
  reasoningEffort?: "low" | "medium" | "high";
}): Promise<Record<string, unknown>> {
  const apiKey = Deno.env.get("GROQ_API_KEY")?.trim();
  if (!apiKey) {
    console.error("AI failure: missing server configuration.");
    throw new PublicFunctionError(503, connectionError);
  }
  const attempts = [
    { provider: "groq", model: GROQ_MODEL, apiKey },
    { provider: "groq", model: GROQ_FALLBACK_MODEL, apiKey },
  ];
  const nvidiaKey = Deno.env.get("NVIDIA_API_KEY")?.trim();
  if (nvidiaKey) {
    // NVIDIA retired its 120B endpoint; use the verified available 20B model.
    attempts.push({
      provider: "nvidia",
      model: GROQ_FALLBACK_MODEL,
      apiKey: nvidiaKey,
    });
  }
  const deadline = Date.now() + 45000;
  const failures: ProviderFailure[] = [];
  for (const attempt of attempts) {
    const remaining = deadline - Date.now();
    if (remaining <= 0) {
      failures.push({ status: 503, dailyQuota: false, retryAfterSeconds: 15 });
      break;
    }
    const controller = new AbortController();
    const isGroq = attempt.provider === "groq";
    const timeout = setTimeout(
      () => controller.abort(),
      isGroq ? Math.min(15000, remaining) : remaining,
    );
    try {
      const response = await fetch(
        isGroq
          ? "https://api.groq.com/openai/v1/chat/completions"
          : "https://integrate.api.nvidia.com/v1/chat/completions",
        {
          method: "POST",
          signal: controller.signal,
          headers: {
            Authorization: `Bearer ${attempt.apiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: attempt.model,
            // Do not infer JSON mode from user text. NVIDIA's object mode
            // needs the schema in trusted instructions as well as validation.
            messages: isGroq ? messages : [
              {
                role: "system",
                content: `Return only a JSON object matching this schema: ${
                  JSON.stringify(schema)
                }`,
              },
              ...messages,
            ],
            temperature: 0.5,
            top_p: 0.95,
            stream: false,
            reasoning_effort: reasoningEffort,
            ...(isGroq
              ? {
                max_completion_tokens: maxOutputTokens,
                include_reasoning: false,
                response_format: {
                  type: "json_schema",
                  json_schema: {
                    name: "evercare_response",
                    strict: true,
                    schema,
                  },
                },
              }
              : {
                max_tokens: maxOutputTokens,
                response_format: { type: "json_object" },
              }),
          }),
        },
      );
      if (!response.ok) {
        console.error(
          `AI failure: ${attempt.provider} HTTP ${response.status}.`,
        );
        const failure = await readProviderFailure(response);
        if (
          response.status === 429 || response.status >= 500 ||
          [404, 408, 410, 413].includes(response.status) ||
          failure.modelOrContextLimit
        ) {
          failures.push(failure);
          continue;
        }
        // Do not hide authentication or request-contract errors with retries.
        throw new PublicFunctionError(503, connectionError);
      }
      const payload = await response.json();
      if (controller.signal.aborted) {
        throw new DOMException("Timed out", "AbortError");
      }
      const choice = payload?.choices?.[0];
      const message = choice?.message;
      if (
        choice?.finish_reason !== "stop" || message?.refusal ||
        message?.tool_calls?.length || typeof message?.content !== "string"
      ) {
        throw new PublicFunctionError(503, invalidOutputError);
      }
      // Only final content is eligible. Never fall back to reasoning fields,
      // repair truncated JSON, or turn provider errors into canned health advice.
      const parsed = JSON.parse(message.content.trim());
      if (
        !matchesSchema(parsed, schema) || parsed == null ||
        typeof parsed !== "object" || Array.isArray(parsed)
      ) {
        throw new PublicFunctionError(503, invalidOutputError);
      }
      return parsed as Record<string, unknown>;
    } catch (error) {
      if (error instanceof PublicFunctionError) throw error;
      if (error instanceof SyntaxError && !controller.signal.aborted) {
        console.error("AI failure: malformed output.");
        throw new PublicFunctionError(503, invalidOutputError);
      }
      console.error(
        controller.signal.aborted
          ? "AI failure: attempt timeout."
          : "AI failure: transport unavailable.",
      );
      failures.push({ status: 503, dailyQuota: false, retryAfterSeconds: 15 });
    } finally {
      clearTimeout(timeout);
    }
  }
  if (failures.length && failures.every((failure) => failure.dailyQuota)) {
    throw new PublicFunctionError(
      429,
      "EverCare AI has reached its daily free limit. Please try again after the daily reset.",
      undefined,
      "AI_DAILY_QUOTA",
    );
  }
  const lastFailure = failures.at(-1);
  if (lastFailure?.status === 429) {
    throw new PublicFunctionError(
      429,
      "EverCare AI is receiving a lot of requests right now. Please try again in a moment.",
      lastFailure.retryAfterSeconds,
    );
  }
  throw new PublicFunctionError(503, connectionError);
}

type ProviderFailure = {
  status: number;
  retryAfterSeconds: number;
  dailyQuota: boolean;
  modelOrContextLimit?: boolean;
};

async function readProviderFailure(
  response: Response,
): Promise<ProviderFailure> {
  let code = "";
  let message = "";
  try {
    const body = await response.json();
    code = typeof body?.error?.code === "string" ? body.error.code : "";
    message = typeof body?.error?.message === "string"
      ? body.error.message
      : "";
  } catch (_) {
    // An unreadable provider error must never be shown to the person chatting.
  }
  const retry = response.headers.get("retry-after");
  const seconds = retry && /^\d+(?:\.\d+)?$/.test(retry)
    ? Math.ceil(Number(retry))
    : Math.ceil((Date.parse(retry ?? "") - Date.now()) / 1000);
  return {
    status: response.status,
    retryAfterSeconds: Number.isFinite(seconds) && seconds > 0
      ? Math.min(seconds, 3600)
      : 15,
    dailyQuota: response.status === 429 &&
      /\b(?:tokens? per day|requests? per day|TPD|RPD)\b/i.test(message),
    modelOrContextLimit: response.status === 400 && (
      [
        "model_not_found",
        "model_decommissioned",
        "context_length_exceeded",
        "request_too_large",
      ].includes(code) ||
      /maximum context length|context length exceeded|request too large/i.test(
        message,
      )
    ),
  };
}

// Validate the small JSON Schema subset used by our three functions even if
// a provider responds with HTTP 200 but an unexpected output shape.
function matchesSchema(
  value: unknown,
  schema: Record<string, unknown>,
): boolean {
  if (Array.isArray(schema.enum) && !schema.enum.includes(value)) return false;
  if (schema.type === "object") {
    if (value == null || typeof value !== "object" || Array.isArray(value)) {
      return false;
    }
    const record = value as Record<string, unknown>;
    const properties = (schema.properties ?? {}) as Record<
      string,
      Record<string, unknown>
    >;
    if (
      Array.isArray(schema.required) &&
      schema.required.some((key) => !Object.hasOwn(record, key))
    ) return false;
    return Object.entries(record).every(([key, item]) =>
      Object.hasOwn(properties, key)
        ? matchesSchema(item, properties[key])
        : schema.additionalProperties !== false
    );
  }
  if (schema.type === "array") {
    return Array.isArray(value) &&
      (typeof schema.minItems !== "number" ||
        value.length >= schema.minItems) &&
      (typeof schema.maxItems !== "number" ||
        value.length <= schema.maxItems) &&
      value.every((item) =>
        matchesSchema(item, schema.items as Record<string, unknown>)
      );
  }
  if (schema.type === "string") {
    return typeof value === "string" &&
      (typeof schema.maxLength !== "number" ||
        value.length <= schema.maxLength);
  }
  if (schema.type === "boolean") return typeof value === "boolean";
  if (schema.type === "integer" || schema.type === "number") {
    return typeof value === "number" &&
      Number.isFinite(value) &&
      (schema.type !== "integer" || Number.isInteger(value)) &&
      (typeof schema.minimum !== "number" || value >= schema.minimum) &&
      (typeof schema.maximum !== "number" || value <= schema.maximum);
  }
  return false;
}

export function modelText(
  value: unknown,
  field: string,
  maximumLength: number,
): string {
  if (typeof value !== "string") {
    throw new PublicFunctionError(503, `EverCare AI returned no ${field}.`);
  }
  const text = value.trim();
  if (text.length === 0 || text.length > maximumLength) {
    throw new PublicFunctionError(
      503,
      `EverCare AI returned invalid ${field}.`,
    );
  }
  return text;
}

export function modelTextList(
  value: unknown,
  maximumItems: number,
  maximumItemLength: number,
): string[] {
  if (!Array.isArray(value) || value.length > maximumItems) {
    throw new PublicFunctionError(503, "EverCare AI returned invalid tips.");
  }
  return value.map((item) => modelText(item, "tip", maximumItemLength));
}

export function functionErrorResponse(error: unknown): Response {
  if (error instanceof PublicFunctionError) {
    return errorResponse(
      error.message,
      error.status,
      error.retryAfterSeconds,
      error.code,
    );
  }
  console.error("Unhandled EverCare AI function error.");
  return errorResponse(connectionError, 503);
}
