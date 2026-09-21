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
export const GEMINI_MODEL = "gemini-3.8-flash";
const connectionError =
  "EverCare AI couldn't connect right now. Please try again.";
const invalidOutputError =
  "EverCare AI couldn't generate a reply right now. Please try again.";

export async function requestGeminiStructuredJson({
  schema,
  messages,
  maxOutputTokens = 4096,
  thinkingLevel = "medium",
}: {
  schema: Record<string, unknown>;
  messages: ChatMessage[];
  maxOutputTokens?: number;
  thinkingLevel?: "low" | "medium" | "high";
}): Promise<Record<string, unknown>> {
  const apiKey = Deno.env.get("GEMINI_API_KEY")?.trim();
  if (!apiKey) {
    console.error("Gemini failure: missing server configuration.");
    throw new PublicFunctionError(503, connectionError);
  }

  // Keep trusted instructions separate from untrusted user/model turns. No
  // provider-side stored conversations, paid tools, or provider fallback.
  const systemParts = messages.filter((message) => message.role === "system")
    .map((message) => ({ text: message.content }));
  const contents = messages.filter((message) => message.role !== "system")
    .map((message) => ({
      role: message.role === "assistant" ? "model" : "user",
      parts: [{ text: message.content }],
    }));
  const controller = new AbortController();
  // Covers both the connection and reading the response body.
  const timeout = setTimeout(() => controller.abort(), 45000);
  try {
    const send = () =>
      fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
        {
          method: "POST",
          signal: controller.signal,
          headers: {
            "x-goog-api-key": apiKey,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            ...(systemParts.length
              ? { systemInstruction: { parts: systemParts } }
              : {}),
            contents,
            generationConfig: {
              thinkingConfig: { thinkingLevel },
              maxOutputTokens,
              responseMimeType: "application/json",
              responseJsonSchema: schema,
            },
          }),
        },
      );
    let response = await send();
    // A single bounded retry handles transient provider overload. Quota errors
    // are returned immediately, and both attempts share the same deadline.
    if ([502, 503, 504].includes(response.status)) {
      await response.body?.cancel();
      await new Promise((resolve) => setTimeout(resolve, 750));
      response = await send();
    }
    if (!response.ok) {
      console.error(`Gemini failure: HTTP ${response.status}.`);
      if (response.status === 429) {
        const retry = response.headers.get("retry-after");
        let seconds = retry && /^\d+$/.test(retry)
          ? Number(retry)
          : Math.ceil((Date.parse(retry ?? "") - Date.now()) / 1000);
        // QuotaFailure distinguishes a project-wide daily limit from a brief
        // rate limit. Inspect it even when a misleading short Retry-After is
        // supplied; never forward or log Google's raw error body.
        let dailyQuotaExceeded = false;
        try {
          const errorBody = await response.json();
          const details = errorBody?.error?.details;
          if (Array.isArray(details)) {
            dailyQuotaExceeded = details.some((detail) =>
              detail?.["@type"] ===
                "type.googleapis.com/google.rpc.QuotaFailure" &&
              Array.isArray(detail.violations) &&
              detail.violations.some((
                violation: { quotaId?: unknown } | null,
              ) =>
                typeof violation?.quotaId === "string" &&
                /PerDay/i.test(violation.quotaId)
              )
            );
          }
          if (!Number.isFinite(seconds) || seconds <= 0) {
            const retryInfo = Array.isArray(details)
              ? details.find((item) =>
                item?.["@type"] === "type.googleapis.com/google.rpc.RetryInfo"
              )
              : undefined;
            if (
              typeof retryInfo?.retryDelay === "string" &&
              /^\d+(?:\.\d+)?s$/.test(retryInfo.retryDelay)
            ) {
              seconds = Math.ceil(Number.parseFloat(retryInfo.retryDelay));
            }
          }
        } catch (_) {
          /* Keep the generic rate-limit response for an unusable error body. */
        }
        if (!response.bodyUsed) await response.body?.cancel();
        if (dailyQuotaExceeded) {
          throw new PublicFunctionError(
            429,
            "EverCare AI has reached its daily free limit. Please try again after the daily reset.",
            undefined,
            "AI_DAILY_QUOTA",
          );
        }
        throw new PublicFunctionError(
          429,
          "EverCare AI is receiving a lot of requests right now. Please try again in a moment.",
          Number.isFinite(seconds) && seconds > 0
            ? Math.min(seconds, 3600)
            : 15,
        );
      }
      await response.body?.cancel();
      throw new PublicFunctionError(503, connectionError);
    }
    const payload = await response.json();
    const candidate = payload?.candidates?.[0];
    if (
      payload?.promptFeedback?.blockReason || candidate?.finishReason !== "STOP"
    ) {
      console.error(
        "Gemini failure: blocked, incomplete, or missing candidate.",
      );
      throw new PublicFunctionError(503, invalidOutputError);
    }
    const parts = candidate?.content?.parts;
    if (!Array.isArray(parts)) {
      throw new PublicFunctionError(503, invalidOutputError);
    }
    // Never expose thinking text or thought signatures. Only final text parts
    // contribute to the structured answer sent to Flutter.
    const content = parts.filter((part) =>
      part && part.thought !== true && typeof part.text === "string"
    )
      .map((part) => part.text).join("").trim();
    const parsed = JSON.parse(content);
    if (
      !matchesSchema(parsed, schema) || parsed == null ||
      typeof parsed !== "object" || Array.isArray(parsed)
    ) {
      throw new PublicFunctionError(503, invalidOutputError);
    }
    return parsed as Record<string, unknown>;
  } catch (error) {
    if (error instanceof PublicFunctionError) throw error;
    console.error(
      controller.signal.aborted
        ? "Gemini failure: timeout."
        : "Gemini failure: transport or malformed response.",
    );
    throw new PublicFunctionError(
      503,
      error instanceof SyntaxError ? invalidOutputError : connectionError,
    );
  } finally {
    clearTimeout(timeout);
  }
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
