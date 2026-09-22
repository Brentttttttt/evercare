import 'package:flutter/foundation.dart';

/// UI-facing contract, kept independent of the operating-system plugin.
abstract class PhoneReminderController extends ChangeNotifier {
  bool get supported;
  bool get initialized;
  bool get signedIn;
  bool get enabled;
  bool get notificationsAllowed;
  bool get exactAlarmsAllowed;
  bool get busy;
  int get scheduledCount;
  DateTime? get scheduledThrough;
  DateTime? get lastSyncedAt;
  String? get error;

  Future<void> enable();
  Future<void> disable();
  Future<void> refresh();
  Future<void> enableExactTiming();
  Future<void> openSettings();
  Future<bool> sendTestReminder();

  /// Offers an explanation once per account/device, never a repeated OS prompt.
  Future<bool> shouldOfferPermissionPrompt();
}
