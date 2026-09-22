import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/blood_pressure_assessment.dart';
import '../models/bp_monitor_result.dart';
import '../models/evercare_ai.dart';

/// Calls EverCare's authenticated Edge Functions. Provider credentials stay
/// in Supabase Function secrets and are never included in the Flutter app.
class EverCareAiService {
  const EverCareAiService(this._client);

  final SupabaseClient _client;

  void _requireSignedInUser() {
    if (_client.auth.currentUser == null) {
      throw StateError('Sign in to use EverCare AI.');
    }
  }

  Future<HealthAiInsight> explainBloodPressure(BpMonitorResult result) async {
    _requireSignedInUser();
    final assessment = BloodPressureAssessment.fromValues(
      systolic: result.systolic,
      diastolic: result.diastolic,
      pulse: result.pulse,
    );
    final response = await _client.functions.invoke(
      'health-bp-insight',
      body: {
        // The Edge Function classifies this app-corrected reading. It forwards
        // only the resulting range and reviewed choices to the AI provider;
        // raw packet data and identity are never forwarded.
        'systolic': result.systolic,
        'diastolic': result.diastolic,
        'pulse': result.pulse,
        'category': assessment.categoryId,
        'measuredAt': result.receivedAt.toUtc().toIso8601String(),
      },
    );
    final insight = HealthAiInsight.fromMap(_responseMap(response.data));
    if (insight.systolic != result.systolic ||
        insight.diastolic != result.diastolic ||
        insight.pulse != result.pulse ||
        insight.status != assessment.categoryId ||
        insight.headline != assessment.friendlyStatus ||
        insight.rangeLabel != assessment.label ||
        insight.disclaimer != BloodPressureAssessment.shortDisclaimer ||
        insight.disclaimerDetails !=
            BloodPressureAssessment.additionalDisclaimerInfo) {
      throw const FormatException(
        'EverCare AI returned an insight for a different reading.',
      );
    }
    return insight;
  }

  Future<HealthBpChatResponse> askAboutBloodPressure({
    required BpMonitorResult result,
    required String message,
    List<EverCareAiChatTurn> history = const [],
  }) async {
    _requireSignedInUser();
    final assessment = BloodPressureAssessment.fromValues(
      systolic: result.systolic,
      diastolic: result.diastolic,
      pulse: result.pulse,
    );
    final response = await _client.functions.invoke(
      'health-bp-chat',
      body: healthBpChatRequestBody(
        result: result,
        message: message,
        history: history,
      ),
    );
    final chatResponse = HealthBpChatResponse.fromMap(
      _responseMap(response.data),
    );
    final expectedUrgentGuidance =
        assessment.category == BloodPressureCategory.severeHypertension
        ? assessment.nextStep
        : null;
    if (chatResponse.systolic != result.systolic ||
        chatResponse.diastolic != result.diastolic ||
        chatResponse.pulse != result.pulse ||
        chatResponse.category != assessment.categoryId ||
        chatResponse.urgentGuidance != expectedUrgentGuidance ||
        chatResponse.disclaimer != healthBpChatDisclaimer) {
      throw const FormatException(
        'EverCare AI returned a reply for a different reading.',
      );
    }
    return chatResponse;
  }

  Future<CareBookAiResponse> askCareBook({
    required String message,
    required int selectedChapter,
    List<EverCareAiChatTurn> history = const [],
  }) async {
    _requireSignedInUser();
    final response = await _client.functions.invoke(
      'care-book-ai',
      body: careBookAiRequestBody(
        message: message,
        selectedChapter: selectedChapter,
        history: history,
      ),
    );
    return CareBookAiResponse.fromMap(_responseMap(response.data));
  }

  Map<String, dynamic> _responseMap(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('EverCare AI returned an invalid response.');
  }
}

Map<String, Object> healthBpChatRequestBody({
  required BpMonitorResult result,
  required String message,
  List<EverCareAiChatTurn> history = const [],
}) => {
  // This is an intentional privacy boundary. Never add raw packet, device,
  // identity, timestamp, profile, or saved-history fields here.
  'message': message,
  'systolic': result.systolic,
  'diastolic': result.diastolic,
  'pulse': result.pulse,
  'history': everCareAiHistoryPayload(history),
};

Map<String, Object> careBookAiRequestBody({
  required String message,
  required int selectedChapter,
  List<EverCareAiChatTurn> history = const [],
}) => {
  'message': message,
  'selectedChapter': selectedChapter,
  'history': everCareAiHistoryPayload(history),
};

List<Map<String, String>> everCareAiHistoryPayload(
  Iterable<EverCareAiChatTurn> history,
) {
  // Match the Edge Function limits. Keep complete exchanges so a truncated
  // answer cannot lose a qualification or leave an orphaned assistant reply.
  // The initial UI greeting is display-only; model history starts with a user.
  final recent = <Map<String, String>>[];
  var totalCharacters = 0;
  for (final turn in history) {
    final content = turn.content.trim();
    if (content.isEmpty) continue;
    final isUser = turn.role == EverCareAiChatRole.user;
    if (content.length > (isUser ? 600 : 2400)) {
      // Keep a continuous suffix after any oversized exchange instead of
      // rewriting what the user or assistant said.
      recent.clear();
      totalCharacters = 0;
      continue;
    }
    if (recent.isEmpty && !isUser) continue;
    recent.add({'role': isUser ? 'user' : 'assistant', 'content': content});
    totalCharacters += content.length;
    while (recent.length > 16 || totalCharacters > 16000) {
      totalCharacters -= recent.removeAt(0)['content']!.length;
      while (recent.isNotEmpty && recent.first['role'] == 'assistant') {
        totalCharacters -= recent.removeAt(0)['content']!.length;
      }
    }
  }
  return recent;
}

/// Converts authenticated Edge Function failures into a short message that is
/// safe to show in the app. Never display arbitrary server exception details:
/// they can contain provider URLs, credentials, or internal stack traces.
String everCareAiFailureMessage(
  Object error, {
  required String connectionFallback,
}) {
  if (error is StateError) {
    return 'Sign in to use EverCare AI.';
  }
  if (error is AuthException) {
    return 'Your sign-in session has expired. Please sign in again.';
  }
  if (error is FormatException) {
    return 'EverCare AI returned an invalid response. Please try again.';
  }
  if (error is FunctionException) {
    final details = error.details;
    if (error.status == 429 && details is Map) {
      // Only recognized codes select app-owned text. Provider error messages
      // must never become user-visible copy.
      switch (details['code']) {
        case 'AI_DAILY_QUOTA':
          return 'EverCare AI has reached its daily free limit. Please try again after the daily reset.';
        case 'AI_COOLDOWN':
          return 'Please wait a few seconds before asking EverCare AI again.';
      }
    }
    return switch (error.status) {
      400 => 'Please check your question and try again.',
      401 || 403 => 'Your sign-in session has expired. Please sign in again.',
      413 => 'Please shorten your question and try again.',
      429 =>
        'EverCare AI is receiving a lot of requests right now. Please try again in a moment.',
      _ => "EverCare AI couldn't connect right now. Please try again.",
    };
  }
  return connectionFallback;
}
