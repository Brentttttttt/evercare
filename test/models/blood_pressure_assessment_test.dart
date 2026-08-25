import 'package:evercare/models/blood_pressure_assessment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BloodPressureAssessment assess(int systolic, int diastolic) =>
      BloodPressureAssessment.fromValues(
        systolic: systolic,
        diastolic: diastolic,
        pulse: 72,
      );

  test('uses the adult normal and elevated category boundaries', () {
    expect(assess(119, 79).category, BloodPressureCategory.normal);
    expect(assess(120, 79).category, BloodPressureCategory.elevated);
    expect(assess(129, 79).category, BloodPressureCategory.elevated);
  });

  test('uses either systolic or diastolic for high-category boundaries', () {
    expect(assess(130, 79).category, BloodPressureCategory.hypertensionStage1);
    expect(assess(119, 80).category, BloodPressureCategory.hypertensionStage1);
    expect(assess(140, 70).category, BloodPressureCategory.hypertensionStage2);
    expect(assess(120, 90).category, BloodPressureCategory.hypertensionStage2);
  });

  test('keeps the existing internal category IDs unchanged', () {
    expect(assess(89, 70).categoryId, 'lower_than_usual');
    expect(assess(118, 75).categoryId, 'normal');
    expect(assess(125, 75).categoryId, 'elevated');
    expect(assess(135, 85).categoryId, 'hypertension_stage_1');
    expect(assess(145, 78).categoryId, 'hypertension_stage_2');
    expect(assess(181, 80).categoryId, 'severe_hypertension');
  });

  test('flags readings above 180/120 for urgent follow-up', () {
    final assessment = assess(181, 80);

    expect(assessment.category, BloodPressureCategory.severeHypertension);
    expect(assessment.label, 'Severely elevated blood pressure reading');
    expect(assessment.shortLabel, 'Severely Elevated');
    expect(assessment.friendlyStatus, 'This reading needs urgent attention');
    expect(assessment.friendlyCompactLabel, 'Urgent Attention');
    expect(assessment.friendlySupportingText, contains('urgent attention'));
    expect(assessment.needsUrgentFollowUp, isTrue);
    expect(assessment.nextStep, contains('local emergency services'));
    expect(assessment.nextStep, contains('remains above 180'));
    expect(assessment.nextStep, contains('remains above 120'));
  });

  test('does not label an unexpectedly low result as normal', () {
    final assessment = assess(89, 59);

    expect(assessment.category, BloodPressureCategory.lowerThanUsual);
    expect(assessment.label, 'Lower-than-usual blood pressure reading');
    expect(assessment.friendlyStatus, 'This reading is lower than usual');
    expect(assessment.friendlyCompactLabel, 'Lower Reading');
    expect(assessment.nextStep, contains('faint'));
  });

  group('uses friendly and medical wording for the required examples', () {
    final examples =
        <(int, int, BloodPressureCategory, String, String, String, String)>[
          (
            118,
            75,
            BloodPressureCategory.normal,
            'Your reading looks good',
            'Looking Good',
            'Normal blood pressure range',
            'Normal Range',
          ),
          (
            125,
            75,
            BloodPressureCategory.elevated,
            'Your reading is slightly raised',
            'Slightly Raised',
            'Elevated blood pressure range',
            'Elevated Range',
          ),
          (
            135,
            85,
            BloodPressureCategory.hypertensionStage1,
            'Your reading is higher than recommended',
            'Above Recommended',
            'Stage 1 blood pressure range',
            'Stage 1 Range',
          ),
          (
            118,
            95,
            BloodPressureCategory.hypertensionStage2,
            'This reading needs some attention',
            'Needs Attention',
            'Stage 2 blood pressure range',
            'Stage 2 Range',
          ),
          (
            145,
            78,
            BloodPressureCategory.hypertensionStage2,
            'This reading needs some attention',
            'Needs Attention',
            'Stage 2 blood pressure range',
            'Stage 2 Range',
          ),
        ];

    for (final example in examples) {
      test('${example.$1}/${example.$2}', () {
        final assessment = assess(example.$1, example.$2);

        expect(assessment.category, example.$3);
        expect(assessment.friendlyStatus, example.$4);
        expect(assessment.friendlyCompactLabel, example.$5);
        expect(assessment.label, example.$6);
        expect(assessment.shortLabel, example.$7);
      });
    }
  });

  test('provides calm supporting text and a short action for each range', () {
    expect(
      assess(118, 75).friendlySupportingText,
      'Your blood pressure reading is within the normal range.',
    );
    expect(
      assess(118, 75).shortNextAction,
      'Keep tracking your readings over time.',
    );

    expect(
      assess(125, 75).friendlySupportingText,
      contains('a little higher than the normal range'),
    );
    expect(assess(125, 75).shortNextAction, contains('check again'));

    expect(
      assess(135, 85).friendlySupportingText,
      contains('A single reading does not diagnose high blood pressure.'),
    );
    expect(assess(135, 85).shortNextAction, contains('Rest for a few minutes'));

    expect(
      assess(145, 78).friendlySupportingText,
      contains('One reading alone does not diagnose high blood pressure.'),
    );
    expect(
      assess(145, 78).shortNextAction,
      contains('Rest for at least 5 minutes'),
    );
    expect(assess(145, 78).nextStep, assess(145, 78).shortNextAction);
  });

  test('explains when the diastolic value causes the Stage 2 range', () {
    final assessment = assess(118, 95);
    final explanation = assessment.upperLowerExplanation;

    expect(assessment.systolicRangeLabel, 'Normal range');
    expect(assessment.diastolicRangeLabel, 'Stage 2 range');
    expect(assessment.systolicSetsDisplayedRange, isFalse);
    expect(assessment.diastolicSetsDisplayedRange, isTrue);

    expect(
      explanation,
      contains(
        'upper number (systolic) is 118 mmHg, which is within the normal range',
      ),
    );
    expect(
      explanation,
      contains(
        'lower number (diastolic) is 95 mmHg, which falls within the Stage 2 range',
      ),
    );
    expect(
      explanation,
      contains('use whichever value falls into the higher category'),
    );
    expect(
      explanation,
      contains(
        'lower number (diastolic) determines the Stage 2 range for this measurement',
      ),
    );
    expect(
      explanation,
      isNot(
        contains('systolic) is 118 mmHg, which is within the Stage 2 range'),
      ),
    );
  });

  test('explains when the systolic value causes the Stage 2 range', () {
    final assessment = assess(145, 78);
    final explanation = assessment.upperLowerExplanation;

    expect(assessment.systolicRangeLabel, 'Stage 2 range');
    expect(assessment.diastolicRangeLabel, 'Normal range');
    expect(assessment.systolicSetsDisplayedRange, isTrue);
    expect(assessment.diastolicSetsDisplayedRange, isFalse);

    expect(
      explanation,
      contains(
        'upper number (systolic) is 145 mmHg, which is within the Stage 2 range',
      ),
    );
    expect(
      explanation,
      contains(
        'lower number (diastolic) is 78 mmHg, which falls within the normal range',
      ),
    );
    expect(
      explanation,
      contains('use whichever value falls into the higher category'),
    );
    expect(
      explanation,
      contains(
        'upper number (systolic) determines the Stage 2 range for this measurement',
      ),
    );
    expect(
      explanation,
      isNot(
        contains('diastolic) is 78 mmHg, which falls within the Stage 2 range'),
      ),
    );
  });

  test('explains both values in elderly-friendly language', () {
    final assessment = assess(135, 85);
    final explanation = assessment.upperLowerExplanation;

    expect(explanation, contains('upper number (systolic)'));
    expect(explanation, contains('lower number (diastolic)'));
    expect(explanation, contains('Both values are within the Stage 1 range'));
    expect(
      assessment.rangeExplanation,
      startsWith(assessment.friendlySupportingText),
    );
    expect(assessment.systolicSetsDisplayedRange, isTrue);
    expect(assessment.diastolicSetsDisplayedRange, isTrue);
  });

  test('provides the exact short disclaimer and optional additional info', () {
    expect(
      BloodPressureAssessment.shortDisclaimer,
      'This result describes this reading only and is not a medical diagnosis.',
    );
    expect(
      BloodPressureAssessment.measurementOnlyDisclaimer,
      BloodPressureAssessment.shortDisclaimer,
    );
    expect(
      BloodPressureAssessment.additionalDisclaimerInfo,
      'Blood pressure can change throughout the day. Repeated measurements '
      'and evaluation by a qualified healthcare professional are used when '
      'assessing high blood pressure.',
    );
  });

  test('never phrases a measurement range as a personal diagnosis', () {
    final examples = [
      assess(118, 75),
      assess(125, 75),
      assess(135, 85),
      assess(118, 95),
      assess(145, 78),
      assess(181, 121),
    ];
    final forbiddenDiagnosisClaims = RegExp(
      r'you have (?:high blood pressure|hypertension|stage [12])|'
      r'you are hypertensive|diagnosed with high blood pressure',
      caseSensitive: false,
    );

    for (final assessment in examples) {
      final visibleWording = [
        assessment.label,
        assessment.shortLabel,
        assessment.friendlyStatus,
        assessment.friendlyCompactLabel,
        assessment.friendlySupportingText,
        assessment.upperLowerExplanation,
        assessment.rangeExplanation,
        assessment.nextStep,
        BloodPressureAssessment.measurementOnlyDisclaimer,
        BloodPressureAssessment.additionalDisclaimerInfo,
      ].join(' ');

      expect(visibleWording, isNot(matches(forbiddenDiagnosisClaims)));
      expect(
        visibleWording,
        isNot(
          matches(
            RegExp(
              r'\bwarning\b|\bdanger\b|critical condition',
              caseSensitive: false,
            ),
          ),
        ),
      );
    }
  });
}
