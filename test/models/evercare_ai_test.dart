import 'package:evercare/models/evercare_ai.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthAiInsight.fromMap', () {
    test('parses the deterministic reading echoed by the server', () {
      final insight = HealthAiInsight.fromMap({
        'status': 'hypertension_stage_2',
        'systolic': 140,
        'diastolic': 102,
        'pulse': 73,
        'headline': 'This reading needs some attention',
        'rangeLabel': 'Stage 2 blood pressure range',
        'explanation':
            'This measurement falls within the Stage 2 blood pressure range.',
        'tips': ['Rest quietly.', 'Repeat the measurement.'],
        'nextStep': 'Contact a qualified health professional promptly.',
        'disclaimer':
            'This result describes this reading only and is not a medical diagnosis.',
        'disclaimerDetails':
            'Blood pressure can change throughout the day. Repeated measurements and evaluation by a qualified healthcare professional are used when assessing high blood pressure.',
      });

      expect(insight.systolic, 140);
      expect(insight.diastolic, 102);
      expect(insight.pulse, 73);
      expect(insight.status, 'hypertension_stage_2');
      expect(insight.headline, 'This reading needs some attention');
      expect(insight.rangeLabel, 'Stage 2 blood pressure range');
    });

    test('rejects a response without its deterministic reading', () {
      expect(
        () => HealthAiInsight.fromMap({
          'status': 'normal',
          'headline': 'Normal range',
          'rangeLabel': 'Normal blood pressure range',
          'explanation': 'Explanation',
          'tips': <String>[],
          'nextStep': 'Continue the care plan.',
          'disclaimer': 'Educational only.',
          'disclaimerDetails': 'Additional information.',
        }),
        throwsFormatException,
      );
    });
  });

  group('CareBookAiResponse.fromMap', () {
    test('accepts the intentional empty answer for an ignored message', () {
      final response = CareBookAiResponse.fromMap({
        'status': 'ignored',
        'answer': '',
        'sources': <int>[],
      });

      expect(response.status, CareBookAiResponseStatus.ignored);
      expect(response.answer, isEmpty);
      expect(response.sourceChapters, isEmpty);
    });

    test('continues to reject an empty answer for a rendered response', () {
      expect(
        () => CareBookAiResponse.fromMap({
          'status': 'answered',
          'answer': '',
          'sources': <int>[1],
        }),
        throwsFormatException,
      );
    });

    test('accepts a friendly answered reply without a chapter source', () {
      final response = CareBookAiResponse.fromMap({
        'status': 'answered',
        'answer': 'Hello! How can I help with older-adult care today?',
        'sources': <int>[],
      });

      expect(response.status, CareBookAiResponseStatus.answered);
      expect(response.answer, startsWith('Hello!'));
      expect(response.sourceChapters, isEmpty);
    });
  });

  group('HealthBpChatResponse.fromMap', () {
    Map<String, Object?> responseMap(String status) => {
      'status': status,
      'answer': 'A friendly, reading-specific reply.',
      'systolic': 118,
      'diastolic': 95,
      'pulse': 75,
      'category': 'hypertension_stage_2',
      'urgentGuidance': null,
      'disclaimer': healthBpChatDisclaimer,
    };

    test('parses every supported response status', () {
      expect(
        HealthBpChatResponse.fromMap(responseMap('answered')).status,
        HealthBpChatResponseStatus.answered,
      );
      expect(
        HealthBpChatResponse.fromMap(responseMap('greeting')).status,
        HealthBpChatResponseStatus.greeting,
      );
      expect(
        HealthBpChatResponse.fromMap(responseMap('off_topic')).status,
        HealthBpChatResponseStatus.offTopic,
      );
      expect(
        HealthBpChatResponse.fromMap(responseMap('medical_redirect')).status,
        HealthBpChatResponseStatus.medicalRedirect,
      );
      expect(
        HealthBpChatResponse.fromMap(responseMap('emergency_redirect')).status,
        HealthBpChatResponseStatus.emergencyRedirect,
      );
    });

    test('requires a non-empty answer even for an off-topic redirect', () {
      final map = responseMap('off_topic')..['answer'] = '';
      expect(() => HealthBpChatResponse.fromMap(map), throwsFormatException);
    });

    test('rejects an unknown status and missing echoed values', () {
      expect(
        () => HealthBpChatResponse.fromMap(responseMap('unknown')),
        throwsFormatException,
      );
      final missingReading = responseMap('answered')..remove('systolic');
      expect(
        () => HealthBpChatResponse.fromMap(missingReading),
        throwsFormatException,
      );
    });
  });
}
