import '../models/scheduled_reminder.dart';

typedef ReminderChangeHandler =
    Future<void> Function(String userId, ReminderKind kind, String? resourceId);

/// Successful writes await device reconciliation, without making an OS error
/// look like a failed database save. No controller means no platform side effects
/// in repository-only tests or unsupported application hosts.
abstract final class ReminderChanges {
  static ReminderChangeHandler? onChanged;
  static Future<void> Function(String userId)? onSigningOut;

  static Future<void> changed(
    String userId,
    ReminderKind kind, [
    String? resourceId,
  ]) async {
    try {
      await onChanged?.call(userId, kind, resourceId);
    } catch (_) {
      // The successful database write remains successful. The device reminder
      // service exposes its own retry status independently of repository data.
    }
  }

  static Future<void> signingOut(String userId) async {
    try {
      await onSigningOut?.call(userId);
    } catch (_) {
      // An OS issue must not prevent signing out of the Supabase account.
    }
  }
}
