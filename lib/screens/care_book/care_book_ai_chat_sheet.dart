import 'package:flutter/material.dart';

import '../../models/care_book_chapter.dart';
import '../../models/evercare_ai.dart';
import '../../services/evercare_ai_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/evercare_backend_scope.dart';

class CareBookAssistantCard extends StatelessWidget {
  const CareBookAssistantCard({
    required this.chapter,
    required this.onTap,
    super.key,
  });

  final CareBookChapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: AppColors.primaryContainer,
      borderColor: AppColors.primaryGreen.withValues(alpha: .24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ask Care Guide', style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(
                  'Ask about caregiving topics from the Care Book. It is ready to help with ${chapter.title.toLowerCase()}.',
                  style: AppTextStyles.bodyMuted.copyWith(height: 1.36),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}

class CareBookAiChatSheet extends StatefulWidget {
  const CareBookAiChatSheet({required this.selectedChapter, super.key});

  final CareBookChapter selectedChapter;

  @override
  State<CareBookAiChatSheet> createState() => _CareBookAiChatSheetState();
}

class _CareBookAiChatSheetState extends State<CareBookAiChatSheet> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<CareBookChatMessage> _messages = const [
    CareBookChatMessage.assistant(
      'Ask me a practical caregiving question from the Care Book. I can help with routines, organization, safety, support, and emergency preparation.',
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

    final client = EverCareBackendScope.maybeClient(context);
    if (client?.auth.currentUser == null) {
      setState(() {
        _notice = 'Sign in to ask Care Guide. Your chat is not saved.';
      });
      return;
    }

    _messageController.clear();
    setState(() {
      _sending = true;
      _notice = null;
    });
    try {
      final response = await EverCareAiService(client!).askCareBook(
        message: message,
        selectedChapter: widget.selectedChapter.number,
      );
      if (!mounted) return;
      if (response.status == CareBookAiResponseStatus.ignored) {
        // Off-topic messages are deliberately not added to the conversation
        // and receive no assistant acknowledgement.
        return;
      }
      setState(() {
        _messages.add(CareBookChatMessage.user(message));
        _messages.add(
          CareBookChatMessage.assistant(
            response.answer,
            sourceChapters: response.sourceChapters,
          ),
        );
      });
      _scrollToLatest();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notice =
            'Care Guide is unavailable right now. Please check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: .9,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ask Care Guide', style: AppTextStyles.sectionTitle),
                      SizedBox(height: 3),
                      Text(
                        'Answers are grounded in EverCare’s Care Book.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Current Care Book topic: ${widget.selectedChapter.number}. ${widget.selectedChapter.title}',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_messages.length == 1) _SuggestedQuestions(onTap: _send),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 10, bottom: 12),
                itemCount: _messages.length + (_sending ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (_sending && index == _messages.length) {
                    return const _TypingBubble();
                  }
                  return _ChatBubble(message: _messages[index]);
                },
              ),
            ),
            if (_notice case final notice?) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(notice, style: AppTextStyles.small),
              ),
            ],
            TextField(
              controller: _messageController,
              enabled: !_sending,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask a Care Book question…',
                suffixIcon: IconButton(
                  tooltip: 'Send',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Care Guide does not diagnose, change medicines, or handle emergencies. It does not save this conversation.',
              style: AppTextStyles.small,
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(
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
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final CareBookChatMessage message;

  @override
  Widget build(BuildContext context) {
    final color = message.isUser ? AppColors.darkGreen : AppColors.card;
    final foreground = message.isUser ? Colors.white : AppColors.foreground;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: message.isUser ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: AppTextStyles.body.copyWith(
                  color: foreground,
                  height: 1.4,
                ),
              ),
              if (!message.isUser && message.sourceChapters.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Care Book: ${message.sourceChapters.join(', ')}',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: AppCard(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 9),
            Text('Care Guide is thinking…', style: AppTextStyles.bodyMuted),
          ],
        ),
      ),
    );
  }
}
