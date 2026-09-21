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
        {'role': 'user', 'content': 'Why is it Stage 2 range?'},
      ]);
      expect(body.values, isNot(contains(128)));
      expect(body.toString(), isNot(contains('private')));
    },
  );

  test('AI chat history retains the last 16 chronological messages', () {
    final turns = List<EverCareAiChatTurn>.generate(
      20,
      (index) => index.isEven
          ? EverCareAiChatTurn.user('user message $index')
          : EverCareAiChatTurn.assistant('assistant message $index'),
    );

    final history = everCareAiHistoryPayload(turns);

    expect(history, hasLength(16));
    expect(history.first['content'], 'user message 4');
    expect(history.last['content'], 'assistant message 19');
    expect(
      history.map((item) => item.keys.toSet()),
      everyElement({'role', 'content'}),
    );
  });

  test('history preserves full assistant answers beyond 600 characters', () {
    final answer = '${'A' * 1600} This qualification must remain intact.';
    final history = everCareAiHistoryPayload([
      const EverCareAiChatTurn.assistant('Welcome to the reading chat.'),
      const EverCareAiChatTurn.user('Could coffee affect it?'),
      EverCareAiChatTurn.assistant(answer),
      const EverCareAiChatTurn.user('I had two cups earlier.'),
      const EverCareAiChatTurn.assistant('That context helps.'),
    ]);

    expect(history, hasLength(4));
    expect(history.first['role'], 'user');
    expect(history[1]['content'], answer);
    expect(history[2]['content'], 'I had two cups earlier.');
  });

  test('character budget drops whole old exchanges without cutting text', () {
    final turns = <EverCareAiChatTurn>[];
    for (var index = 0; index < 8; index++) {
      turns.add(EverCareAiChatTurn.user('$index${'U' * 599}'));
      turns.add(EverCareAiChatTurn.assistant('$index${'A' * 2399}'));
    }

    final history = everCareAiHistoryPayload(turns);

    expect(history, hasLength(10));
    expect(history.first['content'], startsWith('3'));
    expect(history.first['role'], 'user');
    expect(history.last['role'], 'assistant');
    expect(
      history.fold<int>(0, (total, item) => total + item['content']!.length),
      15000,
    );
    expect(
      history.where((item) => item['role'] == 'assistant'),
      everyElement(containsPair('content', hasLength(2400))),
    );
  });

  test('message budget never leaves an orphaned assistant answer', () {
    final history = everCareAiHistoryPayload(
      List.generate(
        19,
        (index) => index.isEven
            ? EverCareAiChatTurn.user('question $index')
            : EverCareAiChatTurn.assistant('answer $index'),
      ),
    );

    expect(history, hasLength(15));
    expect(history.first, {'role': 'user', 'content': 'question 4'});
    expect(history.last, {'role': 'user', 'content': 'question 18'});
  });

  test('oversized exchanges are omitted without rewriting their meaning', () {
    final history = everCareAiHistoryPayload([
      const EverCareAiChatTurn.user('Older question'),
      const EverCareAiChatTurn.assistant('Older answer'),
      EverCareAiChatTurn.user('U' * 601),
      const EverCareAiChatTurn.assistant('Answer to oversized question'),
      const EverCareAiChatTurn.user('Another question'),
      EverCareAiChatTurn.assistant('A' * 2401),
      const EverCareAiChatTurn.user('  Recent question  '),
      const EverCareAiChatTurn.assistant('  Recent answer  '),
    ]);

    expect(history, [
      {'role': 'user', 'content': 'Recent question'},
      {'role': 'assistant', 'content': 'Recent answer'},
    ]);
  });

  test('empty messages and UI-only greetings are not provider history', () {
    expect(
      everCareAiHistoryPayload(const [
        EverCareAiChatTurn.assistant('Welcome!'),
        EverCareAiChatTurn.user('   '),
        EverCareAiChatTurn.assistant('  '),
      ]),
      isEmpty,
    );
  });

  test(
    'latest question appears once alongside the complete prior exchange',
    () {
      const latest = 'How long should I wait before checking again?';
      const turns = [
        EverCareAiChatTurn.user('Could coffee affect it?'),
        EverCareAiChatTurn.assistant(
          'Caffeine can affect a reading temporarily.',
        ),
        EverCareAiChatTurn.user('I had two cups earlier.'),
        EverCareAiChatTurn.assistant(
          'Keep that in mind when comparing readings.',
        ),
      ];
      final body = careBookAiRequestBody(
        message: latest,
        selectedChapter: 8,
        history: turns,
      );

      expect(body['message'], latest);
      expect(body['history'], [
        for (final turn in turns)
          {
            'role': turn.role == EverCareAiChatRole.user ? 'user' : 'assistant',
            'content': turn.content,
          },
      ]);
      expect(body['history'].toString(), isNot(contains(latest)));
    },
  );

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
    test('daily quota has a reset message without exposing provider details', () {
      const error = FunctionException(
        status: 429,
        details: {
          'code': 'AI_DAILY_QUOTA',
          'error': 'Gemini key=private-secret at https://internal.invalid',
        },
      );

      expect(
        everCareAiFailureMessage(error, connectionFallback: 'offline'),
        'EverCare AI has reached its daily free limit. Please try again after the daily reset.',
      );
    });

    test('tap cooldown asks for seconds rather than a daily reset', () {
      const error = FunctionException(
        status: 429,
        details: {
          'code': 'AI_COOLDOWN',
          'error': 'Internal request identifier: private-id',
        },
      );

      expect(
        everCareAiFailureMessage(error, connectionFallback: 'offline'),
        'Please wait a few seconds before asking EverCare AI again.',
      );
    });

    test('unrecognized quota details retain the safe generic message', () {
      for (final details in [
        null,
        'AI_DAILY_QUOTA',
        {'code': 'AI_UNKNOWN_QUOTA'},
        {'code': 'AI_DAILY_QUOTA https://internal.invalid?key=private-secret'},
        {'code': 429},
        {
          'code': ['AI_DAILY_QUOTA'],
        },
        {'error': 'AI_DAILY_QUOTA'},
        {'code': 'AI_DAILY_QUOTA', 'error': 'private-secret'}.toString(),
      ]) {
        expect(
          everCareAiFailureMessage(
            FunctionException(status: 429, details: details),
            connectionFallback: 'offline',
          ),
          'EverCare AI is receiving a lot of requests right now. Please try again in a moment.',
        );
      }
    });

    test('quota codes only apply to HTTP 429 responses', () {
      const expectedByStatus = {
        400: 'Please check your question and try again.',
        401: 'Your sign-in session has expired. Please sign in again.',
        403: 'Your sign-in session has expired. Please sign in again.',
        413: 'Please shorten your question and try again.',
        503: "EverCare AI couldn't connect right now. Please try again.",
      };
      for (final code in ['AI_DAILY_QUOTA', 'AI_COOLDOWN']) {
        for (final entry in expectedByStatus.entries) {
          expect(
            everCareAiFailureMessage(
              FunctionException(status: entry.key, details: {'code': code}),
              connectionFallback: 'offline',
            ),
            entry.value,
          );
        }
      }
    });

    test('quota errors use a friendly service message, not server details', () {
      const error = FunctionException(
        status: 429,
        details: {'error': 'Please wait before asking again.'},
      );

      expect(
        everCareAiFailureMessage(error, connectionFallback: 'offline'),
        'EverCare AI is receiving a lot of requests right now. Please try again in a moment.',
      );
    });

    test('does not expose raw exception details, URLs, or credentials', () {
      for (final details in [
        {'error': 'Gemini key=private-secret at https://internal.invalid'},
        {'message': 'Stack trace: private-secret'},
        'GEMINI_API_KEY=private-secret',
      ]) {
        expect(
          everCareAiFailureMessage(
            FunctionException(status: 503, details: details),
            connectionFallback: 'offline',
          ),
          "EverCare AI couldn't connect right now. Please try again.",
        );
      }
    });

    test('server authentication failures keep a useful sign-in message', () {
      const error = FunctionException(
        status: 401,
        details: {'error': 'expired access token: private-token'},
      );

      expect(
        everCareAiFailureMessage(error, connectionFallback: 'offline'),
        'Your sign-in session has expired. Please sign in again.',
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
