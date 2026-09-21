import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/care_book_chapter.dart';
import '../../models/evercare_ai.dart';
import '../../services/evercare_ai_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_ai_mascot.dart';
import '../../widgets/evercare_backend_scope.dart';

typedef CareBookAiRequest =
    Future<CareBookAiResponse> Function({
      required String message,
      required int selectedChapter,
    });

const careBookAiLauncherKey = ValueKey<String>('care-book-ai-launcher');
const careBookAiLauncherLabelKey = ValueKey<String>(
  'care-book-ai-launcher-label',
);
const careBookAiLauncherButtonKey = ValueKey<String>(
  'care-book-ai-launcher-button',
);
const careBookAiSheetKey = ValueKey<String>('care-book-ai-sheet');
const careBookAiHeaderMascotKey = ValueKey<String>(
  'care-book-ai-header-mascot',
);
const careBookAiAssistantAvatarKey = ValueKey<String>(
  'care-book-ai-assistant-avatar',
);
const careBookAiTypingAvatarKey = ValueKey<String>(
  'care-book-ai-typing-avatar',
);
const careBookAiComposerKey = ValueKey<String>('care-book-ai-composer');
const careBookAiSafetyButtonKey = ValueKey<String>(
  'care-book-ai-safety-button',
);
const careBookFriendlyScopeReply =
    'That topic is outside what I’m here for, but I’m still happy to help. You can ask me about older-adult health and daily care, routines, meals and hydration, medicine reminders, appointments, home safety, emotional support, or caregiver wellbeing.';

class CareBookAiLauncher extends StatelessWidget {
  const CareBookAiLauncher({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return _CareBookLauncherMotion(
      child: Row(
        key: careBookAiLauncherKey,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            key: careBookAiLauncherLabelKey,
            constraints: BoxConstraints(maxWidth: largeText ? 154 : 176),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xF7FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: .18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGreen.withValues(alpha: .11),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help while reading?',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ask Care Guide',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Tooltip(
            message: 'Open Care Guide AI chat',
            child: Semantics(
              button: true,
              label: 'Open Care Guide AI chat',
              child: PressScale(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkGreen.withValues(alpha: .2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    key: careBookAiLauncherButtonKey,
                    color: Colors.white,
                    shape: CircleBorder(
                      side: BorderSide(
                        color: AppColors.primaryGreen.withValues(alpha: .32),
                        width: 1.4,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onTap,
                      customBorder: const CircleBorder(),
                      child: const SizedBox.square(
                        dimension: 70,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Center(child: AiMascotAvatar(size: 64)),
                            Positioned(
                              right: -1,
                              bottom: 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(
                                    BorderSide(color: Colors.white, width: 2),
                                  ),
                                ),
                                child: SizedBox.square(
                                  dimension: 23,
                                  child: Icon(
                                    Icons.chat_bubble_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareBookLauncherMotion extends StatefulWidget {
  const _CareBookLauncherMotion({required this.child});

  final Widget child;

  @override
  State<_CareBookLauncherMotion> createState() =>
      _CareBookLauncherMotionState();
}

class _CareBookLauncherMotionState extends State<_CareBookLauncherMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _verticalOffset;
  Timer? _nextCycle;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addStatusListener(_handleStatus);
    _verticalOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -4,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -4,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    _nextCycle?.cancel();
    _controller.stop();
    _controller.value = 0;
    if (!reduceMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startCycle());
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || (_reduceMotion ?? true)) return;
    _nextCycle?.cancel();
    _nextCycle = Timer(const Duration(milliseconds: 900), _startCycle);
  }

  void _startCycle() {
    if (!mounted || (_reduceMotion ?? true) || _controller.isAnimating) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _nextCycle?.cancel();
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _verticalOffset,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _verticalOffset.value),
          child: child,
        ),
      ),
    );
  }
}

class _CareGuideHeaderMascot extends StatelessWidget {
  const _CareGuideHeaderMascot({required this.size, required this.avatarKey});

  final double size;
  final Key avatarKey;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: avatarKey,
      child: AiMascotAvatar(size: size),
    );
  }
}

class _CareGuideIdentity extends StatelessWidget {
  const _CareGuideIdentity();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'EverCare AI',
          style: AppTextStyles.eyebrow.copyWith(
            color: AppColors.purple,
            letterSpacing: .55,
          ),
        ),
      ],
    );
  }
}

class _CareGuideTopicBanner extends StatelessWidget {
  const _CareGuideTopicBanner({required this.chapter});

