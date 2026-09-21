import 'dart:async';

import 'package:evercare/data/care_book_data.dart';
import 'package:evercare/models/evercare_ai.dart';
import 'package:evercare/screens/care_book/care_book_ai_chat_sheet.dart';
import 'package:evercare/theme/app_theme.dart';
import 'package:evercare/widgets/bp_level_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Future<void> pumpChat(
    WidgetTester tester,
    CareBookAiRequest request, {
    Size size = const Size(390, 844),
    double textScaleFactor = 1,
  }) async {
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
          body: CareBookAiChatSheet(
            selectedChapter: CareBookData.chapters.first,
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

  Future<void> pumpLauncher(
    WidgetTester tester, {
    required VoidCallback onTap,
    bool disableAnimations = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: Scaffold(
          body: Center(child: CareBookAiLauncher(onTap: onTap)),
        ),
      ),
    );
  }

  testWidgets('launcher hint and mascot hover together and stay tappable', (
    tester,
  ) async {
    var taps = 0;
    await pumpLauncher(tester, onTap: () => taps++);
    await tester.pump();

    final label = find.byKey(careBookAiLauncherLabelKey);
    final button = find.byKey(careBookAiLauncherButtonKey);
    final launcher = find.byKey(careBookAiLauncherKey);
    final restingLabelRect = tester.getRect(label);
    final restingRect = tester.getRect(button);
    final restingLauncherRect = tester.getRect(launcher);
    await tester.pump(const Duration(milliseconds: 600));
    final hoveringLabelRect = tester.getRect(label);
    final hoveringRect = tester.getRect(button);
    final hoveringLauncherRect = tester.getRect(launcher);

    final labelDelta = hoveringLabelRect.top - restingLabelRect.top;
    final buttonDelta = hoveringRect.top - restingRect.top;
    final launcherDelta = hoveringLauncherRect.top - restingLauncherRect.top;

    expect(restingRect.size, const Size.square(70));
    expect(hoveringRect.size, const Size.square(70));
    expect(restingRect.top - hoveringRect.top, inInclusiveRange(.5, 4.1));
    expect(labelDelta, closeTo(buttonDelta, .001));
    expect(launcherDelta, closeTo(buttonDelta, .001));
    expect(
      hoveringRect.left - hoveringLabelRect.right,
      closeTo(restingRect.left - restingLabelRect.right, .001),
    );

    await tester.tapAt(hoveringRect.center);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('launcher hover respects reduced-motion settings', (
    tester,
  ) async {
    await pumpLauncher(tester, onTap: () {}, disableAnimations: true);
    await tester.pump();

    final label = find.byKey(careBookAiLauncherLabelKey);
    final button = find.byKey(careBookAiLauncherButtonKey);
    final launcher = find.byKey(careBookAiLauncherKey);
    final beforeLabel = tester.getRect(label);
    final beforeButton = tester.getRect(button);
    final beforeLauncher = tester.getRect(launcher);
    await tester.pump(const Duration(seconds: 3));
    final afterLabel = tester.getRect(label);
    final afterButton = tester.getRect(button);
    final afterLauncher = tester.getRect(launcher);

    expect(afterLabel, beforeLabel);
    expect(afterButton, beforeButton);
    expect(afterLauncher, beforeLauncher);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the mascot in the header and assistant greeting', (
    tester,
  ) async {
    await pumpChat(
      tester,
      ({required message, required selectedChapter}) async =>
          const CareBookAiResponse(
            status: CareBookAiResponseStatus.ignored,
            answer: '',
            sourceChapters: [],
          ),
    );

    expect(find.byKey(careBookAiSheetKey), findsOneWidget);
    expect(find.byKey(careBookAiHeaderMascotKey), findsOneWidget);
    expect(mascotInside(careBookAiHeaderMascotKey), findsOneWidget);
    expect(find.byKey(careBookAiAssistantAvatarKey), findsOneWidget);
    expect(mascotInside(careBookAiAssistantAvatarKey), findsOneWidget);
    expect(find.byKey(careBookAiTypingAvatarKey), findsNothing);
    expect(find.text('Care Guide'), findsWidgets);

    await tester.tap(find.byKey(careBookAiSafetyButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('About Care Guide'), findsOneWidget);
    expect(
      find.textContaining('does not save this conversation to your account'),
      findsOneWidget,
    );
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('turns a legacy ignored response into a friendly redirect', (
    tester,
  ) async {
    await pumpChat(
      tester,
      ({required message, required selectedChapter}) async =>
          const CareBookAiResponse(
            status: CareBookAiResponseStatus.ignored,
            answer: '',
            sourceChapters: [],
          ),
    );

    await tester.enterText(find.byType(TextField), 'Write me a song');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Write me a song'), findsOneWidget);
    expect(find.text(careBookFriendlyScopeReply), findsOneWidget);
    expect(find.byKey(careBookAiAssistantAvatarKey), findsNWidgets(2));
    expect(find.textContaining('check your connection'), findsNothing);
  });

  testWidgets('shows a warm greeting without requiring a source chapter', (
    tester,
  ) async {
    await pumpChat(
      tester,
      ({
        required message,
        required selectedChapter,
      }) async => const CareBookAiResponse(
        status: CareBookAiResponseStatus.answered,
        answer:
            'Hello! It’s lovely to hear from you. How can I help with older-adult care today?',
        sourceChapters: [],
      ),
    );

    await tester.enterText(find.byKey(careBookAiComposerKey), 'Hello');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(
      find.text(
        'Hello! It’s lovely to hear from you. How can I help with older-adult care today?',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Care Book:'), findsNothing);
  });

  testWidgets('submits a natural custom question from the keyboard action', (
    tester,
  ) async {
    String? requestedMessage;
    await pumpChat(tester, ({
      required message,
      required selectedChapter,
    }) async {
      requestedMessage = message;
      return const CareBookAiResponse(
        status: CareBookAiResponseStatus.answered,
        answer: 'Use simple steps and preserve familiar routines.',
        sourceChapters: [1, 3],
      );
    });

    const question = 'How do I help grandma get ready in the morning?';
    await tester.enterText(find.byKey(careBookAiComposerKey), question);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(requestedMessage, question);
    expect(find.text(question), findsOneWidget);
    expect(
      find.text('Use simple steps and preserve familiar routines.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('adds a successful answer to the mutable conversation', (
    tester,
  ) async {
    await pumpChat(
      tester,
      ({required message, required selectedChapter}) async =>
          const CareBookAiResponse(
            status: CareBookAiResponseStatus.answered,
            answer: 'Keep the routine simple and write down each daily task.',
            sourceChapters: [1, 3],
          ),
    );

    await tester.enterText(
      find.byType(TextField),
      'How should I organize a daily routine?',
    );
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('How should I organize a daily routine?'), findsOneWidget);
    expect(
      find.text('Keep the routine simple and write down each daily task.'),
      findsOneWidget,
    );
    expect(find.text('Care Book: 1, 3'), findsOneWidget);
    expect(find.textContaining('check your connection'), findsNothing);
  });

  testWidgets('restores the question after a failed request for easy retry', (
    tester,
  ) async {
    await pumpChat(tester, ({
      required message,
      required selectedChapter,
    }) async {
      throw Exception('offline');
    });

    const question = 'How can I make the bedroom safer?';
    await tester.enterText(find.byKey(careBookAiComposerKey), question);
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(careBookAiComposerKey),
    );
    expect(composer.controller?.text, question);
    expect(composer.enabled, isTrue);
    final notice = find.text(
      "EverCare AI couldn't connect right now. Please try again.",
    );
    expect(notice, findsOneWidget);
    expect(tester.getRect(notice).top, greaterThanOrEqualTo(0));
    expect(
      tester.getRect(notice).bottom,
      lessThanOrEqualTo(tester.getRect(find.byKey(careBookAiComposerKey)).top),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('quota failures do not add a refusal to the conversation', (
    tester,
  ) async {
    await pumpChat(tester, ({
      required message,
      required selectedChapter,
    }) async {
      throw const FunctionException(
        status: 429,
        details: {'error': 'GEMINI_API_KEY=private-key'},
      );
    });

    const question = 'Could coffee affect blood pressure?';
    await tester.enterText(find.byKey(careBookAiComposerKey), question);
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.textContaining('receiving a lot of requests'), findsOneWidget);
    expect(find.textContaining('private-key'), findsNothing);
    expect(find.byKey(careBookAiAssistantAvatarKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('care-book-ai-message-1')),
      findsNothing,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(careBookAiComposerKey))
          .controller
          ?.text,
      question,
    );
  });

  testWidgets('shows a mascot while thinking and beside the completed reply', (
    tester,
  ) async {
    final response = Completer<CareBookAiResponse>();
    await pumpChat(
      tester,
      ({required message, required selectedChapter}) => response.future,
    );

    await tester.enterText(
      find.byKey(careBookAiComposerKey),
      'How can I prepare for a medical visit?',
    );
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Care Guide is thinking…'), findsOneWidget);
    expect(find.byKey(careBookAiTypingAvatarKey), findsOneWidget);
    expect(mascotInside(careBookAiTypingAvatarKey), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(careBookAiComposerKey)).enabled,
      isFalse,
    );
    expect(
      tester.getRect(find.text('Care Guide is thinking…')).bottom,
      lessThanOrEqualTo(tester.getRect(find.byKey(careBookAiComposerKey)).top),
    );
    expect(tester.takeException(), isNull);

    response.complete(
      const CareBookAiResponse(
        status: CareBookAiResponseStatus.answered,
        answer: 'Write down symptoms, medicines, and your questions.',
        sourceChapters: [1, 3],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(careBookAiTypingAvatarKey), findsNothing);
    expect(find.text('Care Guide is thinking…'), findsNothing);
    expect(
      tester.widget<TextField>(find.byKey(careBookAiComposerKey)).enabled,
      isTrue,
    );
    expect(find.text('How can I prepare for a medical visit?'), findsOneWidget);
    expect(
      find.text('Write down symptoms, medicines, and your questions.'),
      findsOneWidget,
    );
    expect(find.text('Care Book: 1, 3'), findsOneWidget);

    const replyKey = ValueKey<String>('care-book-ai-message-2');
    expect(find.byKey(replyKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(replyKey),
        matching: find.byKey(careBookAiAssistantAvatarKey),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(replyKey),
        matching: find.byKey(evercareAiMascotKey),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the composer usable with large text and keyboard inset', (
    tester,
  ) async {
    addTearDown(tester.view.resetViewInsets);
    await pumpChat(
      tester,
      ({required message, required selectedChapter}) async =>
          const CareBookAiResponse(
            status: CareBookAiResponseStatus.ignored,
            answer: '',
            sourceChapters: [],
          ),
      size: const Size(320, 700),
      textScaleFactor: 2,
    );

    final composer = find.byKey(careBookAiComposerKey);
    await tester.showKeyboard(composer);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();

    final composerRect = tester.getRect(composer);
    expect(composerRect.left, greaterThanOrEqualTo(0));
    expect(composerRect.right, lessThanOrEqualTo(320));
    expect(composerRect.top, greaterThanOrEqualTo(0));
    expect(composerRect.bottom, lessThanOrEqualTo(460));
    expect(find.byKey(careBookAiHeaderMascotKey), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });
}
