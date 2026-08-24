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

  test('flags readings above 180/120 for urgent follow-up', () {
    final assessment = assess(181, 80);

    expect(assessment.category, BloodPressureCategory.severeHypertension);
    expect(assessment.needsUrgentFollowUp, isTrue);
    expect(assessment.nextStep, contains('local emergency services'));
  });

  test('does not label an unexpectedly low result as normal', () {
    expect(assess(89, 59).category, BloodPressureCategory.lowerThanUsual);
  });
}
