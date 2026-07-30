enum BpMonitorCaptureEventType {
  captureStarted,
  captureStopped,
  scanning,
  deviceDetected,
  connecting,
  connected,
  notificationsEnabled,
  disconnected,
  bleError,
}

extension BpMonitorCaptureEventTypeName on BpMonitorCaptureEventType {
  String get exportName => switch (this) {
    BpMonitorCaptureEventType.captureStarted => 'capture_started',
    BpMonitorCaptureEventType.captureStopped => 'capture_stopped',
    BpMonitorCaptureEventType.scanning => 'scanning',
    BpMonitorCaptureEventType.deviceDetected => 'device_detected',
    BpMonitorCaptureEventType.connecting => 'connecting',
    BpMonitorCaptureEventType.connected => 'connected',
    BpMonitorCaptureEventType.notificationsEnabled => 'notifications_enabled',
    BpMonitorCaptureEventType.disconnected => 'disconnected',
    BpMonitorCaptureEventType.bleError => 'ble_error',
  };
}

class BpMonitorCaptureEvent {
  const BpMonitorCaptureEvent({
    required this.index,
    required this.timestamp,
    required this.type,
    required this.details,
  });

  final int index;
  final DateTime timestamp;
  final BpMonitorCaptureEventType type;
  final String details;

  Map<String, Object> toJson() {
    return {
      'index': index,
      'timestamp': timestamp.toIso8601String(),
      'type': type.exportName,
      'details': details,
    };
  }
}
