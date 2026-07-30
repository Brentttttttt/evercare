import 'package:flutter/widgets.dart';

import '../services/bp_monitor_ble_service.dart';

/// Exposes the single application-owned BLE service to every EverCare route.
///
/// This keeps Health and BLE Diagnostics on the same scan, connection, and
/// notification subscription without adding another state-management package.
class BpMonitorBleScope extends InheritedNotifier<BpMonitorBleService> {
  const BpMonitorBleScope({
    required BpMonitorBleService service,
    required super.child,
    super.key,
  }) : super(notifier: service);

  static BpMonitorBleService watch(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<BpMonitorBleScope>();
    assert(scope != null, 'BpMonitorBleScope is missing above this route.');
    return scope!.notifier!;
  }

  static BpMonitorBleService read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<BpMonitorBleScope>();
    final scope = element?.widget as BpMonitorBleScope?;
    assert(scope != null, 'BpMonitorBleScope is missing above this route.');
    return scope!.notifier!;
  }
}
