import 'dart:async';

import 'package:evercare/models/blood_pressure_assessment.dart';
import 'package:evercare/models/bp_monitor_result.dart';
import 'package:evercare/models/evercare_ai.dart';
import 'package:evercare/screens/health/health_bp_ai_chat_sheet.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:evercare/widgets/evercare_ai_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  BpMonitorResult result({
    int rawSystolic = 128,
    int systolic = 118,
    int diastolic = 95,
    int pulse = 75,
  }) => BpMonitorResult(
    rawSystolic: rawSystolic,
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse,
    receivedAt: DateTime(2026, 8, 25, 12, 30),
    rawBytes: const [0x81, 0x80, 0x5F, 0x4B],
    rawHex: '81 80 5F 4B',
    metadataBytes: const [],
    packetIndex: 1,
    decoderVersion: 'test',
    validationStatus: 'test',
    deviceIdentifier: 'private-device-id',
    deviceName: 'Test monitor',
  );

  BloodPressureAssessment assessmentFor(BpMonitorResult reading) =>
      BloodPressureAssessment.fromValues(
        systolic: reading.systolic,
        diastolic: reading.diastolic,
        pulse: reading.pulse,
      );

  HealthBpChatResponse responseFor(
    BpMonitorResult reading, {
    required HealthBpChatResponseStatus status,
    required String answer,
  }) {
    final assessment = assessmentFor(reading);
    return HealthBpChatResponse(
      status: status,
      answer: answer,
      systolic: reading.systolic,
      diastolic: reading.diastolic,
      pulse: reading.pulse,
      category: assessment.categoryId,
      urgentGuidance:
          assessment.category == BloodPressureCategory.severeHypertension
          ? assessment.nextStep
          : null,
      disclaimer: healthBpChatDisclaimer,
    );
  }

  Future<void> pumpChat(
    WidgetTester tester,
    HealthBpAiRequest request, {
    BpMonitorResult? reading,
    Size size = const Size(390, 844),
    double textScaleFactor = 1,
  }) async {
    final selectedReading = reading ?? result();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
          child: child!,
        ),
        home: Scaffold(
          body: HealthBpAiChatSheet(
            result: selectedReading,
            assessment: assessmentFor(selectedReading),
            requestAiResponse: request,
          ),
        ),
      ),
    );
  }

  Finder mascotInside(Key key) => find.descendant(
    of: find.byKey(key),
    matching: find.byKey(evercareAiMascotKey),
  );

  testWidgets('shows the corrected reading, range, and friendly mascot', (
    tester,
  ) async {
    await pumpChat(
      tester,
      ({required message, required result}) async => responseFor(
        result,
        status: HealthBpChatResponseStatus.answered,
        answer: 'Helpful reply.',
      ),
    );

    expect(find.byKey(healthBpAiChatSheetKey), findsOneWidget);
    expect(find.textContaining('118/95 mmHg'), findsWidgets);
    expect(find.text('Stage 2 blood pressure range'), findsOneWidget);
    expect(find.byKey(healthBpAiChatHeaderMascotKey), findsOneWidget);
    expect(mascotInside(healthBpAiChatHeaderMascotKey), findsOneWidget);
    expect(find.byKey(healthBpAiChatAssistantMascotKey), findsOneWidget);
    expect(find.textContaining('Hello! I’m here to help'), findsOneWidget);
    expect(find.textContaining('not a medical diagnosis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('submits a natural custom question from the keyboard', (
    tester,
  ) async {
    String? requestedMessage;
    BpMonitorResult? requestedResult;
    await pumpChat(tester, ({required message, required result}) async {
      requestedMessage = message;
      requestedResult = result;
      return responseFor(
        result,
        status: HealthBpChatResponseStatus.answered,
        answer:
            'Your lower number set the range for this measurement. One reading is not a diagnosis.',
      );
    });

    const question = 'Why is my lower number important?';
    await tester.enterText(find.byKey(healthBpAiChatComposerKey), question);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(requestedMessage, question);
    expect(requestedResult?.systolic, 118);
    expect(requestedResult?.rawSystolic, 128);
    expect(find.text(question), findsOneWidget);
    expect(find.textContaining('lower number set the range'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a friendly off-topic redirect instead of silence', (
    tester,
  ) async {
    await pumpChat(
      tester,
      ({required message, required result}) async => responseFor(
        result,
        status: HealthBpChatResponseStatus.offTopic,
        answer:
            'That topic is outside this reading chat, but I can still help explain your blood-pressure numbers.',
      ),
    );

    await tester.enterText(
      find.byKey(healthBpAiChatComposerKey),
      'Who won the basketball game?',
    );
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Who won the basketball game?'), findsOneWidget);
    expect(find.textContaining('outside this reading chat'), findsOneWidget);
    expect(find.byKey(healthBpAiChatAssistantMascotKey), findsNWidgets(2));
  });

  testWidgets('shows the mascot while preparing a reply', (tester) async {
    final pending = Completer<HealthBpChatResponse>();
    await pumpChat(
      tester,
      ({required message, required result}) => pending.future,
    );

    await tester.enterText(
      find.byKey(healthBpAiChatComposerKey),
      'How should I check again?',
    );
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await tester.pump();

    expect(find.text('EverCare AI is thinking…'), findsOneWidget);
    expect(find.byKey(healthBpAiChatTypingMascotKey), findsOneWidget);
    expect(mascotInside(healthBpAiChatTypingMascotKey), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(healthBpAiChatComposerKey)).enabled,
      isFalse,
    );

    pending.complete(
      responseFor(
        result(),
        status: HealthBpChatResponseStatus.answered,
        answer: 'Rest for five minutes and keep your arm supported.',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Rest for five minutes'), findsOneWidget);
  });

  testWidgets('restores a question after a failed request', (tester) async {
    await pumpChat(tester, ({required message, required result}) async {
      throw Exception('offline');
    });

    const question = 'What does the upper number mean?';
    await tester.enterText(find.byKey(healthBpAiChatComposerKey), question);
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(healthBpAiChatComposerKey),
    );
    expect(composer.controller?.text, question);
    expect(composer.enabled, isTrue);
    expect(
      find.text("EverCare AI couldn't connect right now. Please try again."),
      findsOneWidget,
    );
  });

  testWidgets('quota failure is a retryable notice, not an assistant reply', (
    tester,
  ) async {
    var requests = 0;
    await pumpChat(tester, ({required message, required result}) async {
      requests++;
      if (requests == 1) {
        throw const FunctionException(
          status: 429,
          details: {'error': 'https://internal.invalid?key=private-key'},
        );
      }
      return responseFor(
        result,
        status: HealthBpChatResponseStatus.answered,
        answer: 'Here is the answer to your lifestyle question.',
      );
    });

    const question = 'How can I improve my blood pressure?';
    await tester.enterText(find.byKey(healthBpAiChatComposerKey), question);
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.textContaining('receiving a lot of requests'), findsOneWidget);
    expect(find.textContaining('private-key'), findsNothing);
    expect(find.byKey(healthBpAiChatAssistantMascotKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('health-bp-chat-message-1')),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text(question), findsOneWidget);
    expect(find.textContaining('receiving a lot of requests'), findsNothing);
    expect(
      find.textContaining('answer to your lifestyle question'),
      findsOneWidget,
    );
  });

  testWidgets('keeps urgent guidance above a severe-reading conversation', (
    tester,
  ) async {
    final severeReading = result(
      rawSystolic: 191,
      systolic: 181,
      diastolic: 121,
    );
    await pumpChat(
      tester,
      ({required message, required result}) async => responseFor(
        result,
        status: HealthBpChatResponseStatus.greeting,
        answer: 'Hello. Please follow the urgent guidance shown above.',
      ),
      reading: severeReading,
    );

    expect(find.text('Urgent guidance for this reading'), findsOneWidget);
    expect(find.textContaining('local emergency services'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.textContaining('Please also follow'), findsOneWidget);

    await tester.enterText(
      find.byKey(healthBpAiChatComposerKey),
      'What should I do now?',
    );
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Urgent guidance still applies'), findsOneWidget);
    expect(find.textContaining('local emergency services'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits large text with the keyboard open', (tester) async {
    addTearDown(tester.view.resetViewInsets);
    await pumpChat(
      tester,
      ({required message, required result}) async => responseFor(
        result,
        status: HealthBpChatResponseStatus.answered,
        answer: 'Helpful reply.',
      ),
      size: const Size(320, 700),
      textScaleFactor: 2,
    );

    final composer = find.byKey(healthBpAiChatComposerKey);
    await tester.showKeyboard(composer);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();

    final composerRect = tester.getRect(composer);
    expect(composerRect.left, greaterThanOrEqualTo(0));
    expect(composerRect.right, lessThanOrEqualTo(320));
    expect(composerRect.bottom, lessThanOrEqualTo(460));
    expect(find.byKey(healthBpAiChatHeaderMascotKey), findsOneWidget);
    expect(find.byKey(healthBpAiChatSafetyButtonKey), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });
}
