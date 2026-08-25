enum CareBookAiResponseStatus {
  answered,
  ignored,
  medicalRedirect,
  emergencyRedirect,
}

enum EverCareAiChatRole { user, assistant }

class EverCareAiChatTurn {
  const EverCareAiChatTurn.user(this.content) : role = EverCareAiChatRole.user;

  const EverCareAiChatTurn.assistant(this.content)
    : role = EverCareAiChatRole.assistant;

  final EverCareAiChatRole role;
  final String content;
}

class HealthAiInsight {
  const HealthAiInsight({
    required this.status,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.headline,
    required this.rangeLabel,
    required this.explanation,
    required this.tips,
    required this.nextStep,
    required this.disclaimer,
    required this.disclaimerDetails,
  });

  factory HealthAiInsight.fromMap(Map<String, dynamic> map) {
    return HealthAiInsight(
      status: _requiredText(map, 'status'),
      systolic: _requiredInteger(map, 'systolic'),
      diastolic: _requiredInteger(map, 'diastolic'),
      pulse: _requiredInteger(map, 'pulse'),
      headline: _requiredText(map, 'headline'),
      rangeLabel: _requiredText(map, 'rangeLabel'),
      explanation: _requiredText(map, 'explanation'),
      tips: _textList(map['tips']),
      nextStep: _requiredText(map, 'nextStep'),
      disclaimer: _requiredText(map, 'disclaimer'),
      disclaimerDetails: _requiredText(map, 'disclaimerDetails'),
    );
  }

  final String status;
  final int systolic;
  final int diastolic;
  final int pulse;
  final String headline;
  final String rangeLabel;
  final String explanation;
  final List<String> tips;
  final String nextStep;
  final String disclaimer;
  final String disclaimerDetails;
}

const healthBpChatDisclaimer =
    'This chat explains this reading only and is not a medical diagnosis.';

enum HealthBpChatResponseStatus {
  answered,
  greeting,
  offTopic,
  medicalRedirect,
  emergencyRedirect,
}

class HealthBpChatResponse {
  const HealthBpChatResponse({
    required this.status,
    required this.answer,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.category,
    required this.urgentGuidance,
    required this.disclaimer,
  });

  factory HealthBpChatResponse.fromMap(Map<String, dynamic> map) {
    final status = switch (_requiredText(map, 'status')) {
      'answered' => HealthBpChatResponseStatus.answered,
      'greeting' => HealthBpChatResponseStatus.greeting,
      'off_topic' => HealthBpChatResponseStatus.offTopic,
      'medical_redirect' => HealthBpChatResponseStatus.medicalRedirect,
      'emergency_redirect' => HealthBpChatResponseStatus.emergencyRedirect,
      final value => throw FormatException(
        'Unknown blood-pressure chat status: $value',
      ),
    };
    return HealthBpChatResponse(
      status: status,
      answer: _requiredText(map, 'answer'),
      systolic: _requiredInteger(map, 'systolic'),
      diastolic: _requiredInteger(map, 'diastolic'),
      pulse: _requiredInteger(map, 'pulse'),
      category: _requiredText(map, 'category'),
      urgentGuidance: _nullableText(map, 'urgentGuidance'),
      disclaimer: _requiredText(map, 'disclaimer'),
    );
  }

  final HealthBpChatResponseStatus status;
  final String answer;
  final int systolic;
  final int diastolic;
  final int pulse;
  final String category;
  final String? urgentGuidance;
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
      // The Edge Function deliberately returns an empty answer when it
      // classifies a message as unrelated to the Care Book. Keep requiring a
      // real answer for every status that the UI will render.
      answer: status == CareBookAiResponseStatus.ignored
          ? _optionalText(map, 'answer')
          : _requiredText(map, 'answer'),
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

String _optionalText(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value == null) return '';
  if (value is String) return value.trim();
  throw FormatException('AI response has no valid $field.');
}

String? _nullableText(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value == null) return null;
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('AI response has no valid $field.');
}

int _requiredInteger(Map<String, dynamic> map, String field) {
  final value = map[field];
  if (value is int) return value;
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
