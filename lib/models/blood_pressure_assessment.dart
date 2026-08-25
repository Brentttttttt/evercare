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
  static const String shortDisclaimer =
      'This result describes this reading only and is not a medical diagnosis.';

  static const String additionalDisclaimerInfo =
      'Blood pressure can change throughout the day. Repeated measurements '
      'and evaluation by a qualified healthcare professional are used when '
      'assessing high blood pressure.';

  /// Kept as an alias for existing result screens while they adopt the
  /// friendlier, shorter disclaimer.
  static const String measurementOnlyDisclaimer = shortDisclaimer;

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

  /// Presentation label for the systolic (upper-number) component only.
  String get systolicRangeLabel => _rangeForSystolic(systolic).compactLabel;

  /// Presentation label for the diastolic (lower-number) component only.
  String get diastolicRangeLabel => _rangeForDiastolic(diastolic).compactLabel;

  /// Whether the systolic component contributes to the displayed result.
  bool get systolicSetsDisplayedRange =>
      _rangeForSystolic(systolic) == _rangeForCategory(category);

  /// Whether the diastolic component contributes to the displayed result.
  bool get diastolicSetsDisplayedRange =>
      _rangeForDiastolic(diastolic) == _rangeForCategory(category);

  String get categoryId => switch (category) {
    BloodPressureCategory.lowerThanUsual => 'lower_than_usual',
    BloodPressureCategory.normal => 'normal',
    BloodPressureCategory.elevated => 'elevated',
    BloodPressureCategory.hypertensionStage1 => 'hypertension_stage_1',
    BloodPressureCategory.hypertensionStage2 => 'hypertension_stage_2',
    BloodPressureCategory.severeHypertension => 'severe_hypertension',
  };

  String get label => switch (category) {
    BloodPressureCategory.lowerThanUsual =>
      'Lower-than-usual blood pressure reading',
    BloodPressureCategory.normal => 'Normal blood pressure range',
    BloodPressureCategory.elevated => 'Elevated blood pressure range',
    BloodPressureCategory.hypertensionStage1 => 'Stage 1 blood pressure range',
    BloodPressureCategory.hypertensionStage2 => 'Stage 2 blood pressure range',
    BloodPressureCategory.severeHypertension =>
      'Severely elevated blood pressure reading',
  };

  String get shortLabel => switch (category) {
    BloodPressureCategory.lowerThanUsual => 'Lower Than Usual',
    BloodPressureCategory.normal => 'Normal Range',
    BloodPressureCategory.elevated => 'Elevated Range',
    BloodPressureCategory.hypertensionStage1 => 'Stage 1 Range',
    BloodPressureCategory.hypertensionStage2 => 'Stage 2 Range',
    BloodPressureCategory.severeHypertension => 'Severely Elevated',
  };

  /// The calm, plain-language status that should lead a result screen.
  String get friendlyStatus => switch (category) {
    BloodPressureCategory.lowerThanUsual => 'This reading is lower than usual',
    BloodPressureCategory.normal => 'Your reading looks good',
    BloodPressureCategory.elevated => 'Your reading is slightly raised',
    BloodPressureCategory.hypertensionStage1 =>
      'Your reading is higher than recommended',
    BloodPressureCategory.hypertensionStage2 =>
      'This reading needs some attention',
    BloodPressureCategory.severeHypertension =>
      'This reading needs urgent attention',
  };

  /// A friendly status for compact badges and circular indicators.
  String get friendlyCompactLabel => switch (category) {
    BloodPressureCategory.lowerThanUsual => 'Lower Reading',
    BloodPressureCategory.normal => 'Looking Good',
    BloodPressureCategory.elevated => 'Slightly Raised',
    BloodPressureCategory.hypertensionStage1 => 'Above Recommended',
    BloodPressureCategory.hypertensionStage2 => 'Needs Attention',
    BloodPressureCategory.severeHypertension => 'Urgent Attention',
  };

  /// A short, supportive description of this measurement's range.
  String get friendlySupportingText => switch (category) {
    BloodPressureCategory.lowerThanUsual =>
      'One or both values are lower than the usual adult range. If this is '
          'unexpected, rest quietly and check the reading again.',
    BloodPressureCategory.normal =>
      'Your blood pressure reading is within the normal range.',
    BloodPressureCategory.elevated =>
      'Your reading is a little higher than the normal range. You can '
          'continue keeping track of your blood pressure over time.',
    BloodPressureCategory.hypertensionStage1 =>
      'One or both of your blood pressure values are higher than the '
          'recommended range. A single reading does not diagnose high blood '
          'pressure.',
    BloodPressureCategory.hypertensionStage2 =>
      'One or both of your blood pressure values are in a higher range. One '
          'reading alone does not diagnose high blood pressure.',
    BloodPressureCategory.severeHypertension =>
      'This reading is severely elevated and needs urgent attention, '
          'especially if it stays this high after a repeat measurement.',
  };

  /// Explains how the two values determine this measurement's category.
  ///
  /// This deliberately describes a reading rather than diagnosing a person.
  String get upperLowerExplanation {
    final systolicRange = _rangeForSystolic(systolic);
    final diastolicRange = _rangeForDiastolic(diastolic);
    final overallRange = _rangeForCategory(category);

    final valueExplanation = systolicRange == diastolicRange
        ? 'Your upper number (systolic) is $systolic mmHg, and your lower '
              'number (diastolic) is $diastolic mmHg. Both values are within '
              '${systolicRange.sentenceRange}.'
        : 'Your upper number (systolic) is $systolic mmHg, which is within '
              '${systolicRange.sentenceRange}. Your lower number (diastolic) '
              'is $diastolic mmHg, which falls within '
              '${diastolicRange.sentenceRange}.';

    final systolicDetermines = systolicRange == overallRange;
    final diastolicDetermines = diastolicRange == overallRange;
    final categoryExplanation = switch (category) {
      BloodPressureCategory.lowerThanUsual =>
        'A reading is shown as lower than usual when either value is below '
            'the usual adult range.',
      _ when systolicDetermines && diastolicDetermines =>
        'Both values place this measurement in '
            '${overallRange.sentenceRange}.',
      _ when systolicDetermines =>
        'Your upper number (systolic) determines '
            '${overallRange.sentenceRange} for this measurement. Blood '
            'pressure readings use whichever value falls into the higher '
            'category.',
      _ when diastolicDetermines =>
        'Your lower number (diastolic) determines '
            '${overallRange.sentenceRange} for this measurement. Blood '
            'pressure readings use whichever value falls into the higher '
            'category.',
      _ => 'This measurement includes a value outside the usual adult range.',
    };

    return '$valueExplanation $categoryExplanation';
  }

  /// Backwards-compatible detailed explanation for existing result screens.
  String get rangeExplanation =>
      '$friendlySupportingText $upperLowerExplanation';

  String get summary => rangeExplanation;

  String get shortNextAction => switch (category) {
    BloodPressureCategory.lowerThanUsual =>
      'Rest for at least 5 minutes, keep your arm supported around heart '
          'level, and check again. If you feel faint, weak, confused, or '
          'unwell, contact a qualified healthcare professional.',
    BloodPressureCategory.normal => 'Keep tracking your readings over time.',
    BloodPressureCategory.elevated =>
      'Keep tracking your readings over time. Sit comfortably, support your '
          'arm around heart level, and check again when you are relaxed.',
    BloodPressureCategory.hypertensionStage1 =>
      'Rest for a few minutes, support your arm around heart level, and '
          'consider checking again. If similar readings continue, consider '
          'sharing them with a healthcare professional.',
    BloodPressureCategory.hypertensionStage2 =>
      'Rest for at least 5 minutes while sitting comfortably, support your '
          'arm around heart level, and check again. If similar readings continue, '
          'consider sharing them with a healthcare professional.',
    BloodPressureCategory.severeHypertension =>
      'Sit quietly and repeat the measurement after at least 5 minutes. If the systolic value remains above 180 or the diastolic value remains above 120, seek urgent clinical advice. Call local emergency services immediately for chest pain, shortness of breath, weakness or numbness, vision changes, back pain, or trouble speaking.',
  };

  String get nextStep => shortNextAction;

  bool get needsUrgentFollowUp =>
      category == BloodPressureCategory.severeHypertension;
}

