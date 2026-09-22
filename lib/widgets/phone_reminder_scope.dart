import 'package:flutter/widgets.dart';

import '../services/phone_reminder_controller.dart';

class PhoneReminderScope extends InheritedNotifier<PhoneReminderController> {
  const PhoneReminderScope({
    required PhoneReminderController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static PhoneReminderController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PhoneReminderScope>()
      ?.notifier;
}
