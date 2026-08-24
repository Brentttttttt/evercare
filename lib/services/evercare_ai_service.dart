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
        // This is the app-corrected BLE value. Raw packet data and identity
        // are deliberately not sent to the AI provider.
        'systolic': result.systolic,
        'diastolic': result.diastolic,
        'pulse': result.pulse,
        'category': assessment.categoryId,
        'measuredAt': result.receivedAt.toUtc().toIso8601String(),
      },
    );
    return HealthAiInsight.fromMap(_responseMap(response.data));
  }

  Future<CareBookAiResponse> askCareBook({
    required String message,
    required int selectedChapter,
  }) async {
    _requireSignedInUser();
    final response = await _client.functions.invoke(
      'care-book-ai',
      body: {'message': message, 'selectedChapter': selectedChapter},
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
