import {
  enforceCooldown,
  functionErrorResponse,
  jsonResponse,
  modelText,
  modelTextList,
  optionsResponse,
  PublicFunctionError,
  readJsonBody,
  requestGroqStructuredJson,
  requiredInteger,
  requireUserId,
} from "../_shared/ai.ts";

type BloodPressureCategory =
  | "lower_than_usual"
  | "normal"
  | "elevated"
  | "hypertension_stage_1"
  | "hypertension_stage_2"
  | "severe_hypertension";

type Assessment = {
  category: BloodPressureCategory;
  label: string;
  summary: string;
  nextStep: string;
};

const insightSchema = {
  type: "object",
  additionalProperties: false,
  required: ["headline", "explanation", "tips"],
  properties: {
    headline: { type: "string" },
    explanation: { type: "string" },
    tips: {
      type: "array",
      items: { type: "string" },
      minItems: 2,
      maxItems: 3,
    },
  },
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return optionsResponse();
  if (req.method !== "POST") {
    return functionErrorResponse(new PublicFunctionError(405, "Method not allowed."));
  }

  try {
    const userId = await requireUserId(req);
    enforceCooldown(userId, "health-bp-insight", 10000);
    const body = await readJsonBody(req);
    const systolic = requiredInteger(body.systolic, "systolic", 1, 350);
    const diastolic = requiredInteger(body.diastolic, "diastolic", 1, 250);
    const pulse = requiredInteger(body.pulse, "pulse", 1, 300);
    const assessment = assess(systolic, diastolic);

    const completion = await requestGroqStructuredJson({
      schemaName: "evercare_bp_insight",
      schema: insightSchema,
      maxCompletionTokens: 360,
      messages: [
        {
          role: "system",
          content: [
            "You are EverCare's health education assistant.",
            "Write a calm, plain-language explanation for one adult blood-pressure reading.",
            "The category and next step below are server-determined. Do not reclassify it, diagnose illness, declare the person healthy, prescribe medicines, recommend dosage changes, or claim a monitor is medically validated.",
            "Give only general, low-risk measurement and self-care tips. Do not ask for or infer identity, history, or diagnoses.",
            "For a severe reading, reinforce the provided next step without minimizing it.",
            "Return JSON that matches the requested schema. Headline and explanation must be concise; tips must be short.",
          ].join(" "),
        },
        {
          role: "user",
          content: [
            `Corrected systolic: ${systolic} mmHg.`,
            `Diastolic: ${diastolic} mmHg.`,
            `Pulse: ${pulse} BPM.`,
            `Server category: ${assessment.label}.`,
            `Server summary: ${assessment.summary}`,
            `Server next step: ${assessment.nextStep}`,
          ].join("\n"),
        },
      ],
    });

    return jsonResponse({
      status: assessment.category,
      headline: modelText(completion.headline, "headline", 150),
      explanation: modelText(completion.explanation, "explanation", 700),
      tips: modelTextList(completion.tips, 3, 220),
      // Safety-critical category, action, and disclaimer remain deterministic;
      // the model only contributes explanatory wording and general tips.
      nextStep: assessment.nextStep,
      disclaimer:
        "This AI explanation is educational only. A single reading does not diagnose a condition or medically verify the monitor. Follow advice from a qualified healthcare professional.",
    });
  } catch (error) {
    return functionErrorResponse(error);
  }
});

function assess(systolic: number, diastolic: number): Assessment {
  if (systolic > 180 || diastolic > 120) {
    return {
      category: "severe_hypertension",
      label: "Severely high reading",
      summary:
        "This reading is severely high and needs prompt attention, especially if it stays this high after a repeat measurement.",
      nextStep:
        "Sit quietly and repeat after at least 5 minutes. If it remains above 180/120, seek urgent clinical advice. Call local emergency services immediately for chest pain, shortness of breath, weakness or numbness, vision changes, back pain, or trouble speaking.",
    };
  }
  if (systolic >= 140 || diastolic >= 90) {
    return {
      category: "hypertension_stage_2",
      label: "High blood pressure · Stage 2",
      summary:
        "This single reading is in the Stage 2 high blood-pressure category.",
      nextStep:
        "Rest quietly and repeat the measurement. If it remains this high, contact a qualified health professional promptly.",
    };
  }
  if (systolic >= 130 || diastolic >= 80) {
    return {
      category: "hypertension_stage_1",
      label: "High blood pressure · Stage 1",
      summary:
        "This single reading is in the Stage 1 high blood-pressure category.",
      nextStep:
        "Rest quietly, repeat the measurement correctly, and discuss persistent readings with a qualified health professional.",
    };
  }
  if (systolic >= 120 && diastolic < 80) {
    return {
      category: "elevated",
      label: "Elevated blood pressure",
      summary:
        "This single reading is in the elevated adult blood-pressure category.",
      nextStep:
        "Rest quietly, repeat the measurement correctly, and discuss repeated elevated readings with a qualified health professional.",
    };
  }
  if (systolic < 90 || diastolic < 60) {
    return {
      category: "lower_than_usual",
      label: "Lower-than-usual reading",
      summary:
        "This is lower than the usual adult range. A clinician can assess whether it is concerning for this person.",
      nextStep:
        "If this is unexpected or the person feels faint, weak, confused, or unwell, repeat the reading and contact a qualified health professional.",
    };
  }
  return {
    category: "normal",
    label: "Within normal adult range",
    summary:
      "This single reading falls within the normal adult blood-pressure category.",
    nextStep:
      "Continue the care plan and record readings as instructed by the healthcare team.",
  };
}
