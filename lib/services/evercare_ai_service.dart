import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/blood_pressure_assessment.dart';
import '../models/bp_monitor_result.dart';
import '../models/evercare_ai.dart';

/// Calls EverCare's authenticated Edge Functions. The Groq credential stays
/// in Supabase Function secrets and is never included in the Flutter app.
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
  final recent = history
      .map((turn) {
        final trimmed = turn.content.trim();
        final content = trimmed.length <= 600
            ? trimmed
            : trimmed.substring(0, 600);
        return {
          'role': turn.role == EverCareAiChatRole.user ? 'user' : 'assistant',
          'content': content,
        };
      })
      .where((turn) => turn['content']!.isNotEmpty)
      .toList(growable: true);
  if (recent.length > 8) recent.removeRange(0, recent.length - 8);
  var totalCharacters = recent.fold<int>(
    0,
    (total, turn) => total + turn['content']!.length,
  );
  while (recent.length > 1 && totalCharacters > 3200) {
    totalCharacters -= recent.removeAt(0)['content']!.length;
  }
  return recent;
}

/// Converts authenticated Edge Function failures into a short message that is
/// safe to show in the app. A connection hint is reserved for failures where
/// the server did not return a useful response.
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
    final serverMessage = switch (details) {
      Map() => details['error'] ?? details['message'],
      String() => details,
      _ => null,
    };
    if (serverMessage is String) {
      final text = serverMessage.trim();
      if (text.isNotEmpty && text.length <= 240) return text;
    }
    return switch (error.status) {
      401 => 'Your sign-in session has expired. Please sign in again.',
      429 => 'EverCare AI is busy. Please wait a moment and try again.',
      _ => 'EverCare AI is temporarily unavailable. Please try again.',
    };
  }
  return connectionFallback;
}
