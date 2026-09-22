import {
  enforceCooldown,
  functionErrorResponse,
  jsonResponse,
  modelText,
  optionalConversationHistory,
  optionsResponse,
  PublicFunctionError,
  readJsonBody,
  requestAiStructuredJson,
  requiredInteger,
  requiredText,
  requireUserId,
} from "../_shared/ai.ts";
import {
  assessBloodPressure,
  type Assessment,
} from "../_shared/blood_pressure_assessment.ts";
import {
  emergencyReply,
  everCareSystemPrompt,
  reportsImmediateEmergency,
} from "../_shared/health_conversation.ts";

type ChatStatus = "answered" | "off_topic" | "emergency_redirect";

const answerSchema = {
  type: "object",
  additionalProperties: false,
  required: ["status", "answer"],
  properties: {
    status: {
      type: "string",
      enum: ["answered", "off_topic", "emergency_redirect"],
    },
    answer: { type: "string" },
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
    const systolic = requiredInteger(body.systolic, "systolic", 1, 350);
    const diastolic = requiredInteger(body.diastolic, "diastolic", 1, 250);
    const pulse = requiredInteger(body.pulse, "pulse", 1, 300);
    const assessment = assessBloodPressure(systolic, diastolic);
    const history = optionalConversationHistory(body.history);
    const reading = { systolic, diastolic, pulse, assessment };

    // Clear active emergencies do not depend on provider availability or quota.
    // Ambiguous/educational symptom questions still reach contextual reasoning.
    if (
      reportsImmediateEmergency(message, {
        severeBloodPressure: assessment.category === "severe_hypertension",
      })
    ) {
      return chatResponse({
        ...reading,
        status: "emergency_redirect",
        answer: emergencyReply,
      });
    }

    enforceCooldown(userId, "health-bp-chat", 2500);
    const completion = await requestAiStructuredJson({
      schema: answerSchema,
      messages: [
        {
          role: "system",
          content: [
            everCareSystemPrompt,
            "You are in Blood Pressure chat. Help with this measurement, follow-up questions, sensible lifestyle changes, general health and medication education, and related caregiving. Greetings are welcome. Mark only clearly unrelated requests off_topic.",
            "Return JSON with status answered, off_topic, or emergency_redirect and an answer. For emergency_redirect the server supplies emergency wording; use an empty answer. Otherwise answer the latest question in your own words, usually 2–5 sentences, expanding up to 250 words only when needed. Do not produce more than 2400 characters.",
            "Use the authoritative current measurement below without inventing readings, trends, symptoms, medicines, or a diagnosis. Needs Attention is a UI status, not an emergency diagnosis. Do not repeat the range or values unless they help answer the newest question. Existing severe-reading guidance remains authoritative.",
            "For caffeine follow-ups, correct earlier assistant claims if necessary: coffee could contribute but does not establish a cause, and it is not known to especially affect this person's diastolic number. Waiting at least 30 minutes without caffeine is preparation for a routine measurement, NOT proof that caffeine has worn off. At 30–60 minutes caffeine can still affect the reading; do not call that a caffeine-free baseline or say most people's caffeine is wearing off then. For 'how long should I wait', explain that distinction briefly and include quiet rest before rechecking. Never encourage someone to consume caffeine as a diagnostic challenge.",
            "CURRENT BP CONTEXT:",
            JSON.stringify({
              systolic,
              diastolic,
              pulse,
              bloodPressureUnit: "mmHg",
              pulseUnit: "BPM",
              resultStatus: {
                lower_than_usual: "Lower Reading",
                normal: "Looking Good",
                elevated: "Slightly Raised",
                hypertension_stage_1: "Above Recommended",
                hypertension_stage_2: "Needs Attention",
                severe_hypertension: "Urgent Attention",
              }[assessment.category],
              classification: assessment.rangeLabel,
              measurementExplanation: assessment.summary,
              nextStep: assessment.nextStep,
              dataShared:
                "Current corrected values, typed question, and bounded recent conversation only. No account identity, raw BLE packets, device details, or saved health history is added. User-typed identifying details are part of the submitted text.",
            }),
          ].join("\n"),
        },
        ...history,
        { role: "user", content: message },
      ],
    });

    const status = completion.status;
    if (
      status !== "answered" && status !== "off_topic" &&
      status !== "emergency_redirect"
    ) {
      throw new PublicFunctionError(
        503,
        "EverCare AI couldn't connect right now. Please try again.",
      );
    }
    // Keep useful generated answers intact. Numeric health education and a
    // brief medication caution must not replace an answer with a stock refusal.
    return chatResponse({
      ...reading,
      status,
      answer: status === "emergency_redirect"
        ? emergencyReply
        : modelText(completion.answer, "answer", 2400),
    });
  } catch (error) {
    return functionErrorResponse(error);
  }
}

if (import.meta.main) Deno.serve(handleRequest);

function chatResponse({
  status,
  answer,
  systolic,
  diastolic,
  pulse,
  assessment,
}: {
  status: ChatStatus;
  answer: string;
  systolic: number;
  diastolic: number;
  pulse: number;
  assessment: Assessment;
}): Response {
  return jsonResponse({
    status,
    answer,
    systolic,
    diastolic,
    pulse,
    category: assessment.category,
    urgentGuidance: assessment.category === "severe_hypertension"
      ? assessment.nextStep
      : null,
    disclaimer:
      "This chat explains this reading only and is not a medical diagnosis.",
  });
}
