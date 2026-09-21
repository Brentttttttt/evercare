import { careBookSourcePack } from "../_shared/care_book_context.ts";
import {
  enforceCooldown,
  functionErrorResponse,
  jsonResponse,
  modelText,
  optionalConversationHistory,
  optionsResponse,
  PublicFunctionError,
  readJsonBody,
  requestGeminiStructuredJson,
  requiredInteger,
  requiredText,
  requireUserId,
} from "../_shared/ai.ts";
import {
  emergencyReply,
  everCareSystemPrompt,
  reportsImmediateEmergency,
} from "../_shared/health_conversation.ts";

const answerSchema = {
  type: "object",
  additionalProperties: false,
  required: ["status", "answer", "sources"],
  properties: {
    status: {
      type: "string",
      enum: ["answered", "ignored", "emergency_redirect"],
    },
    answer: { type: "string" },
    sources: {
      type: "array",
      items: { type: "integer", minimum: 1, maximum: 12 },
      minItems: 0,
      maxItems: 3,
    },
  },
};

export async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") return optionsResponse();
  if (req.method !== "POST") {
    return functionErrorResponse(
      new PublicFunctionError(405, "Method not allowed."),
    );
  }

  try {
    const userId = await requireUserId(req);
    const body = await readJsonBody(req);
    const message = requiredText(body.message, "message", 600);
    const selectedChapter = requiredInteger(
      body.selectedChapter,
      "selectedChapter",
      1,
      12,
    );
    const history = optionalConversationHistory(body.history);

    if (reportsImmediateEmergency(message)) {
      return jsonResponse({
        status: "emergency_redirect",
        answer: emergencyReply,
        sources: [12],
      });
    }

    enforceCooldown(userId, "care-book-ai", 2500);
    const completion = await requestGeminiStructuredJson({
      schema: answerSchema,
      messages: [
        {
          role: "system",
          content: [
            everCareSystemPrompt,
            "You are Care Guide, EverCare AI in Care Book mode. Help older adults, caregivers, and families with health education, medicines, meals, hydration, routines, appointments, safety, emotional support, and caregiver wellbeing. Preserve the older adult's preferences and independence. Distinguish the caregiver from the person receiving care.",
            "Use the source pack whenever relevant and list only chapter numbers directly used. For relevant general health or medication education not covered by the source pack, answer using cautious general information with an empty sources list. Never invent a source or claim you have checked a patient's records.",
            "Do not refuse ordinary BP, diagnosis-education, lifestyle, symptom-information, or medicine questions. Explain what can be understood from the available information while respecting the medical safety boundaries. If a user supplies a BP reading, distinguish that single measurement from a diagnosis and suggest the Health reading chat only when it would help, not as a substitute for answering.",
            "Classify responses as answered, ignored for clearly unrelated requests only, or emergency_redirect for genuine immediate danger. Return an empty answer for emergency_redirect because the server supplies that wording. For ignored, give a brief friendly redirection toward health and caregiving with no sources.",
            "Keep simple answers concise; expand only when useful, at most 250 words and 2400 characters. Return JSON matching the schema with status, answer, and up to 3 sources.",
            `CURRENT CARE BOOK CONTEXT: Selected chapter ${selectedChapter}.`,
            "SOURCE PACK:",
            careBookSourcePack,
          ].join("\n"),
        },
        ...history,
        { role: "user", content: message },
      ],
    });

    const status = completion.status;
    if (status === "emergency_redirect") {
      return jsonResponse({
        status,
        answer: emergencyReply,
        sources: [12],
      });
    }
    if (status !== "answered" && status !== "ignored") {
      throw new PublicFunctionError(
        503,
        "EverCare AI couldn't connect right now. Please try again.",
      );
    }
    return jsonResponse({
      // Preserve the app's existing display contract for a scope redirection.
      status: "answered",
      answer: modelText(completion.answer, "answer", 2400),
      sources: status === "ignored" ? [] : validSources(completion.sources),
    });
  } catch (error) {
    return functionErrorResponse(error);
  }
}

if (import.meta.main) Deno.serve(handleRequest);

function validSources(value: unknown): number[] {
  if (!Array.isArray(value)) return [];
  return [
    ...new Set(
      value.filter(
        (source): source is number =>
          typeof source === "number" &&
          Number.isInteger(source) &&
          source >= 1 &&
          source <= 12,
      ),
    ),
  ].slice(0, 3);
}
