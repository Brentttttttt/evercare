import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardSummary {
  const DashboardSummary({
    this.fullName,
    this.nextMedicationName,
    this.nextMedicationTime,
    this.nextAppointmentTitle,
    this.nextAppointmentAt,
  });

  final String? fullName;
  final String? nextMedicationName;
  final String? nextMedicationTime;
  final String? nextAppointmentTitle;
  final DateTime? nextAppointmentAt;
}

class DashboardRepository {
  const DashboardRepository(this._client);

  final SupabaseClient _client;

  Future<DashboardSummary> load() async {
    final user = _client.auth.currentUser;
    if (user == null) return const DashboardSummary();

    final results = await Future.wait<dynamic>([
      _client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle(),
      _client
          .from('medications')
          .select('name,schedule_time')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('schedule_time')
          .limit(1)
          .maybeSingle(),
      _client
          .from('appointments')
          .select('title,starts_at')
          .eq('user_id', user.id)
          .eq('status', 'upcoming')
          .gte('starts_at', DateTime.now().toUtc().toIso8601String())
          .order('starts_at')
          .limit(1)
          .maybeSingle(),
    ]);

    final profile = results[0] as Map<String, dynamic>?;
    final medication = results[1] as Map<String, dynamic>?;
    final appointment = results[2] as Map<String, dynamic>?;
    return DashboardSummary(
      fullName: _nonEmpty(profile?['full_name']),
      nextMedicationName: _nonEmpty(medication?['name']),
      nextMedicationTime: _formatDatabaseTime(
        medication?['schedule_time'] as String?,
      ),
      nextAppointmentTitle: _nonEmpty(appointment?['title']),
      nextAppointmentAt: appointment?['starts_at'] == null
          ? null
          : DateTime.parse(appointment!['starts_at'] as String).toLocal(),
    );
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String? _formatDatabaseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    final hour = int.tryParse(parts.first);
    if (hour == null) return value;
    final minute = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute ${hour >= 12 ? 'PM' : 'AM'}';
  }
}
