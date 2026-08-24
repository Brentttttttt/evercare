import 'package:evercare/services/bp_monitor_calibration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies the configured minus-10 systolic correction once', () {
    expect(BpMonitorCalibration.applyYkIbpa1SystolicCorrection(140), 130);
  });

  test('rejects a raw result that would become non-positive', () {
    expect(BpMonitorCalibration.canApplyYkIbpa1SystolicCorrection(10), isFalse);
    expect(
      () => BpMonitorCalibration.applyYkIbpa1SystolicCorrection(10),
      throwsArgumentError,
    );
  });
}