  final CareBookChapter chapter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: .14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 19,
            color: AppColors.darkGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Current topic: ${chapter.number}. ${chapter.title}',
              style: AppTextStyles.small.copyWith(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CareBookAiChatSheet extends StatefulWidget {
  const CareBookAiChatSheet({
    required this.selectedChapter,
    this.requestAiResponse,
    super.key,
  });

  final CareBookChapter selectedChapter;
  final CareBookAiRequest? requestAiResponse;

  @override
  State<CareBookAiChatSheet> createState() => _CareBookAiChatSheetState();
}

class _CareBookAiChatSheetState extends State<CareBookAiChatSheet> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _conversationEndKey = GlobalKey();
  final List<CareBookChatMessage> _messages = [
    const CareBookChatMessage.assistant(
      'Hello! Ask me about older-adult health or daily care. I can help with routines, meals, safety, appointments, emotional support, caregiver wellbeing, and the Care Book.',
    ),
  ];
  bool _sending = false;
  String? _notice;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestedMessage]) async {
    final message = (suggestedMessage ?? _messageController.text).trim();
    if (message.isEmpty || _sending) return;

    final requestAiResponse = widget.requestAiResponse;
    final client = requestAiResponse == null
        ? EverCareBackendScope.maybeClient(context)
        : null;
    if (requestAiResponse == null && client?.auth.currentUser == null) {
      setState(() {
        _notice = 'Sign in to ask Care Guide. Your chat is not saved.';
      });
      _scrollToLatest();
      return;
    }

    final history = _messages
        .map(
          (item) => item.isUser
              ? EverCareAiChatTurn.user(item.text)
              : EverCareAiChatTurn.assistant(item.text),
        )
        .toList(growable: false);
    _messageController.clear();
    setState(() {
      _messages.add(CareBookChatMessage.user(message));
      _sending = true;
      _notice = null;
    });
    _scrollToLatest();
    try {
      final response = requestAiResponse != null
          ? await requestAiResponse(
              message: message,
              selectedChapter: widget.selectedChapter.number,
            )
          : await EverCareAiService(client!).askCareBook(
              message: message,
              selectedChapter: widget.selectedChapter.number,
              history: history,
            );
      if (!mounted) return;
      final usedLegacyFallback =
          response.status == CareBookAiResponseStatus.ignored;
      setState(() {
        _messages.add(
          CareBookChatMessage.assistant(
            usedLegacyFallback ? careBookFriendlyScopeReply : response.answer,
            sourceChapters: usedLegacyFallback
                ? const []
                : response.sourceChapters,
          ),
        );
      });
      _scrollToLatest();
    } catch (error) {
      if (!mounted) return;
      _messageController.value = TextEditingValue(
        text: message,
        selection: TextSelection.collapsed(offset: message.length),
      );
      setState(() {
        if (_messages.isNotEmpty) {
          final lastMessage = _messages.last;
          if (lastMessage.isUser && lastMessage.text == message) {
            _messages.removeLast();
          }
        }
        _notice = everCareAiFailureMessage(
          error,
          connectionFallback:
              "EverCare AI couldn't connect right now. Please try again.",
        );
      });
      _scrollToLatest();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      final endContext = _conversationEndKey.currentContext;
      if (endContext != null) {
        Scrollable.ensureVisible(
          endContext,
          alignment: 1,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _showSafetyAndPrivacyInfo() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.shield_outlined, color: AppColors.primaryGreen),
        title: const Text('About Care Guide'),
        content: const Text(
          'Care Guide uses EverCare’s Care Book and general older-adult care guidance. Your current question and up to 16 recent chat messages are sent for a contextual AI reply, but EverCare does not save this conversation to your account. Care Guide does not diagnose conditions, change medicines, or replace emergency services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeText = textScale > 1.5;
    final conversationItems = <Widget>[
      _CareGuideTopicBanner(chapter: widget.selectedChapter),
      const _CareGuideSafetyNote(),
      for (var index = 0; index < _messages.length; index++)
        _ChatBubble(
          key: ValueKey<String>('care-book-ai-message-$index'),
          message: _messages[index],
        ),
      if (_messages.length == 1 && !_sending) _SuggestedQuestions(onTap: _send),
      if (_sending) const _TypingBubble(),
      if (_notice case final notice?) _CareGuideNotice(message: notice),
      SizedBox(key: _conversationEndKey, height: 1),
    ];

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        key: careBookAiSheetKey,
        heightFactor: .92,
        alignment: Alignment.bottomCenter,
        child: Material(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: largeText
                      ? const EdgeInsets.fromLTRB(12, 8, 6, 8)
                      : const EdgeInsets.fromLTRB(16, 14, 10, 13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.lightGreen,
                        AppColors.purple.withValues(alpha: .08),
                        Colors.white,
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.primaryGreen.withValues(alpha: .12),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _CareGuideHeaderMascot(
                        size: largeText ? 44 : 56,
                        avatarKey: careBookAiHeaderMascotKey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!largeText) ...[
                              const _CareGuideIdentity(),
                              const SizedBox(height: 3),
                            ],
                            Text(
                              'Care Guide',
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: AppColors.darkGreen,
                              ),
                            ),
                            if (!largeText) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Care Book + older-adult care guidance.',
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        key: careBookAiSafetyButtonKey,
                        tooltip: 'Care Guide safety and privacy',
                        onPressed: _showSafetyAndPrivacyInfo,
                        icon: const Icon(Icons.shield_outlined),
                      ),
                      IconButton(
                        tooltip: 'Close Care Guide',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    itemCount: conversationItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 11),
                    itemBuilder: (context, index) => conversationItems[index],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: largeText
                      ? const EdgeInsets.fromLTRB(10, 8, 10, 9)
                      : const EdgeInsets.fromLTRB(14, 11, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: .82),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkGreen.withValues(alpha: .055),
                        blurRadius: 18,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: TextField(
                    key: careBookAiComposerKey,
                    controller: _messageController,
                    enabled: !_sending,
                    inputFormatters: [LengthLimitingTextInputFormatter(600)],
                    minLines: 1,
                    maxLines: largeText ? 1 : 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sending ? null : (message) => _send(message),
                    decoration: InputDecoration(
                      hintText: 'Ask about older-adult care…',
                      filled: true,
                      fillColor: AppColors.background,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Material(
                          color: _sending
                              ? AppColors.surfaceMuted
                              : AppColors.primaryGreen,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Send',
                            onPressed: _sending ? null : _send,
                            color: Colors.white,
                            icon: const Icon(Icons.send_rounded, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestedQuestions extends StatelessWidget {
  const _SuggestedQuestions({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'How can I make a daily care routine?',
      'What should I prepare for a medical visit?',
      'How can I make the home safer to prevent falls?',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.purple.withValues(alpha: .1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: AppColors.purple,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Not sure what to ask? Try one of these:',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in suggestions)
                ActionChip(
                  avatar: const Icon(Icons.lightbulb_outline_rounded, size: 17),
                  label: Text(suggestion),
                  onPressed: () => onTap(suggestion),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CareGuideSafetyNote extends StatelessWidget {
  const _CareGuideSafetyNote();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Recent messages are used for context. Care Guide does not diagnose, change medicines, or replace emergency services. EverCare does not save this conversation to your account.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 17,
              color: AppColors.secondaryText,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Older-adult care guidance · Not saved to your account',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareGuideNotice extends StatelessWidget {
  const _CareGuideNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.warningContainer,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.warning.withValues(alpha: .16)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 19,
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: AppTextStyles.small)),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, super.key});

  final CareBookChatMessage message;

  @override
  Widget build(BuildContext context) {
    final color = message.isUser ? AppColors.darkGreen : AppColors.card;
    final foreground = message.isUser ? Colors.white : AppColors.foreground;
    final speaker = message.isUser ? 'You' : 'Care Guide';
    final sourceLabel = message.sourceChapters.isEmpty
        ? ''
        : ' Care Book chapters ${message.sourceChapters.join(', ')}.';
    final bubble = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(message.isUser ? 16 : 5),
          topRight: Radius.circular(message.isUser ? 5 : 16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
        ),
        border: message.isUser
            ? null
            : Border.all(color: AppColors.purple.withValues(alpha: .13)),
        boxShadow: message.isUser
            ? null
            : [
                BoxShadow(
                  color: AppColors.darkGreen.withValues(alpha: .045),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            speaker,
            style: AppTextStyles.small.copyWith(
              color: message.isUser
                  ? Colors.white.withValues(alpha: .78)
                  : AppColors.purple,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message.text,
            style: AppTextStyles.body.copyWith(color: foreground, height: 1.4),
          ),
          if (!message.isUser && message.sourceChapters.isNotEmpty) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Care Book: ${message.sourceChapters.join(', ')}',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      label: '$speaker: ${message.text}.$sourceLabel',
      excludeSemantics: true,
      child: message.isUser
          ? Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: bubble,
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CareGuideHeaderMascot(
                  size: 38,
                  avatarKey: careBookAiAssistantAvatarKey,
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: bubble,
                  ),
                ),
              ],
            ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Care Guide is thinking',
      excludeSemantics: true,
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CareGuideHeaderMascot(
              size: 38,
              avatarKey: careBookAiTypingAvatarKey,
            ),
            SizedBox(width: 9),
            Flexible(
              child: AppCard(
                padding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                borderColor: Color(0x216D61A7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        'Care Guide is thinking…',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
