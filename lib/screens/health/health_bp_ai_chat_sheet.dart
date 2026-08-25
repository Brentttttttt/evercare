import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/blood_pressure_assessment.dart';
import '../../models/bp_monitor_result.dart';
import '../../models/evercare_ai.dart';
import '../../services/evercare_ai_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_ai_mascot.dart';
import '../../widgets/evercare_backend_scope.dart';

typedef HealthBpAiRequest =
    Future<HealthBpChatResponse> Function({
      required String message,
      required BpMonitorResult result,
    });

const healthBpAiChatButtonKey = ValueKey<String>('health-bp-ai-chat-button');
const healthBpAiChatSheetKey = ValueKey<String>('health-bp-ai-chat-sheet');
const healthBpAiChatHeaderMascotKey = ValueKey<String>(
  'health-bp-ai-chat-header-mascot',
);
const healthBpAiChatAssistantMascotKey = ValueKey<String>(
  'health-bp-ai-chat-assistant-mascot',
);
const healthBpAiChatTypingMascotKey = ValueKey<String>(
  'health-bp-ai-chat-typing-mascot',
);
const healthBpAiChatComposerKey = ValueKey<String>(
  'health-bp-ai-chat-composer',
);
const healthBpAiChatSafetyButtonKey = ValueKey<String>(
  'health-bp-ai-chat-safety-button',
);

class HealthBpAiChatSheet extends StatefulWidget {
  const HealthBpAiChatSheet({
    required this.result,
    required this.assessment,
    this.requestAiResponse,
    super.key,
  });

  final BpMonitorResult result;
  final BloodPressureAssessment assessment;
  final HealthBpAiRequest? requestAiResponse;

  @override
  State<HealthBpAiChatSheet> createState() => _HealthBpAiChatSheetState();
}

