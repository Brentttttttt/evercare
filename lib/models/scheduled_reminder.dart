import 'dart:convert';

enum ReminderKind { medication, appointment }

/// A single device notification. Both timestamps are canonical UTC instants.
///
/// Notification text is intentionally generic: names, dosages, clinic details,
/// and other health information must not be exposed on a phone's lock screen.
class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.userId,
    required this.resourceId,
    required this.kind,
    required this.scheduledForUtc,
    required this.occurrenceUtc,
    required this.title,
    required this.body,
  });

  final int id;
  final String userId;
  final String resourceId;
  final ReminderKind kind;
  final DateTime scheduledForUtc;
  final DateTime occurrenceUtc;
  final String title;
  final String body;

  /// Only opaque identifiers and timestamps are persisted in the tap payload.
  String get payload => jsonEncode({
    'version': 1,
    'userId': userId,
    'kind': kind.name,
    'resourceId': resourceId,
    'occurrenceUtc': occurrenceUtc.toUtc().toIso8601String(),
    'scheduledForUtc': scheduledForUtc.toUtc().toIso8601String(),
  });
}

/// A validated tap destination; the caller must still check the signed-in user
/// and load the current resource before displaying its details.
class ReminderNotificationTarget {
  const ReminderNotificationTarget({
    required this.userId,
    required this.resourceId,
    required this.kind,
    required this.occurrenceUtc,
    required this.scheduledForUtc,
  });

  final String userId;
  final String resourceId;
  final ReminderKind kind;
  final DateTime occurrenceUtc;
  final DateTime scheduledForUtc;

  static ReminderNotificationTarget? tryParse(String? payload) {
    if (payload == null || payload.isEmpty || payload.length > 2048) {
      return null;
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        return null;
      }
      final userId = decoded['userId'];
      final resourceId = decoded['resourceId'];
      final kind = switch (decoded['kind']) {
        'medication' => ReminderKind.medication,
        'appointment' => ReminderKind.appointment,
        _ => null,
      };
      final occurrenceText = decoded['occurrenceUtc'];
      final scheduledText = decoded['scheduledForUtc'];
      if (!_isIdentifier(userId) ||
          !_isIdentifier(resourceId) ||
          kind == null ||
          occurrenceText is! String ||
          scheduledText is! String) {
        return null;
      }
      final occurrence = DateTime.tryParse(occurrenceText);
      final scheduled = DateTime.tryParse(scheduledText);
      if (occurrence == null ||
          scheduled == null ||
          !occurrence.isUtc ||
          !scheduled.isUtc) {
        return null;
      }
      return ReminderNotificationTarget(
        userId: userId as String,
        resourceId: resourceId as String,
        kind: kind,
        occurrenceUtc: occurrence,
        scheduledForUtc: scheduled,
      );
    } on FormatException {
      return null;
    }
  }
}

bool _isIdentifier(Object? value) =>
    value is String && value.trim().isNotEmpty && value.length <= 128;
