import 'package:evercare/models/bp_monitor_result.dart';
import 'package:evercare/models/evercare_ai.dart';
import 'package:evercare/services/evercare_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'BP chat payload contains only corrected display values and the question',
    () {
      final result = BpMonitorResult(
        rawSystolic: 128,
        systolic: 118,
        diastolic: 95,
        pulse: 75,
        receivedAt: DateTime(2026, 8, 25),
        rawBytes: const [0x81, 0x80, 0x5F, 0x4B],
        rawHex: '81 80 5F 4B',
        metadataBytes: const [0x99],
        packetIndex: 7,
        decoderVersion: 'private-decoder-data',
        validationStatus: 'private-validation-data',
        deviceIdentifier: 'private-device-id',
        deviceName: 'Private monitor name',
      );

      final body = healthBpChatRequestBody(
        result: result,
        message: 'Why is the lower number important?',
        history: const [
          EverCareAiChatTurn.assistant('I can explain this reading.'),
          EverCareAiChatTurn.user('Why is it Stage 2 range?'),
        ],
      );

      expect(body.keys.toSet(), {
        'message',
        'systolic',
        'diastolic',
        'pulse',
        'history',
      });
      expect(body['systolic'], 118);
      expect(body['history'], [
        {'role': 'assistant', 'content': 'I can explain this reading.'},
        {'role': 'user', 'content': 'Why is it Stage 2 range?'},
      ]);
      expect(body.values, isNot(contains(128)));
      expect(body.toString(), isNot(contains('private')));
    },
  );

  test('AI chat history keeps only a small recent context window', () {
    final turns = List<EverCareAiChatTurn>.generate(
      10,
      (index) => index.isEven
          ? EverCareAiChatTurn.user('user message $index')
          : EverCareAiChatTurn.assistant('assistant message $index'),
    );

    final history = everCareAiHistoryPayload(turns);

    expect(history, hasLength(8));
    expect(history.first['content'], 'user message 2');
    expect(history.last['content'], 'assistant message 9');
    expect(
      history.map((item) => item.keys.toSet()),
      everyElement({'role', 'content'}),
    );
  });

  test(
    'Care Book payload contains only its question, chapter, and history',
    () {
      final body = careBookAiRequestBody(
        message: 'What should I prepare for a clinic visit?',
        selectedChapter: 8,
        history: const [EverCareAiChatTurn.user('My grandfather has a visit.')],
      );

      expect(body.keys.toSet(), {'message', 'selectedChapter', 'history'});
      expect(body['selectedChapter'], 8);
      expect(body['history'], [
        {'role': 'user', 'content': 'My grandfather has a visit.'},
      ]);
    },
  );

  group('everCareAiFailureMessage', () {
    test('uses the server error returned by an Edge Function', () {
      const error = FunctionException(
        status: 429,
        details: {'error': 'Please wait before asking again.'},
      );

      expect(
        everCareAiFailureMessage(error, connectionFallback: 'offline'),
        'Please wait before asking again.',
      );
    });

    test('uses a connection hint only for non-function failures', () {
      expect(
        everCareAiFailureMessage(
          Exception('socket failed'),
          connectionFallback: 'Check your connection and try again.',
        ),
        'Check your connection and try again.',
      );
    });

    test('identifies an expired authentication session', () {
      const error = AuthException('refresh failed', statusCode: '401');

      expect(
        everCareAiFailureMessage(error, connectionFallback: 'offline'),
        'Your sign-in session has expired. Please sign in again.',
      );
    });

    test('does not describe malformed AI output as a connection problem', () {
      const error = FormatException('invalid response');

      expect(
        everCareAiFailureMessage(error, connectionFallback: 'offline'),
        'EverCare AI returned an invalid response. Please try again.',
      );
    });
  });
}
