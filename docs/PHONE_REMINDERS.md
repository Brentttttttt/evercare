# Phone reminders

EverCare can schedule medication and hospital-appointment notifications on its
Android app. These are phone notifications, separate from the in-app notification
list. Android delivers a saved reminder even while EverCare is in the background
or its Flutter process is not running. This implementation is local scheduling,
not Firebase/server push. It does not require another AI or backend API key.

## Enable reminders

1. Sign in on the Android app and open Settings > Phone reminders (also available
   from the Notifications screen).
2. Enable phone reminders and allow the Android notification permission when
   prompted. Denying permission does not prevent using the rest of EverCare.
3. Optionally enable precise timing and grant EverCare **Alarms & reminders**
   access in Android settings. Without this access, reminders use Android's
   inexact scheduling and may arrive later than their scheduled times.
4. Use **Test phone reminder**, which queues an alert for 10 seconds later, then
   leave EverCare and check the phone's
   notification drawer. Check both the app-level notification permission and the
   individual medication/appointment notification channels if no alert appears.

Android 13 and newer requires user approval for `POST_NOTIFICATIONS`. Precise
timing uses the user-controlled `SCHEDULE_EXACT_ALARM` permission; EverCare does
not request restricted `USE_EXACT_ALARM`, full-screen alarms, Do Not Disturb
bypass, or a battery-optimization exemption. See the
[Android notification-permission documentation](https://developer.android.com/develop/ui/compose/notifications/notification-permission)
and [alarm permission guidance](https://developer.android.com/develop/background-work/services/alarms).

## What is scheduled

- Medications use their existing structured schedule and its Philippine
  wall-clock time (UTC+8), including configured recurrence and start/end dates.
  Free-text dosage/frequency is not converted into new dosing instructions.
- Upcoming appointments have reminders one day before, one hour before, and at
  the appointment's start. Only future reminder times are scheduled; adding an
  appointment shortly before it starts does not replay earlier reminders.
- Completed appointments and handled medication occurrences are excluded.
  Notifications never mark medication as taken, skipped, or missed and never
  change a medical record in the background.
- Phone notification text is deliberately generic: it does not expose a
  medication name, dosage, doctor, hospital, or patient identity on the lock
  screen. Open EverCare and review the record before acting on a delayed alert;
  a notification is not an instruction to take a catch-up dose.

The planner creates a rolling 30-day schedule, capped at the earliest 400
notifications across both medication and appointment reminders. With many
reminders, the cap can cover less than 30 days. The settings screen exposes
scheduling status. Open EverCare regularly so its schedule can be extended.
There is no infinite background refresh while the app remains closed.

Plans are reconciled when the signed-in app opens, resumes, or relevant local
repository data changes. Edits/deletions replace or cancel obsolete reminders;
turning reminders off or signing out cancels scheduled phone notifications.
Account-specific scheduling prevents a subsequent account from inheriting the
previous account's reminders.

## Delivery and data boundaries

The Android implementation uses `flutter_local_notifications` 22.3.1 and
`timezone` 0.11.1. One-shot UTC timestamps are handed to Android's alarm system,
not a Dart timer. Medication timestamps retain EverCare's existing UTC+8
scheduling rules; appointment timestamps retain their absolute saved instant.
Changing the phone's time zone does not silently change those saved instants.

After a successful sync and local scheduling, delivery does not need an internet
connection. However, this does **not** deliver new caregiver/server edits to a
closed app: those changes require EverCare to reopen and sync. Server push and
cross-device real-time schedule updates while the app is closed are separate,
unimplemented capabilities.

The manifest registers the plugin's scheduled-notification and boot receivers.
Android can restore stored reminders after a restart or app update. A reminder
cannot fire while the phone is powered off, and an overdue reminder can appear
after it powers back on. Check the appointment or medication record rather than
treating a late notification as a current instruction.

Delivery remains subject to user/device controls:

- **Force stop:** explicitly force-stopping EverCare can cancel or suspend alarms
  until the user launches it again. This differs from simply leaving the app.
  [Android 15 stopped-state behavior](https://developer.android.com/about/versions/15/behavior-changes-all#stopped-state)
  explicitly cancels pending intents.
- **Permissions:** disabling notifications or a reminder channel prevents alerts.
  Revoking exact-alarm access can cancel previously registered exact alarms;
  reopen EverCare to rebuild the plan using the current permission state.
- **Device policies:** Do Not Disturb, silent notification channels, battery
  saver, and manufacturer-specific background restrictions may suppress sound
  or delay/prevent delivery. The
  [plugin's Android limitations](https://pub.dev/packages/flutter_local_notifications/versions/22.3.1#scheduled-android-notifications)
  describe OEM restrictions and device alarm-count limits.
- **Timing:** inexact alarms can be delayed substantially by Android. Even exact
  reminders are not a guarantee of medical monitoring or an emergency service.

The repository currently has an Android mobile target, not an iOS target. No
iPhone delivery has been implemented or verified by this change. Web/desktop
views must not imply that Android phone scheduling is available there.

## Verification and physical-device checklist

The dependency resolution, notification XML parsing, and Android
`:app:processDebugMainManifest` check passed. There was no ADB-connected device
during implementation, so actual phone delivery has not yet been verified.
Automated/build results should be recorded separately from this device check.

On a physical Android phone, verify the following before relying on reminders:

1. Install the updated APK. Enable reminders and grant notification permission.
   Use the test action, press Home, and verify a phone notification appears.
2. Create a medication and appointment due soon. Leave the app, lock the screen,
   and confirm notification delivery, channel sound, and tap navigation.
3. Repeat with the app removed from Recents, then with internet disabled after
   its reminders have successfully synchronized. Do not confuse this with
   Android's explicit **Force stop** command.
4. Edit/delete the records, mark a dose handled, complete an appointment, and
   verify obsolete pending notifications are removed.
5. Deny notification permission, disable a channel, and deny precise timing.
   Verify clear settings guidance, no crash, and honest inexact-timing status.
6. Reboot the phone with a future reminder pending. Check restoration and avoid
   interpreting any overdue notification as a catch-up dosing instruction.
7. Sign out, then sign in as a different test account. Confirm no previous
   account's reminders remain.

Use synthetic test records. Do not install over or alter a real patient's
records merely to verify notification delivery.