enum _MeasurementRange {
  lowerThanUsual('a lower-than-usual range', 'Lower than usual'),
  normal('the normal range', 'Normal range'),
  elevated('the elevated range', 'Elevated range'),
  stage1('the Stage 1 range', 'Stage 1 range'),
  stage2('the Stage 2 range', 'Stage 2 range'),
  severelyElevated('the severely elevated range', 'Severely elevated');

  const _MeasurementRange(this.sentenceRange, this.compactLabel);

  final String sentenceRange;
  final String compactLabel;
}

_MeasurementRange _rangeForCategory(BloodPressureCategory category) =>
    switch (category) {
      BloodPressureCategory.lowerThanUsual => _MeasurementRange.lowerThanUsual,
      BloodPressureCategory.normal => _MeasurementRange.normal,
      BloodPressureCategory.elevated => _MeasurementRange.elevated,
      BloodPressureCategory.hypertensionStage1 => _MeasurementRange.stage1,
      BloodPressureCategory.hypertensionStage2 => _MeasurementRange.stage2,
      BloodPressureCategory.severeHypertension =>
        _MeasurementRange.severelyElevated,
    };

_MeasurementRange _rangeForSystolic(int systolic) => switch (systolic) {
  > 180 => _MeasurementRange.severelyElevated,
  >= 140 => _MeasurementRange.stage2,
  >= 130 => _MeasurementRange.stage1,
  >= 120 => _MeasurementRange.elevated,
  < 90 => _MeasurementRange.lowerThanUsual,
  _ => _MeasurementRange.normal,
};

_MeasurementRange _rangeForDiastolic(int diastolic) => switch (diastolic) {
  > 120 => _MeasurementRange.severelyElevated,
  >= 90 => _MeasurementRange.stage2,
  >= 80 => _MeasurementRange.stage1,
  < 60 => _MeasurementRange.lowerThanUsual,
  _ => _MeasurementRange.normal,
};
