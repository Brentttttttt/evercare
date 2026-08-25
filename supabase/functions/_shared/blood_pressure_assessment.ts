export type BloodPressureCategory =
  | "lower_than_usual"
  | "normal"
  | "elevated"
  | "hypertension_stage_1"
  | "hypertension_stage_2"
  | "severe_hypertension";

export type Assessment = {
  category: BloodPressureCategory;
  headline: string;
  rangeLabel: string;
  summary: string;
  nextStep: string;
};

type MeasurementRange =
  | "lower_than_usual"
  | "normal"
  | "elevated"
  | "stage_1"
  | "stage_2"
  | "severely_elevated";

export function assessBloodPressure(
  systolic: number,
  diastolic: number,
): Assessment {
  if (systolic > 180 || diastolic > 120) {
    return {
      category: "severe_hypertension",
      headline: "This reading needs urgent attention",
      rangeLabel: "Severely elevated blood pressure reading",
      summary: rangeSummary(
        systolic,
        diastolic,
        "severely_elevated",
        "severely elevated blood pressure reading",
      ),
      nextStep:
        "Sit quietly and repeat the measurement after at least 5 minutes. If the systolic value remains above 180 or the diastolic value remains above 120, seek urgent clinical advice. Call local emergency services immediately for chest pain, shortness of breath, weakness or numbness, vision changes, back pain, or trouble speaking.",
    };
  }
  if (systolic >= 140 || diastolic >= 90) {
    return {
      category: "hypertension_stage_2",
      headline: "This reading needs some attention",
      rangeLabel: "Stage 2 blood pressure range",
      summary: rangeSummary(
        systolic,
        diastolic,
        "stage_2",
        "Stage 2 blood pressure range",
      ),
      nextStep:
        "Rest quietly for at least 5 minutes, then check your blood pressure again with the cuff positioned correctly and your arm supported around heart level. Keep track of repeated readings. If similar readings continue, consider sharing them with a qualified healthcare professional.",
    };
  }
  if (systolic >= 130 || diastolic >= 80) {
    return {
      category: "hypertension_stage_1",
      headline: "Your reading is higher than recommended",
      rangeLabel: "Stage 1 blood pressure range",
      summary: rangeSummary(
        systolic,
        diastolic,
        "stage_1",
        "Stage 1 blood pressure range",
      ),
      nextStep:
        "Rest for a few minutes and consider checking again with the cuff positioned correctly and your arm supported around heart level. Keep track of repeated readings. If similar readings continue, consider sharing them with a qualified healthcare professional.",
    };
  }
  if (systolic >= 120 && diastolic < 80) {
    return {
      category: "elevated",
      headline: "Your reading is slightly raised",
      rangeLabel: "Elevated blood pressure range",
      summary: rangeSummary(
        systolic,
        diastolic,
        "elevated",
        "elevated blood pressure range",
      ),
      nextStep:
        "Continue keeping track of your blood pressure over time. You can rest for a few minutes and check again with the cuff positioned correctly and your arm supported around heart level.",
    };
  }
  if (systolic < 90 || diastolic < 60) {
    return {
      category: "lower_than_usual",
      headline: "This reading is lower than usual",
      rangeLabel: "Lower-than-usual blood pressure reading",
      summary: rangeSummary(
        systolic,
        diastolic,
        "lower_than_usual",
        "lower-than-usual blood pressure reading",
      ),
      nextStep:
        "If this measurement is unexpected, rest quietly and repeat it correctly. If the person feels faint, weak, confused, or unwell, contact a qualified healthcare professional.",
    };
  }
  return {
    category: "normal",
    headline: "Your reading looks good",
    rangeLabel: "Normal blood pressure range",
    summary: rangeSummary(
      systolic,
      diastolic,
      "normal",
      "normal blood pressure range",
    ),
    nextStep:
      "Continue recording readings over time and follow any care plan provided by a qualified healthcare professional.",
  };
}

function rangeSummary(
  systolic: number,
  diastolic: number,
  determiningRange: MeasurementRange,
  overallDescription: string,
): string {
  const systolicRange = rangeForSystolic(systolic);
  const diastolicRange = rangeForDiastolic(diastolic);
  const componentExplanation = [
    systolicExplanation(systolic),
    diastolicExplanation(diastolic),
  ].join(" ");

  let reason: string;
  const systolicDetermines = systolicRange === determiningRange;
  const diastolicDetermines = diastolicRange === determiningRange;
  const classificationLead = determiningRange === "severely_elevated" ||
      determiningRange === "lower_than_usual"
    ? `This is a ${overallDescription}`
    : `This reading is in the ${overallDescription}`;

  if (
    determiningRange === "lower_than_usual" &&
    systolicDetermines &&
    diastolicDetermines
  ) {
    reason = `${classificationLead} because both values are lower than usual.`;
  } else if (determiningRange === "lower_than_usual" && systolicDetermines) {
    reason =
      `${classificationLead} because the systolic value is lower than the usual adult range.`;
  } else if (determiningRange === "lower_than_usual" && diastolicDetermines) {
    reason =
      `${classificationLead} because the diastolic value is lower than the usual adult range.`;
  } else if (systolicDetermines && diastolicDetermines) {
    reason =
      `${classificationLead} because both values fall within that range.`;
  } else if (systolicDetermines) {
    reason =
      `${classificationLead} because the systolic value determines the higher range.`;
  } else if (diastolicDetermines) {
    reason =
      `${classificationLead} because the diastolic value determines the higher range.`;
  } else {
    reason = `This measurement includes a value outside the usual adult range.`;
  }

  const categorizationNote = determiningRange === "normal" ||
      determiningRange === "lower_than_usual"
    ? ""
    : " Blood pressure readings use whichever value falls into the higher category.";

  const singleReadingNote = determiningRange === "normal" ||
      determiningRange === "lower_than_usual"
    ? ""
    : " One reading alone does not mean that you have high blood pressure.";

  return `${componentExplanation} ${reason}${categorizationNote}${singleReadingNote}`;
}

export function systolicExplanation(value: number): string {
  return `Your upper number (systolic) is ${value} mmHg, which ${
    rangePhrase(rangeForSystolic(value))
  }.`;
}

export function diastolicExplanation(value: number): string {
  return `Your lower number (diastolic) is ${value} mmHg, which ${
    rangePhrase(rangeForDiastolic(value))
  }.`;
}

function rangeForSystolic(value: number): MeasurementRange {
  if (value > 180) return "severely_elevated";
  if (value >= 140) return "stage_2";
  if (value >= 130) return "stage_1";
  if (value >= 120) return "elevated";
  if (value < 90) return "lower_than_usual";
  return "normal";
}

function rangeForDiastolic(value: number): MeasurementRange {
  if (value > 120) return "severely_elevated";
  if (value >= 90) return "stage_2";
  if (value >= 80) return "stage_1";
  if (value < 60) return "lower_than_usual";
  return "normal";
}

function rangePhrase(range: MeasurementRange): string {
  switch (range) {
    case "lower_than_usual":
      return "is lower than the usual adult range";
    case "normal":
      return "is within the normal range";
    case "elevated":
      return "falls within the elevated range";
    case "stage_1":
      return "falls within the Stage 1 range";
    case "stage_2":
      return "falls within the Stage 2 range";
    case "severely_elevated":
      return "falls within the severely elevated range";
  }
}
