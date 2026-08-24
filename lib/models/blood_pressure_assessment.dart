/// Educational adult blood-pressure categories used to present one reading.
///
/// These categories help users decide when to repeat a measurement or contact
/// a professional. They are not a diagnosis and do not determine treatment.
enum BloodPressureCategory {
  lowerThanUsual,
  normal,
  elevated,
  hypertensionStage1,
  hypertensionStage2,
  severeHypertension,
}

class BloodPressureAssessment {
  const BloodPressureAssessment._({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.category,
  });

  factory BloodPressureAssessment.fromValues({
    required int systolic,
    required int diastolic,
    required int pulse,
  }) {
    if (systolic <= 0 || diastolic <= 0 || pulse <= 0) {
      throw ArgumentError('Blood-pressure and pulse values must be positive.');
    }

    final category = switch ((systolic, diastolic)) {
      (final sys, final dia) when sys > 180 || dia > 120 =>
        BloodPressureCategory.severeHypertension,
      (final sys, final dia) when sys >= 140 || dia >= 90 =>
        BloodPressureCategory.hypertensionStage2,
      (final sys, final dia) when sys >= 130 || dia >= 80 =>
        BloodPressureCategory.hypertensionStage1,
      (final sys, final dia) when sys >= 120 && dia < 80 =>
        BloodPressureCategory.elevated,
      (final sys, final dia) when sys < 90 || dia < 60 =>
        BloodPressureCategory.lowerThanUsual,
      _ => BloodPressureCategory.normal,
    };

    return BloodPressureAssessment._(
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      category: category,
    );
  }

  final int systolic;
  final int diastolic;
  final int pulse;
  final BloodPressureCategory category;

  String get categoryId => switch (category) {
    BloodPressureCategory.lowerThanUsual => 'lower_than_usual',
    BloodPressureCategory.normal => 'normal',
    BloodPressureCategory.elevated => 'elevated',
    BloodPressureCategory.hypertensionStage1 => 'hypertension_stage_1',
    BloodPressureCategory.hypertensionStage2 => 'hypertension_stage_2',
    BloodPressureCategory.severeHypertension => 'severe_hypertension',
  };

  String get label => switch (category) {
    BloodPressureCategory.lowerThanUsual => 'Lower-than-usual reading',
    BloodPressureCategory.normal => 'Within normal adult range',
    BloodPressureCategory.elevated => 'Elevated blood pressure',
    BloodPressureCategory.hypertensionStage1 => 'High blood pressure · Stage 1',
    BloodPressureCategory.hypertensionStage2 => 'High blood pressure · Stage 2',
    BloodPressureCategory.severeHypertension => 'Severely high reading',
  };

  String get shortLabel => switch (category) {
    BloodPressureCategory.lowerThanUsual => 'Lower than\nusual',
    BloodPressureCategory.normal => 'Normal\nrange',
    BloodPressureCategory.elevated => 'Elevated',
    BloodPressureCategory.hypertensionStage1 => 'High\nStage 1',
    BloodPressureCategory.hypertensionStage2 => 'High\nStage 2',
    BloodPressureCategory.severeHypertension => 'Severely\nhigh',
  };

  String get summary => switch (category) {
    BloodPressureCategory.lowerThanUsual =>
      'This is lower than the usual adult range. A clinician can assess whether it is concerning for this person.',
    BloodPressureCategory.normal =>
      'This single reading falls within the normal adult blood-pressure category.',
    BloodPressureCategory.elevated =>
      'This single reading is in the elevated adult blood-pressure category.',
    BloodPressureCategory.hypertensionStage1 =>
      'This single reading is in the Stage 1 high blood-pressure category.',
    BloodPressureCategory.hypertensionStage2 =>
      'This single reading is in the Stage 2 high blood-pressure category.',
    BloodPressureCategory.severeHypertension =>
      'This reading is severely high and needs prompt attention, especially if it stays this high after a repeat measurement.',
  };

  String get nextStep => switch (category) {
    BloodPressureCategory.lowerThanUsual =>
      'If this is unexpected or the person feels faint, weak, confused, or unwell, repeat the reading and contact a qualified health professional.',
    BloodPressureCategory.normal =>
      'Continue the care plan and record readings as instructed by the healthcare team.',
    BloodPressureCategory.elevated =>
      'Rest quietly, repeat the measurement correctly, and discuss repeated elevated readings with a qualified health professional.',
    BloodPressureCategory.hypertensionStage1 =>
      'Rest quietly, repeat the measurement correctly, and discuss persistent readings with a qualified health professional.',
    BloodPressureCategory.hypertensionStage2 =>
      'Rest quietly and repeat the measurement. If it remains this high, contact a qualified health professional promptly.',
    BloodPressureCategory.severeHypertension =>
      'Sit quietly and repeat after at least 5 minutes. If it remains above 180/120, seek urgent clinical advice. Call local emergency services immediately for chest pain, shortness of breath, weakness or numbness, vision changes, back pain, or trouble speaking.',
  };

  bool get needsUrgentFollowUp =>
      category == BloodPressureCategory.severeHypertension;
}
