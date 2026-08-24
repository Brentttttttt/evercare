enum CareBookAiResponseStatus {
  answered,
  ignored,
  medicalRedirect,
  emergencyRedirect,
}

class HealthAiInsight {
  const HealthAiInsight({
    required this.status,
    required this.headline,
    required this.explanation,
    required this.tips,
    required this.nextStep,
    required this.disclaimer,
  });

  factory HealthAiInsight.fromMap(Map<String, dynamic> map) {
    return HealthAiInsight(
      status: _requiredText(map, 'status'),
      headline: _requiredText(map, 'headline'),
      explanation: _requiredText(map, 'explanation'),
      tips: _textList(map['tips']),
      nextStep: _requiredText(map, 'nextStep'),
      disclaimer: _requiredText(map, 'disclaimer'),
    );
  }

  final String status;
  final String headline;
  final String explanation;
  final List<String> tips;
  final String nextStep;
  final String disclaimer;
}

class CareBookChatMessage {
  const CareBookChatMessage.user(this.text)
    : isUser = true,
      sourceChapters = const [];

  const CareBookChatMessage.assistant(
    this.text, {
    this.sourceChapters = const [],
  }) : isUser = false;

  final String text;
  final bool isUser;
  final List<int> sourceChapters;
}

class CareBookAiResponse {
  const CareBookAiResponse({
    required this.status,
    required this.answer,
    required this.sourceChapters,
  });

  factory CareBookAiResponse.fromMap(Map<String, dynamic> map) {
    final status = switch (_requiredText(map, 'status')) {
      'answered' => CareBookAiResponseStatus.answered,
      'ignored' => CareBookAiResponseStatus.ignored,
      'medical_redirect' => CareBookAiResponseStatus.medicalRedirect,
      'emergency_redirect' => CareBookAiResponseStatus.emergencyRedirect,
      final value => throw FormatException(
        'Unknown Care Book AI status: $value',
      ),
    };
    final sourceValue = map['sources'];
    final sourceChapters = sourceValue is List
        ? sourceValue
              .whereType<num>()
              .map((value) => value.toInt())
              .where((value) => value >= 1 && value <= 12)
              .toSet()
              .toList()
        : const <int>[];
    return CareBookAiResponse(
      status: status,
      answer: _requiredText(map, 'answer'),
      sourceChapters: sourceChapters,
    );
  }

  final CareBookAiResponseStatus status;
  final String answer;
  final List<int> sourceChapters;
}

String _requiredText(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('AI response has no valid $field.');
}

List<String> _textList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
