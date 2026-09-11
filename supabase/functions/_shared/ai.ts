const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

const recentRequests = new Map<string, number>();

export class PublicFunctionError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly retryAfterSeconds?: number,
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
): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      ...corsHeaders,
      ...(retryAfterSeconds == null
        ? {}
        : { "Retry-After": retryAfterSeconds.toString() }),
    },
  });
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
  if (!Array.isArray(value) || value.length > 8) {
    throw new PublicFunctionError(
      400,
      "history must contain 8 messages or fewer.",
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
      600,
    );
    totalCharacters += content.length;
    if (totalCharacters > 3200) {
      throw new PublicFunctionError(
        400,
        "history must contain 3200 characters or fewer.",
      );
    }
    return { role: record.role, content };
  });
}

type ChatMessage = {
  role: "system" | "user" | "assistant";
  content: string;
};
type ReasoningEffort = "low" | "medium" | "high";

export async function requestGroqStructuredJson({
  schemaName,
  schema,
  messages,
  maxCompletionTokens = 700,
  reasoningEffort = "medium",
  temperature = 0.2,
}: {
  schemaName: string;
  schema: Record<string, unknown>;
  messages: ChatMessage[];
  maxCompletionTokens?: number;
  reasoningEffort?: ReasoningEffort;
  temperature?: number;
}): Promise<Record<string, unknown>> {
  const apiKey = Deno.env.get("GROQ_API_KEY");
  if (!apiKey) {
    console.error("GROQ_API_KEY is not configured for this Edge Function.");
    throw new PublicFunctionError(503, "AI service is not configured yet.");
  }

  const response = await fetch(
    "https://api.groq.com/openai/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: Deno.env.get("GROQ_MODEL") ?? "openai/gpt-oss-120b",
        messages,
        // GPT-OSS completion tokens include reasoning tokens. Callers can
        // lower or raise this when a narrowly bounded task warrants it.
        reasoning_effort: reasoningEffort,
        temperature,
        max_completion_tokens: maxCompletionTokens,
        response_format: {
          type: "json_schema",
          json_schema: {
            name: schemaName,
            strict: true,
            schema,
          },
        },
      }),
    },
  );

  if (!response.ok) {
    const retryAfter = Number.parseInt(
      response.headers.get("retry-after") ?? "",
      10,
    );
    if (response.status === 429) {
      throw new PublicFunctionError(
        429,
        "EverCare AI is busy. Please try again shortly.",
        Number.isFinite(retryAfter) ? retryAfter : 15,
      );
    }
    console.error(`Groq request failed with HTTP ${response.status}.`);
    throw new PublicFunctionError(
      503,
      "EverCare AI is temporarily unavailable.",
    );
  }

  const payload = await response.json();
  const content = payload?.choices?.[0]?.message?.content;
  if (typeof content !== "string") {
    console.error("Groq returned a completion without text content.");
    throw new PublicFunctionError(
      503,
      "EverCare AI returned an invalid response.",
    );
  }
  try {
    const parsed = JSON.parse(content);
    if (parsed == null || typeof parsed !== "object" || Array.isArray(parsed)) {
      throw new Error("Structured output was not an object.");
    }
    return parsed as Record<string, unknown>;
  } catch (_) {
    console.error("Groq structured output could not be parsed.");
    throw new PublicFunctionError(
      503,
      "EverCare AI returned an invalid response.",
    );
  }
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
    return errorResponse(error.message, error.status, error.retryAfterSeconds);
  }
  console.error("Unhandled EverCare AI function error.");
  return errorResponse("EverCare AI is temporarily unavailable.", 503);
}
