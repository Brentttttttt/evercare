import {
  enforceCooldown,
  functionErrorResponse,
  jsonResponse,
  optionsResponse,
  PublicFunctionError,
  readJsonBody,
  requestGroqStructuredJson,
  requiredInteger,
  requireUserId,
} from "../_shared/ai.ts";
import { assessBloodPressure } from "../_shared/blood_pressure_assessment.ts";

type TipId =
  | "rest_and_repeat"
  | "use_correct_position"
  | "record_and_share"
  | "follow_care_plan";

const tipCatalog: Record<TipId, string> = {
  rest_and_repeat:
    "Sit comfortably and rest quietly for at least 5 minutes, then take another reading when you feel relaxed.",
  use_correct_position:
    "Keep the cuff positioned correctly and support your arm around heart level. Sit with your back supported, keep your feet flat, and avoid talking during the measurement.",
  record_and_share:
    "Keep track of repeated readings so you or a caregiver can review how they change over time.",
  follow_care_plan:
    "If similar readings continue, consider sharing them with a qualified healthcare professional and follow any care plan you already have.",
};

const tipIds = Object.keys(tipCatalog) as TipId[];

const insightSchema = {
  type: "object",
  additionalProperties: false,
  required: ["tipIds"],
  properties: {
    tipIds: {
      type: "array",
      items: { type: "string", enum: tipIds },
      minItems: 2,
      maxItems: 3,
    },
  },
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return optionsResponse();
  if (req.method !== "POST") {
    return functionErrorResponse(
      new PublicFunctionError(405, "Method not allowed."),
    );
  }

  try {
    const userId = await requireUserId(req);
    const body = await readJsonBody(req);
    const systolic = requiredInteger(body.systolic, "systolic", 1, 350);
    const diastolic = requiredInteger(body.diastolic, "diastolic", 1, 250);
    const pulse = requiredInteger(body.pulse, "pulse", 1, 300);
    enforceCooldown(userId, "health-bp-insight", 10000);
    const assessment = assessBloodPressure(systolic, diastolic);

    const completion = await requestGroqStructuredJson({
      schemaName: "evercare_bp_insight",
      schema: insightSchema,
      maxCompletionTokens: 220,
      reasoningEffort: "low",
      messages: [
        {
          role: "system",
          content: [
            "You are EverCare's health education assistant.",
            "Choose two or three useful tip IDs for the server-determined adult blood-pressure category and next step.",
            "Do not diagnose illness or decide the category, measurements, treatment, medicine, dosage, or urgency.",
            "Return only JSON matching the schema. EverCare maps the IDs to reviewed wording; you do not write user-visible medical text.",
          ].join(" "),
        },
        {
          role: "user",
          content: [
            `Server category: ${assessment.rangeLabel}.`,
            `Server next step: ${assessment.nextStep}`,
            "Available tip IDs:",
            ...tipIds.map((id) => `${id}: ${tipCatalog[id]}`),
          ].join("\n"),
        },
      ],
    });

    const tips = selectReviewedTips(completion.tipIds);

    return jsonResponse({
      status: assessment.category,
      headline: assessment.headline,
      rangeLabel: assessment.rangeLabel,
      systolic,
      diastolic,
      pulse,
      explanation: assessment.summary,
      tips,
      // Safety-critical category, action, and disclaimer remain deterministic;
      // the model only selects IDs that map to reviewed, server-owned tips.
      nextStep: assessment.nextStep,
      disclaimer:
        "This result describes this reading only and is not a medical diagnosis.",
      disclaimerDetails:
        "Blood pressure can change throughout the day. Repeated measurements and evaluation by a qualified healthcare professional are used when assessing high blood pressure.",
    });
  } catch (error) {
    return functionErrorResponse(error);
  }
});

function selectReviewedTips(value: unknown): string[] {
  const selectedIds: TipId[] = [];
  if (Array.isArray(value)) {
    for (const candidate of value) {
      if (
        typeof candidate === "string" &&
        Object.hasOwn(tipCatalog, candidate) &&
        !selectedIds.includes(candidate as TipId)
      ) {
        selectedIds.push(candidate as TipId);
      }
      if (selectedIds.length === 3) break;
    }
  }

  // Structured output normally supplies at least two IDs. These reviewed
  // defaults keep the response useful and deterministic if a provider ever
  // returns duplicates or malformed content.
  for (const fallback of tipIds) {
    if (selectedIds.length >= 2) break;
    if (!selectedIds.includes(fallback)) selectedIds.push(fallback);
  }

  return selectedIds.map((id) => tipCatalog[id]);
}