class _HealthBpAiChatSheetState extends State<HealthBpAiChatSheet> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _conversationEndKey = GlobalKey();
  late final List<_HealthChatMessage> _messages;
  bool _sending = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    final result = widget.result;
    final urgentNote =
        widget.assessment.category == BloodPressureCategory.severeHypertension
        ? ' Please also follow the urgent guidance shown above.'
        : '';
    _messages = [
      _HealthChatMessage.assistant(
        'Hello! I’m here to help you understand this '
        '${result.systolic}/${result.diastolic} mmHg reading. You can ask '
        'about the upper and lower numbers, why ${widget.assessment.label} '
        'is shown, or how to check again carefully.$urgentNote',
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? submittedMessage]) async {
    final message = (submittedMessage ?? _messageController.text).trim();
    if (message.isEmpty || _sending) return;

    final requestAiResponse = widget.requestAiResponse;
    final client = requestAiResponse == null
        ? EverCareBackendScope.maybeClient(context)
        : null;
    if (requestAiResponse == null && client?.auth.currentUser == null) {
      setState(() {
        _notice = 'Sign in to ask EverCare AI. This chat is not saved.';
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
      _messages.add(_HealthChatMessage.user(message));
      _sending = true;
      _notice = null;
    });
    _scrollToLatest();
    try {
      final response = requestAiResponse != null
          ? await requestAiResponse(message: message, result: widget.result)
          : await EverCareAiService(client!).askAboutBloodPressure(
              result: widget.result,
              message: message,
              history: history,
            );
      if (!mounted) return;
      setState(() {
        _messages.add(
          _HealthChatMessage.assistant(
            response.answer,
            status: response.status,
            urgentGuidance: response.urgentGuidance,
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
              'Could not reach EverCare AI. Check your connection and try again.',
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
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _showSafetyAndPrivacyInfo() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.shield_outlined, color: AppColors.primaryGreen),
        title: const Text('About this reading chat'),
        content: const Text(
          '$healthBpChatDisclaimer Your current question, up to 8 recent chat messages, and the corrected numbers shown in EverCare are sent for AI processing so replies can understand the conversation. EverCare does not add your account identity, raw BLE packet, device details, or saved health history. Anything identifying that you type is still part of your messages. EverCare does not save this conversation to your account.',
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
      _ReadingContextBanner(
        result: widget.result,
        assessment: widget.assessment,
      ),
      if (widget.assessment.category ==
          BloodPressureCategory.severeHypertension)
        _UrgentGuidanceCard(message: widget.assessment.nextStep),
      _HealthChatPrivacyNote(onTap: _showSafetyAndPrivacyInfo),
      for (var index = 0; index < _messages.length; index++)
        _HealthChatBubble(
          key: ValueKey<String>('health-bp-chat-message-$index'),
          message: _messages[index],
        ),
      if (_messages.length == 1 && !_sending)
        _HealthSuggestedQuestions(
          severe:
              widget.assessment.category ==
              BloodPressureCategory.severeHypertension,
          onTap: _send,
        ),
      if (_sending) const _HealthChatTypingBubble(),
      if (_notice case final notice?) _HealthChatNotice(message: notice),
      if (widget.assessment.category ==
              BloodPressureCategory.severeHypertension &&
          (_sending || _notice != null))
        _UrgentGuidanceCard(message: widget.assessment.nextStep),
      SizedBox(key: _conversationEndKey, height: 1),
    ];

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        key: healthBpAiChatSheetKey,
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
                        AppColors.purple.withValues(alpha: .12),
                        AppColors.lightGreen,
                        Colors.white,
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.purple.withValues(alpha: .12),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      KeyedSubtree(
                        key: healthBpAiChatHeaderMascotKey,
                        child: AiMascotAvatar(size: largeText ? 36 : 56),
                      ),
                      SizedBox(width: largeText ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!largeText)
                              Text(
                                'EVERCARE AI',
                                style: AppTextStyles.eyebrow.copyWith(
                                  color: AppColors.purple,
                                ),
                              ),
                            Text(
                              largeText
                                  ? 'Reading chat'
                                  : 'Ask about this reading',
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: AppColors.darkGreen,
                              ),
                            ),
                            if (!largeText) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${widget.result.systolic}/${widget.result.diastolic} mmHg · Pulse ${widget.result.pulse} BPM',
                                style: AppTextStyles.small,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        key: healthBpAiChatSafetyButtonKey,
                        tooltip: 'Reading chat safety and privacy',
                        onPressed: _showSafetyAndPrivacyInfo,
                        visualDensity: largeText
                            ? VisualDensity.compact
                            : VisualDensity.standard,
                        constraints: largeText
                            ? const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              )
                            : null,
                        icon: const Icon(Icons.shield_outlined),
                      ),
                      IconButton(
                        tooltip: 'Close reading chat',
                        onPressed: () => Navigator.pop(context),
                        visualDensity: largeText
                            ? VisualDensity.compact
                            : VisualDensity.standard,
                        constraints: largeText
                            ? const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              )
                            : null,
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
                    key: healthBpAiChatComposerKey,
                    controller: _messageController,
                    enabled: !_sending,
                    inputFormatters: [LengthLimitingTextInputFormatter(600)],
                    minLines: 1,
                    maxLines: largeText ? 1 : 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sending ? null : (message) => _send(message),
                    decoration: InputDecoration(
                      hintText: 'Ask about this reading…',
                      isDense: largeText,
                      contentPadding: largeText
                          ? const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            )
                          : null,
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

class _ReadingContextBanner extends StatelessWidget {
  const _ReadingContextBanner({required this.result, required this.assessment});

  final BpMonitorResult result;
  final BloodPressureAssessment assessment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: .16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.monitor_heart_rounded,
            color: AppColors.darkGreen,
            size: 22,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.systolic}/${result.diastolic} mmHg · Pulse ${result.pulse} BPM',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(assessment.label, style: AppTextStyles.small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentGuidanceCard extends StatelessWidget {
  const _UrgentGuidanceCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Urgent guidance. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.destructiveContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withValues(alpha: .28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.emergency_rounded, color: AppColors.danger),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Urgent guidance for this reading',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: AppTextStyles.bodyMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthChatPrivacyNote extends StatelessWidget {
  const _HealthChatPrivacyNote({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open reading chat safety and privacy details',
      child: Material(
        color: AppColors.purple.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 19,
                  color: AppColors.purple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$healthBpChatDisclaimer Your question, recent messages, and corrected numbers are sent for contextual replies. EverCare does not add your identity, device details, raw BLE data, or saved history, and does not save this chat to your account. Tap for details.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.purple,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthSuggestedQuestions extends StatelessWidget {
  const _HealthSuggestedQuestions({required this.severe, required this.onTap});

  final bool severe;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final suggestions = severe
        ? const [
            'What should I do now?',
            'Which symptoms need emergency help?',
            'How should I repeat this reading safely?',
          ]
        : const [
            'Why is this reading in this range?',
            'Which number set the range?',
            'How should I check again?',
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
          Text(
            'You can ask:',
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in suggestions)
                ActionChip(
                  avatar: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 17,
                  ),
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

class _HealthChatMessage {
  const _HealthChatMessage.user(this.text)
    : isUser = true,
      status = null,
      urgentGuidance = null;

  const _HealthChatMessage.assistant(
    this.text, {
    this.status,
    this.urgentGuidance,
  }) : isUser = false;

  final String text;
  final bool isUser;
  final HealthBpChatResponseStatus? status;
  final String? urgentGuidance;
}

class _HealthChatBubble extends StatelessWidget {
  const _HealthChatBubble({required this.message, super.key});

  final _HealthChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUrgent =
        message.status == HealthBpChatResponseStatus.emergencyRedirect;
    final isBoundary =
        message.status == HealthBpChatResponseStatus.offTopic ||
        message.status == HealthBpChatResponseStatus.medicalRedirect;
    final bubbleColor = message.isUser
        ? AppColors.darkGreen
        : isUrgent
        ? AppColors.destructiveContainer
        : Colors.white;
    final foreground = message.isUser ? Colors.white : AppColors.foreground;
    final borderColor = isUrgent
        ? AppColors.danger.withValues(alpha: .3)
        : isBoundary
        ? AppColors.warning.withValues(alpha: .22)
        : AppColors.purple.withValues(alpha: .13);
    final speaker = message.isUser ? 'You' : 'EverCare AI';
    final bubble = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(message.isUser ? 16 : 5),
          topRight: Radius.circular(message.isUser ? 5 : 16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
        ),
        border: message.isUser ? null : Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            speaker,
            style: AppTextStyles.small.copyWith(
              color: message.isUser
                  ? Colors.white.withValues(alpha: .8)
                  : isUrgent
                  ? AppColors.danger
                  : AppColors.purple,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message.text,
            style: AppTextStyles.body.copyWith(color: foreground, height: 1.4),
          ),
          if (message.urgentGuidance case final guidance?) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.destructiveContainer,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: .24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Urgent guidance still applies',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(guidance, style: AppTextStyles.bodyMuted),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      label:
          '$speaker: ${message.text}${message.urgentGuidance == null ? '' : '. Urgent guidance: ${message.urgentGuidance}'}',
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
                KeyedSubtree(
                  key: healthBpAiChatAssistantMascotKey,
                  child: const AiMascotAvatar(size: 38),
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

class _HealthChatTypingBubble extends StatelessWidget {
  const _HealthChatTypingBubble();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'EverCare AI is thinking',
      excludeSemantics: true,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyedSubtree(
            key: healthBpAiChatTypingMascotKey,
            child: AiMascotAvatar(size: 38),
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
                      'EverCare AI is thinking…',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthChatNotice extends StatelessWidget {
  const _HealthChatNotice({required this.message});

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
