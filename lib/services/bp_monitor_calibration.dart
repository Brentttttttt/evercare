/// App-side calibration for the supported YK-IBPA1 BLE monitor.
///
/// The physical monitor and its packet protocol are left unchanged. EverCare
/// preserves the raw packet value and applies this configured offset only to
/// newly decoded BLE systolic results. Manual entries are never adjusted.
abstract final class BpMonitorCalibration {
  static const int ykIbpa1SystolicOffsetMmHg = -10;
  static const String version = 'yk_ibpa1_systolic_minus_10_v1';

  /// A raw value of 10 or below cannot produce a positive corrected reading.
  /// It is rejected instead of inventing a clamped health measurement.
  static bool canApplyYkIbpa1SystolicCorrection(int rawSystolic) =>
      rawSystolic > -ykIbpa1SystolicOffsetMmHg;

  static int applyYkIbpa1SystolicCorrection(int rawSystolic) {
    if (!canApplyYkIbpa1SystolicCorrection(rawSystolic)) {
      throw ArgumentError.value(
        rawSystolic,
        'rawSystolic',
        'Cannot apply the YK-IBPA1 systolic correction safely.',
      );
    }
    return rawSystolic + ykIbpa1SystolicOffsetMmHg;
  }
}
