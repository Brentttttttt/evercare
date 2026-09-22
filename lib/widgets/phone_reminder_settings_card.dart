import 'package:flutter/material.dart';

import '../services/phone_reminder_controller.dart';
import '../theme/app_text_styles.dart';
import 'app_page.dart';
import 'phone_reminder_scope.dart';

/// Device reminder controls, separate from EverCare's account inbox.
class PhoneReminderSettingsCard extends StatelessWidget {
  const PhoneReminderSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PhoneReminderScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Phone reminders', style: AppTextStyles.cardTitle),
            const SizedBox(height: 8),
            if (!controller.supported)
              const Text('Phone reminders are available on Android.')
            else if (!controller.initialized)
              const Text('Checking phone reminder settings…')
            else if (!controller.signedIn)
              const Text('Sign in to turn on phone reminders.')
            else ...[
              Row(
                children: [
                  const Expanded(child: Text('Remind me on this phone')),
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Phone reminders',
                    child: Switch(
                      value: controller.enabled,
                      onChanged: controller.busy
                          ? null
                          : (enabled) => _run(
                              context,
                              enabled ? controller.enable : controller.disable,
                            ),
                    ),
                  ),
                ],
              ),
              Text(
                controller.enabled
                    ? controller.notificationsAllowed
                          ? 'On. Reminders can appear while EverCare is in the background.'
                          : 'Phone permission is blocked. Allow notifications in phone settings to receive reminders.'
                    : 'Off. Turn on reminders for medicine and appointments.',
              ),
              const SizedBox(height: 8),
              Text(
                'Notification permission: ${controller.notificationsAllowed ? 'allowed' : 'not allowed'}.',
                style: AppTextStyles.bodyMuted,
              ),
              Text(
                controller.exactAlarmsAllowed
                    ? 'Exact timing permission: allowed.'
                    : 'Exact timing permission: not allowed. Reminders may be delayed.',
                style: AppTextStyles.bodyMuted,
              ),
              if (controller.busy) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: const Text('Updating phone reminders…'),
                ),
              ],
              if (controller.error case final error?) ...[
                const SizedBox(height: 8),
                Semantics(liveRegion: true, child: Text(error)),
              ],
              const SizedBox(height: 12),
              Text(
                '${controller.scheduledCount} reminders queued on this phone.',
              ),
              if (controller.scheduledThrough case final through?)
                Text(
                  'Latest queued reminder: ${_phoneDate(context, through)}. '
                  'This does not confirm every event is covered.',
                  style: AppTextStyles.bodyMuted,
                ),
              Text(
                controller.lastSyncedAt == null
                    ? 'Not synced yet.'
                    : 'Last synced: ${_phoneDate(context, controller.lastSyncedAt!)}.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 12),
              if (controller.enabled &&
                  controller.notificationsAllowed &&
                  !controller.exactAlarmsAllowed)
                _Action(
                  label: 'Allow exact timing',
                  onPressed: controller.busy
                      ? null
                      : () => _run(context, controller.enableExactTiming),
                ),
              _Action(
                label: 'Open phone settings',
                onPressed: controller.busy
                    ? null
                    : () => _run(context, controller.openSettings),
              ),
              _Action(
                label: 'Refresh reminders',
                onPressed: controller.busy
                    ? null
                    : () => _run(context, controller.refresh),
              ),
              _Action(
                label: 'Test phone reminder',
                onPressed:
                    controller.busy ||
                        !controller.enabled ||
                        !controller.notificationsAllowed
                    ? null
                    : () => _testReminder(context, controller),
              ),
              Text(
                'The test queues an alert for 10 seconds from now. '
                'Put EverCare in the background to check it. '
                'It does not add an inbox message; flexible timing may delay it.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: const Text('How reminders work'),
                children: const [
                  Text(
                    'Medicine times use Philippine time. Appointment alerts '
                    'are planned one day before, one hour before, and at the visit.\n\n'
                    'EverCare queues up to 400 of the earliest reminders within '
                    'the next 30 days. Open the app regularly to refresh and '
                    'extend the schedule.\n\n'
                    'Lock-screen alerts use generic wording to keep medicine '
                    'and appointment details private.\n\n'
                    'Delivery depends on your phone. Force-stopping the app, '
                    'turning the phone off, or battery restrictions can prevent '
                    'or delay alerts.',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _phoneDate(BuildContext context, DateTime value) {
    final philippines = value.toUtc().add(const Duration(hours: 8));
    final labels = MaterialLocalizations.of(context);
    return '${labels.formatMediumDate(philippines)}, '
        '${labels.formatTimeOfDay(TimeOfDay.fromDateTime(philippines))} PH time';
  }

  static Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update phone reminders. Please try again.'),
        ),
      );
    }
  }

  static Future<void> _testReminder(
    BuildContext context,
    PhoneReminderController controller,
  ) async {
    try {
      final queued = await controller.sendTestReminder();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            queued
                ? 'Test queued for 10 seconds from now. Put EverCare in the background; phone settings may delay delivery.'
                : 'Test was not queued. Check phone permissions and try again.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not queue the test reminder.')),
      );
    }
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}
