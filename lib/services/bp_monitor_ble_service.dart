import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../decoders/yk_ibpa1_packet_decoder.dart';
import '../models/bp_monitor_capture_event.dart';
import '../models/bp_monitor_device.dart';
import '../models/bp_monitor_packet.dart';
import '../models/bp_monitor_result.dart';

enum BpMonitorPermissionState {
  unknown,
  required,
  granted,
  denied,
  permanentlyDenied,
}

enum BpMonitorBleStage {
  initializing,
  unsupported,
  bluetoothOff,
  permissionRequired,
  ready,
  scanning,
  deviceDetected,
  connecting,
  connected,
  listening,
  measurementInProgress,
  resultReceived,
  measurementFailed,
  packetReceived,
  monitorNotFound,
  disconnected,
  error,
}

enum BpMonitorMeasurementState {
  waitingForMonitor,
  ready,
  inProgress,
  resultReceived,
  failed,
}

class BpMonitorBleService extends ChangeNotifier {
  BpMonitorBleService({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const monitorName = 'YK-IBPA1';
  static const serviceUuid = 'cdeacd80-5235-4c07-8846-93a37ee6b86d';
  static const notificationCharacteristicUuid =
      'cdeacd81-5235-4c07-8846-93a37ee6b86d';

  static const _savedIdKey = 'bp_monitor_saved_remote_id';
  static const _savedNameKey = 'bp_monitor_saved_name';
  static const _setupVerifiedKey = 'bp_monitor_setup_verified';
  static const _autoConnectKey = 'bp_monitor_auto_connect';
  static const _scanTimeout = Duration(seconds: 12);
  static const _scanRestartDelay = Duration(seconds: 5);
  static const _duplicateResultWindow = Duration(seconds: 30);
  static const measurementResultTimeout = Duration(minutes: 3);
  static const _platformChannel = MethodChannel('evercare/android_platform');

  SharedPreferencesAsync? _preferences;
  final YkIbpa1PacketDecoder _decoder = const YkIbpa1PacketDecoder();
  final StreamController<BpMonitorPacket> _packetController =
      StreamController<BpMonitorPacket>.broadcast(sync: true);
  final Map<String, BluetoothDevice> _nativeDevices = {};
  final Map<String, BpMonitorDevice> _matchingDevices = {};
  final List<BpMonitorPacket> _packets = [];
  final List<BpMonitorCaptureEvent> _captureEvents = [];
  final Set<Object> _activeClients = HashSet<Object>.identity();

  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _scanningSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  Timer? _autoScanTimer;
  Timer? _measurementTimeoutTimer;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _notificationCharacteristic;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BpMonitorPermissionState _permissionState = BpMonitorPermissionState.unknown;
  BpMonitorBleStage _stage = BpMonitorBleStage.initializing;

  String? _savedIdentifier;
  String? _savedName;
  String? _lastError;
  String _statusMessage = 'Preparing Bluetooth checks...';
  DateTime? _captureStartTime;
  DateTime? _captureEndTime;
  DateTime? _lastConnectedAt;
  DateTime? _measurementStartedAt;
  DateTime? _measurementCompletedAt;
  DateTime? _lastAcceptedResultAt;
  int? _androidSdkInt;
  int? _latestProgressPressure;
  int _nextPacketIndex = 1;
  int _nextMeasurementPacketIndex = 1;
  int _nextCaptureEventIndex = 1;
  int _connectionAttemptId = 0;
  bool _supported = false;
  bool _initialized = false;
  bool _closed = false;
  bool _ownsScan = false;
  bool _connecting = false;
  bool _connectionCancellationPending = false;
  bool _preparingNotifications = false;
  bool _manualDisconnect = false;
  bool _connectWhenDiscovered = false;
  bool _autoReconnectPaused = false;
  bool _autoConnect = true;
  bool _isScanning = false;
  bool _captureActive = false;
  bool _hasSeenProgressStructure = false;
  bool _appInForeground = true;
  bool _savedMonitorVerified = false;
  BpMonitorMeasurementState _measurementState =
      BpMonitorMeasurementState.waitingForMonitor;
  BpMonitorResult? _currentResult;
  List<int>? _lastAcceptedResultBytes;
  String? _lastAcceptedResultDeviceIdentifier;
  String? _measurementFailureMessage;

  Stream<BpMonitorPacket> get packetStream => _packetController.stream;
  UnmodifiableListView<BpMonitorPacket> get packets =>
      UnmodifiableListView<BpMonitorPacket>(_packets);
  UnmodifiableListView<BpMonitorCaptureEvent> get captureEvents =>
      UnmodifiableListView<BpMonitorCaptureEvent>(_captureEvents);
  UnmodifiableListView<BpMonitorDevice> get matchingDevices =>
      UnmodifiableListView<BpMonitorDevice>(
        _matchingDevices.values.toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi)),
      );

  BpMonitorBleStage get stage => _stage;
  BpMonitorMeasurementState get measurementState => _measurementState;
  BpMonitorPermissionState get permissionState => _permissionState;
  BluetoothAdapterState get adapterState => _adapterState;
  bool get isSupported => _supported;
  bool get isScanning => _isScanning;
  bool get isConnecting => _connecting || _connectionCancellationPending;
  bool get isCancellingConnection => _connectionCancellationPending;
  bool get isConnected => _connectedDevice?.isConnected ?? false;
  bool get isListening =>
      isConnected && _notificationCharacteristic?.isNotifying == true;
  bool get autoConnect => _autoConnect;
  bool get autoReconnectActive =>
      _autoConnect && !_autoReconnectPaused && hasSavedMonitor;
  bool get captureActive => _captureActive;
  bool get hasCaptureSession =>
      _captureStartTime != null ||
      _packets.isNotEmpty ||
      _captureEvents.isNotEmpty;
  String? get savedIdentifier => _savedIdentifier;
  String? get savedName => _savedName;
  String? get lastError => _lastError;
  String get statusMessage => _statusMessage;
  DateTime? get captureStartTime => _captureStartTime;
  DateTime? get captureEndTime => _captureEndTime;
  DateTime? get lastConnectedAt => _lastConnectedAt;
  DateTime? get measurementStartedAt => _measurementStartedAt;
  DateTime? get measurementCompletedAt => _measurementCompletedAt;
  int? get latestProgressPressure => _latestProgressPressure;
  BpMonitorResult? get currentResult => _currentResult;
  String? get measurementFailureMessage => _measurementFailureMessage;
  bool get hasFinalResult => _currentResult != null;
  bool get isMeasurementInProgress =>
      _measurementState == BpMonitorMeasurementState.inProgress;
  bool get hasActiveClient => _activeClients.isNotEmpty;
  int get totalPacketCount => _packets.length;
  int get highlightedPacketCount =>
      _packets.where((packet) => packet.isHighlighted).length;
  int get uniquePacketStructureCount =>
      _packets.map((packet) => packet.structureSignature).toSet().length;
  BpMonitorPacket? get firstPacket => _packets.isEmpty ? null : _packets.first;
  BpMonitorPacket? get lastPacket => _packets.isEmpty ? null : _packets.last;
  String? get connectedIdentifier => _connectedDevice?.remoteId.str;
  String? get connectedName {
    final device = _connectedDevice;
    if (device == null) return null;
    return _bestName(device, fallback: _savedName);
  }

  bool get hasSavedMonitor => _savedIdentifier != null;
  bool get isSavedMonitorVerified => hasSavedMonitor && _savedMonitorVerified;
  bool get canOpenSettings =>
      _permissionState == BpMonitorPermissionState.permanentlyDenied;

  SharedPreferencesAsync get _preferenceStore =>
      _preferences ??= SharedPreferencesAsync();

  String get adapterStatusLabel => switch (_adapterState) {
    BluetoothAdapterState.on => 'Bluetooth on',
    BluetoothAdapterState.off => 'Bluetooth off',
    BluetoothAdapterState.turningOn => 'Turning on',
    BluetoothAdapterState.turningOff => 'Turning off',
    BluetoothAdapterState.unauthorized => 'Bluetooth unauthorized',
    BluetoothAdapterState.unavailable => 'Bluetooth unavailable',
    BluetoothAdapterState.unknown => 'Checking Bluetooth',
  };

  String get permissionStatusLabel => switch (_permissionState) {
    BpMonitorPermissionState.unknown => 'Not checked',
    BpMonitorPermissionState.required => 'Permission required',
    BpMonitorPermissionState.granted => 'Granted',
    BpMonitorPermissionState.denied => 'Denied',
    BpMonitorPermissionState.permanentlyDenied =>
      'Permanently denied - open settings',
  };

  String get scanStatusLabel {
    if (_isScanning) return 'Searching for $monitorName';
    if (_matchingDevices.isNotEmpty) {
      return '${_matchingDevices.length} matching monitor(s) detected';
    }
    return 'Not scanning';
  }

  String get connectionStatusLabel {
    if (_connectionCancellationPending) return 'Canceling connection';
    if (_connecting) return 'Connecting';
    if (isListening) return 'Listening for measurement';
    if (isConnected) return 'Connected';
    return 'Disconnected';
  }

  Duration get measurementElapsed {
    final start = _measurementStartedAt;
    if (start == null) return Duration.zero;
    final end = _measurementCompletedAt ?? DateTime.now();
    final elapsed = end.difference(start);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  void attachClient(Object client) {
    if (_closed || !_activeClients.add(client)) return;
    // Screens attach from didChangeDependencies/didUpdateWidget. Deferring the
    // initialization avoids notifying the InheritedNotifier during a build.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_closed || !_activeClients.contains(client)) return;
      unawaited(initialize());
      _scheduleAutoScan(immediate: true);
    });
  }

  void detachClient(Object client) {
    if (_closed || !_activeClients.remove(client)) return;
    if (_activeClients.isNotEmpty) return;

    _autoScanTimer?.cancel();
    if (_isScanning) unawaited(stopScan());
  }

  void setAppInForeground(bool isForeground) {
    if (_closed || _appInForeground == isForeground) return;
    _appInForeground = isForeground;
    if (!isForeground) {
      _autoScanTimer?.cancel();
      if (_isScanning) unawaited(stopScan());
      return;
    }

    // Re-check permission after returning from Android app settings. A user
    // may have granted a previously permanent denial while EverCare was away.
    if (_isAndroid && _androidSdkInt != null) {
      unawaited(refreshPermissionStatus());
    }
    _scheduleAutoScan(immediate: true);
  }

  /// Clears only the live measurement shown to the caregiver.
  ///
  /// The selected monitor, BLE connection, and development capture remain
  /// untouched. The next progress packet begins a new physical session.
  void prepareForNextMeasurement() {
    if (_closed) return;
    _resetCurrentMeasurement();
    _measurementState = isListening
        ? BpMonitorMeasurementState.ready
        : BpMonitorMeasurementState.waitingForMonitor;
    _statusMessage = isListening
        ? 'Ready — press Start on the physical monitor.'
        : 'Connect the saved monitor before starting another measurement.';
    _notifySafely();
  }

  void clearCurrentResult() {
    if (_closed) return;
    _resetCurrentMeasurement();
    _measurementState = isListening
        ? BpMonitorMeasurementState.ready
        : BpMonitorMeasurementState.waitingForMonitor;
    _statusMessage = isListening
        ? 'Current result cleared. Ready for the physical monitor.'
        : 'Current result cleared.';
    _notifySafely();
  }

  void startNewCapture() {
    if (_closed) return;
    _packets.clear();
    _captureEvents.clear();
    _nextPacketIndex = 1;
    _nextCaptureEventIndex = 1;
    _hasSeenProgressStructure = false;
    _captureStartTime = DateTime.now();
    _captureEndTime = null;
    _captureActive = true;
    _recordCaptureEvent(
      BpMonitorCaptureEventType.captureStarted,
      'New in-memory capture started.',
    );

    if (_isScanning) {
      _recordCaptureEvent(
        BpMonitorCaptureEventType.scanning,
        'A BLE scan was already active when capture started.',
      );
    }
    if (isConnecting) {
      _recordCaptureEvent(
        BpMonitorCaptureEventType.connecting,
        'A monitor connection attempt was already active.',
      );
    }
    if (isConnected) {
      _recordCaptureEvent(
        BpMonitorCaptureEventType.connected,
        'Monitor was already connected when capture started.',
      );
    }
    if (isListening) {
      _recordCaptureEvent(
        BpMonitorCaptureEventType.notificationsEnabled,
        'Notifications were already enabled when capture started.',
      );
    }

    _statusMessage =
        'Capture active. Every notification will be retained until stopped or disconnected.';
    _notifySafely();
  }

  void stopCapture() {
    _finishCapture('Capture stopped manually.');
  }

  void clearCapture() {
    if (_closed) return;
    _captureActive = false;
    _packets.clear();
    _captureEvents.clear();
    _captureStartTime = null;
    _captureEndTime = null;
    _nextPacketIndex = 1;
    _nextCaptureEventIndex = 1;
    _hasSeenProgressStructure = false;
    _statusMessage = isListening
        ? 'Capture cleared. Notifications remain enabled.'
        : 'Capture cleared.';
    _notifySafely();
  }

  String exportCaptureAsPlainText() {
    final buffer = StringBuffer()
      ..writeln('EVERCARE BLE MONITOR CAPTURE SESSION')
      ..writeln('Development data only - not medically verified')
      ..writeln('Monitor: ${_savedName ?? monitorName}')
      ..writeln('Identifier: ${_savedIdentifier ?? 'Not saved'}')
      ..writeln('Capture start: ${_exportTimestamp(_captureStartTime)}')
      ..writeln('Capture end: ${_exportTimestamp(_captureEndTime)}')
      ..writeln('Capture active: $_captureActive')
      ..writeln('Total packets: $totalPacketCount')
      ..writeln('Unique packet structures: $uniquePacketStructureCount')
      ..writeln('Highlighted packets: $highlightedPacketCount')
      ..writeln()
      ..writeln('CONNECTION EVENTS');

    if (_captureEvents.isEmpty) {
      buffer.writeln('(none)');
    } else {
      for (final event in _captureEvents) {
        buffer.writeln(
          '#${event.index.toString().padLeft(4, '0')} '
          '${event.timestamp.toIso8601String()} '
          '[${event.type.exportName}] ${event.details}',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('RAW NOTIFICATION PACKETS');

    if (_packets.isEmpty) {
      buffer.writeln('(none)');
    } else {
      for (final packet in _packets) {
        buffer
          ..writeln()
          ..writeln(
            '#${packet.index.toString().padLeft(6, '0')} '
            '${packet.receivedAt.toIso8601String()} '
            'length=${packet.length}'
            '${packet.isHighlighted ? ' [HIGHLIGHTED]' : ''}',
          )
          ..writeln('Decimal: ${packet.decimalString}')
          ..writeln('Hex: ${packet.hexadecimalString}');
        if (packet.highlightReasons.isNotEmpty) {
          buffer.writeln('Reasons: ${packet.highlightReasons.join('; ')}');
        }
      }
    }

    return buffer.toString();
  }

  String exportCaptureAsJson() {
    final payload = {
      'application': 'EverCare',
      'captureType': 'raw_ble_blood_pressure_monitor_notifications',
      'medicalVerification': false,
      'monitor': {
        'name': _savedName ?? monitorName,
        'identifier': _savedIdentifier,
      },
      'session': {
        'startTime': _captureStartTime?.toIso8601String(),
        'endTime': _captureEndTime?.toIso8601String(),
        'active': _captureActive,
        'totalPacketCount': totalPacketCount,
        'uniquePacketStructures': uniquePacketStructureCount,
        'highlightedPacketCount': highlightedPacketCount,
      },
      'events': _captureEvents.map((event) => event.toJson()).toList(),
      'packets': _packets.map((packet) => packet.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _exportTimestamp(DateTime? value) {
    return value?.toIso8601String() ?? 'Not recorded';
  }

  Future<void> initialize() async {
    if (_initialized || _closed) return;
    _initialized = true;

    await _loadPreferences();

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _supported = false;
      _setStage(
        BpMonitorBleStage.unsupported,
        'BLE monitor testing is available on an Android physical device.',
      );
      return;
    }

    try {
      _androidSdkInt = await _platformChannel.invokeMethod<int>(
        'getAndroidSdkInt',
      );
      _supported = await FlutterBluePlus.isSupported;
      if (!_supported) {
        _setStage(
          BpMonitorBleStage.unsupported,
          'Bluetooth Low Energy is not supported on this device.',
        );
        return;
      }

      FlutterBluePlus.setOperationQueueMode(OperationQueueMode.perDevice);

      _scanResultsSubscription = FlutterBluePlus.onScanResults.listen(
        _handleScanResults,
        onError: (Object error) => _setError('Scan failed: $error'),
      );
      _scanningSubscription = FlutterBluePlus.isScanning.listen(
        _handleScanningState,
      );
      _adapterSubscription = FlutterBluePlus.adapterState.listen(
        (state) => unawaited(_handleAdapterState(state)),
      );

      await refreshPermissionStatus();
    } catch (error) {
      _setError('Unable to initialize Bluetooth: $error');
    }
  }

  Future<void> _loadPreferences() async {
    try {
      _savedIdentifier = await _preferenceStore.getString(_savedIdKey);
      _savedName = await _preferenceStore.getString(_savedNameKey);
      _savedMonitorVerified =
          await _preferenceStore.getBool(_setupVerifiedKey) ?? false;
      _autoConnect = await _preferenceStore.getBool(_autoConnectKey) ?? true;
      _notifySafely();
    } catch (error) {
      _setError('Could not load the saved monitor: $error');
    }
  }

  Future<void> refreshPermissionStatus() async {
    if (_closed || !_isAndroid) return;

    try {
      final permissions = _requiredRuntimePermissions;
      final statuses = await Future.wait(
        permissions.map((permission) => permission.status),
      );

      if (statuses.every((status) => status.isGranted)) {
        _permissionState = BpMonitorPermissionState.granted;
        _lastError = null;
        if (_adapterState == BluetoothAdapterState.on) {
          _setStage(BpMonitorBleStage.ready, 'Ready to scan for the monitor.');
          _scheduleAutoScan(immediate: true);
        } else {
          _notifySafely();
        }
        return;
      }

      if (statuses.any((status) => status.isPermanentlyDenied)) {
        _permissionState = BpMonitorPermissionState.permanentlyDenied;
      } else if (statuses.any((status) => status.isDenied)) {
        _permissionState = BpMonitorPermissionState.required;
      } else {
        _permissionState = BpMonitorPermissionState.denied;
      }
      _setStage(
        BpMonitorBleStage.permissionRequired,
        'Bluetooth permission is required before scanning.',
      );
    } catch (error) {
      _setError('Could not check Bluetooth permissions: $error');
    }
  }

  Future<void> requestPermissions() async {
    if (_closed || !_isAndroid) return;

    try {
      final statuses = await _requiredRuntimePermissions.request();
      final values = statuses.values;
      if (values.every((status) => status.isGranted)) {
        _permissionState = BpMonitorPermissionState.granted;
        _lastError = null;
        _autoReconnectPaused = false;
        _setStage(BpMonitorBleStage.ready, 'Bluetooth permission granted.');
        _scheduleAutoScan(immediate: true);
      } else if (values.any((status) => status.isPermanentlyDenied)) {
        _permissionState = BpMonitorPermissionState.permanentlyDenied;
        _setStage(
          BpMonitorBleStage.permissionRequired,
          'Permission is permanently denied. Open Android settings to allow it.',
        );
      } else {
        _permissionState = BpMonitorPermissionState.denied;
        _setStage(
          BpMonitorBleStage.permissionRequired,
          'Permission was denied. Scanning cannot start yet.',
        );
      }
    } catch (error) {
      _setError('Permission request failed: $error');
    }
  }

  List<Permission> get _requiredRuntimePermissions {
    if ((_androidSdkInt ?? 31) >= 31) {
      return const [Permission.bluetoothScan, Permission.bluetoothConnect];
    }
    return const [Permission.locationWhenInUse];
  }

  Future<bool> openPermissionSettings() => openAppSettings();

  Future<void> startScan({bool manual = true}) async {
    if (_closed || !_initialized) return;
    if (manual) _autoReconnectPaused = false;

    if (!_supported) {
      _setStage(BpMonitorBleStage.unsupported, 'Bluetooth LE is unavailable.');
      return;
    }
    if (_adapterState != BluetoothAdapterState.on) {
      _setStage(
        BpMonitorBleStage.bluetoothOff,
        'Turn on Bluetooth, then try scanning again.',
      );
      return;
    }
    if (_permissionState != BpMonitorPermissionState.granted) {
      _setStage(
        BpMonitorBleStage.permissionRequired,
        'Grant Bluetooth permission before scanning.',
      );
      return;
    }
    if (isConnecting || isConnected) return;
    if (_isScanning || FlutterBluePlus.isScanningNow) {
      _statusMessage = 'A monitor scan is already running.';
      _notifySafely();
      return;
    }

    _autoScanTimer?.cancel();
    // Every scan starts with a fresh discovery set. Retaining a device object
    // from an earlier advertisement can make a powered-off monitor appear to
    // have been detected during the current scan.
    _matchingDevices.clear();
    _nativeDevices.clear();

    try {
      _ownsScan = true;
      _setStage(
        BpMonitorBleStage.scanning,
        hasSavedMonitor
            ? 'Searching for the saved $monitorName monitor...'
            : 'Searching for $monitorName... Turn on the monitor now.',
      );
      await FlutterBluePlus.startScan(
        withRemoteIds: _savedIdentifier == null
            ? const []
            : [_savedIdentifier!],
        timeout: _scanTimeout,
        androidUsesFineLocation: (_androidSdkInt ?? 31) < 31,
        androidCheckLocationServices: (_androidSdkInt ?? 31) < 31,
      );
    } catch (error) {
      _ownsScan = false;
      _setError('Could not start the BLE scan: $error');
      _scheduleAutoScan();
    }
  }

  Future<void> stopScan() async {
    _autoScanTimer?.cancel();
    if (!_ownsScan || !FlutterBluePlus.isScanningNow) return;
    try {
      await FlutterBluePlus.stopScan();
    } catch (error) {
      _setError('Could not stop the BLE scan: $error');
    } finally {
      _ownsScan = false;
    }
  }

  void _handleScanResults(List<ScanResult> results) {
    if (_closed) return;

    var changed = false;
    BluetoothDevice? savedDevice;

    for (final result in results) {
      final device = result.device;
      final identifier = device.remoteId.str;
      final advertisedName = result.advertisementData.advName.trim();
      final platformName = device.platformName.trim();
      final isSaved = identifier == _savedIdentifier;
      final nameMatches =
          advertisedName.toUpperCase() == monitorName ||
          platformName.toUpperCase() == monitorName;
      final serviceMatches = result.advertisementData.serviceUuids.any(
        (uuid) => uuid == Guid(serviceUuid),
      );

      if (!isSaved && !nameMatches && !serviceMatches) continue;

      final displayName = advertisedName.isNotEmpty
          ? advertisedName
          : platformName.isNotEmpty
          ? platformName
          : _savedName ?? monitorName;
      _nativeDevices[identifier] = device;
      final previous = _matchingDevices[identifier];
      final candidate = BpMonitorDevice(
        identifier: identifier,
        name: displayName,
        rssi: result.rssi,
      );
      if (previous == null ||
          previous.name != candidate.name ||
          previous.rssi != candidate.rssi) {
        _matchingDevices[identifier] = candidate;
        changed = true;
      }

      if (isSaved) savedDevice = device;
    }

    if (changed && !isConnecting && !isConnected) {
      _setStage(
        BpMonitorBleStage.deviceDetected,
        'Monitor detected. Select it to save and connect.',
      );
    }

    final manualConnectionPending = _connectWhenDiscovered;
    final shouldAutoConnect = _autoConnect && !_autoReconnectPaused;
    if (savedDevice != null &&
        (manualConnectionPending || shouldAutoConnect) &&
        !isConnecting &&
        !isConnected) {
      _connectWhenDiscovered = false;
      unawaited(
        _connectDevice(savedDevice, automatic: !manualConnectionPending),
      );
    }
  }

  void _handleScanningState(bool scanning) {
    if (_closed) return;
    final wasScanning = _isScanning;
    _isScanning = scanning;
    if (!scanning && wasScanning) {
      _ownsScan = false;
      if (!isConnecting && !isConnected) {
        if (_matchingDevices.isEmpty) {
          _connectWhenDiscovered = false;
          _statusMessage = 'Monitor not found during this scan.';
          _stage = BpMonitorBleStage.monitorNotFound;
        } else {
          _stage = BpMonitorBleStage.deviceDetected;
        }
      }
      _scheduleAutoScan();
    }
    _notifySafely();
  }

  Future<void> saveAndConnect(BpMonitorDevice candidate) async {
    if (_closed) return;
    final device = _nativeDevices[candidate.identifier];
    if (device == null) {
      _setError('The selected monitor is no longer available. Scan again.');
      return;
    }

    try {
      await _preferenceStore.setString(_savedIdKey, candidate.identifier);
      await _preferenceStore.setString(_savedNameKey, candidate.name);
      await _preferenceStore.setBool(_setupVerifiedKey, false);
      _savedIdentifier = candidate.identifier;
      _savedName = candidate.name;
      _savedMonitorVerified = false;
      _autoReconnectPaused = false;
      _notifySafely();
      await _connectDevice(device);
    } catch (error) {
      _setError('Could not save the selected monitor: $error');
    }
  }

  Future<void> connectSavedMonitor() async {
    if (_closed) return;
    _autoReconnectPaused = false;
    final identifier = _savedIdentifier;
    if (identifier == null) {
      _statusMessage = 'Scan and select a monitor before connecting.';
      _notifySafely();
      return;
    }

    final discoveredDevice = _nativeDevices[identifier];
    if (discoveredDevice != null) {
      await _connectDevice(discoveredDevice);
      return;
    }

    _statusMessage = 'Searching for the saved monitor before connecting...';
    _connectWhenDiscovered = true;
    _notifySafely();
    await startScan();
  }

  Future<void> retryNotificationSetup() async {
    if (_closed) return;
    final device = _connectedDevice;
    if (device == null || !device.isConnected) {
      await connectSavedMonitor();
      return;
    }

    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _notificationCharacteristic = null;
    _preparingNotifications = false;
    _setStage(
      BpMonitorBleStage.connected,
      'Connected. Retrying the measurement listener...',
    );
    await _prepareNotifications(device);
  }

  Future<void> _connectDevice(
    BluetoothDevice device, {
    bool automatic = false,
  }) async {
    if (_closed || isConnecting || isConnected) return;
    final attemptId = ++_connectionAttemptId;
    _connecting = true;
    _manualDisconnect = false;
    _autoScanTimer?.cancel();

    try {
      await stopScan();
      if (!_isConnectionAttemptActive(attemptId)) return;
      await _cancelDeviceSubscriptions();
      if (!_isConnectionAttemptActive(attemptId)) return;
      _connectedDevice = device;
      _connectionSubscription = device.connectionState.listen(
        (state) => unawaited(_handleConnectionState(device, state)),
      );

      _setStage(
        BpMonitorBleStage.connecting,
        automatic
            ? 'Saved monitor detected. Connecting automatically...'
            : 'Connecting to ${_bestName(device, fallback: _savedName)}...',
      );

      if (!device.isConnected) {
        await device.connect(
          license: License.nonprofit,
          timeout: const Duration(seconds: 25),
        );
      }
      if (!_isConnectionAttemptActive(attemptId) ||
          device.remoteId != _connectedDevice?.remoteId) {
        if (device.isConnected) {
          await device.disconnect(queue: false, androidDelay: 0);
        }
        return;
      }
      if (device.isConnected) {
        await _prepareNotifications(device);
      }
    } catch (error) {
      if (_isConnectionAttemptActive(attemptId)) {
        _setError('Connection failed: $error');
        _scheduleAutoScan();
      }
    } finally {
      if (attemptId == _connectionAttemptId) {
        _connecting = false;
        _notifySafely();
      } else if (_connectionCancellationPending) {
        _connectionCancellationPending = false;
        _notifySafely();
      }
    }
  }

  Future<void> _handleConnectionState(
    BluetoothDevice device,
    BluetoothConnectionState state,
  ) async {
    if (_closed || device.remoteId != _connectedDevice?.remoteId) return;

    switch (state) {
      case BluetoothConnectionState.connected:
        _lastConnectedAt = DateTime.now();
        _setStage(
          BpMonitorBleStage.connected,
          'Connected. Discovering the monitor service...',
        );
        await _prepareNotifications(device);
      case BluetoothConnectionState.disconnected:
        // The connection stream re-emits its current disconnected state as soon
        // as it is subscribed. The direct connect call owns failures until the
        // monitor has actually reached the connected stage.
        if (_connecting && _stage == BpMonitorBleStage.connecting) return;
        await _notificationSubscription?.cancel();
        _notificationSubscription = null;
        _notificationCharacteristic = null;
        _preparingNotifications = false;
        _connecting = false;
        _failActiveMeasurement(
          'No final result was received before the monitor disconnected.',
        );
        _setStage(
          BpMonitorBleStage.disconnected,
          _manualDisconnect
              ? 'Monitor disconnected.'
              : 'Monitor disconnected unexpectedly. Waiting for it to advertise again.',
        );
        _connectedDevice = null;
        if (!_manualDisconnect) _scheduleAutoScan();
    }
  }

  Future<void> _prepareNotifications(BluetoothDevice device) async {
    if (_closed ||
        _preparingNotifications ||
        !device.isConnected ||
        !_isCurrentConnectedDevice(device)) {
      return;
    }
    if (_notificationCharacteristic?.isNotifying == true) return;
    final connectionAttemptId = _connectionAttemptId;
    _preparingNotifications = true;

    try {
      final services = await device.discoverServices();
      if (!_isNotificationSetupCurrent(device, connectionAttemptId)) return;
      BluetoothService? targetService;
      for (final service in services) {
        if (service.uuid == Guid(serviceUuid)) {
          targetService = service;
          break;
        }
      }
      if (targetService == null) {
        throw StateError('Custom service $serviceUuid was not found.');
      }

      BluetoothCharacteristic? targetCharacteristic;
      for (final characteristic in targetService.characteristics) {
        if (characteristic.uuid == Guid(notificationCharacteristicUuid)) {
          targetCharacteristic = characteristic;
          break;
        }
      }
      if (targetCharacteristic == null) {
        throw StateError(
          'Notification characteristic $notificationCharacteristicUuid was not found.',
        );
      }
      if (!targetCharacteristic.properties.notify &&
          !targetCharacteristic.properties.indicate) {
        throw StateError('The characteristic does not support notifications.');
      }
      if (!_isNotificationSetupCurrent(device, connectionAttemptId)) return;

      await _notificationSubscription?.cancel();
      final subscription = targetCharacteristic.onValueReceived.listen(
        _handlePacket,
        onError: (Object error) =>
            _setError('Notification stream failed: $error'),
      );
      _notificationSubscription = subscription;
      final notificationsEnabled = await targetCharacteristic.setNotifyValue(
        true,
      );
      if (!_isNotificationSetupCurrent(device, connectionAttemptId)) {
        await subscription.cancel();
        if (identical(_notificationSubscription, subscription)) {
          _notificationSubscription = null;
        }
        return;
      }
      if (!notificationsEnabled) {
        throw StateError('The monitor rejected notification setup.');
      }
      _notificationCharacteristic = targetCharacteristic;
      _savedMonitorVerified = true;
      try {
        await _preferenceStore.setBool(_setupVerifiedKey, true);
      } catch (_) {
        // The live BLE listener is still valid if this convenience flag fails
        // to persist; it will be verified again on a future connection.
      }
      if (!_isNotificationSetupCurrent(device, connectionAttemptId)) return;
      if (_measurementState != BpMonitorMeasurementState.inProgress &&
          _measurementState != BpMonitorMeasurementState.resultReceived) {
        _measurementState = BpMonitorMeasurementState.ready;
        _measurementFailureMessage = null;
      }
      _setStage(
        BpMonitorBleStage.listening,
        'Ready — press Start on the physical monitor.',
      );
    } catch (error) {
      if (_isNotificationSetupCurrent(device, connectionAttemptId)) {
        await _notificationSubscription?.cancel();
        _notificationSubscription = null;
        _notificationCharacteristic = null;
        _setError('Could not enable monitor notifications: $error');
      }
    } finally {
      if (connectionAttemptId == _connectionAttemptId) {
        _preparingNotifications = false;
      }
    }
  }

  void _handlePacket(List<int> bytes) {
    if (_closed) return;
    _processNotification(bytes, receivedAt: DateTime.now());
  }

  @visibleForTesting
  void processNotificationForTesting(List<int> bytes, {DateTime? receivedAt}) {
    if (_closed) return;
    _processNotification(bytes, receivedAt: receivedAt ?? DateTime.now());
  }

  void _processNotification(List<int> bytes, {required DateTime receivedAt}) {
    BpMonitorPacket? capturedPacket;
    if (_captureActive) {
      capturedPacket = BpMonitorPacket.fromNotification(
        index: _nextPacketIndex++,
        bytes: bytes,
        receivedAt: receivedAt,
        compareAgainstProgressStructure: _hasSeenProgressStructure,
      );
      if (capturedPacket.matchesKnownProgressStructure) {
        _hasSeenProgressStructure = true;
      }

      // Capture is intentionally append-only. Duplicate notifications are
      // preserved with their individual timestamps for protocol analysis.
      _packets.add(capturedPacket);
      _packetController.add(capturedPacket);
    }

    final progressPressure = _decoder.decodeProgressPressure(bytes);
    if (progressPressure != null) {
      if (_measurementState != BpMonitorMeasurementState.inProgress) {
        _beginDetectedMeasurement(receivedAt);
      }
      _nextMeasurementPacketIndex++;
      _latestProgressPressure = progressPressure;
      _measurementState = BpMonitorMeasurementState.inProgress;
      _measurementFailureMessage = null;
      _setStage(
        BpMonitorBleStage.measurementInProgress,
        'Measurement in progress. Live raw cuff-pressure value: $progressPressure.',
      );
      return;
    }

    final isCompletedPacket =
        bytes.length >= 4 &&
        bytes.first == YkIbpa1PacketDecoder.completedResultPacketType;
    if (isCompletedPacket) {
      final deviceIdentifier =
          connectedIdentifier ?? savedIdentifier ?? 'unsaved-monitor';
      final deviceName = connectedName ?? savedName ?? monitorName;
      if (_isDuplicateVisibleResult(
        bytes: bytes,
        deviceIdentifier: deviceIdentifier,
        receivedAt: receivedAt,
      )) {
        _statusMessage =
            'A repeated result packet was received. The visible reading was kept once.';
        _notifySafely();
        return;
      }

      if (_measurementState != BpMonitorMeasurementState.inProgress) {
        _beginDetectedMeasurement(receivedAt);
      }
      final result = _decoder.decodeCompletedResult(
        bytes: bytes,
        receivedAt: receivedAt,
        packetIndex: _nextMeasurementPacketIndex++,
        deviceIdentifier: deviceIdentifier,
        deviceName: deviceName,
      );
      if (result != null) {
        _measurementTimeoutTimer?.cancel();
        _currentResult = result;
        _measurementCompletedAt = receivedAt;
        _measurementState = BpMonitorMeasurementState.resultReceived;
        _measurementFailureMessage = null;
        _lastAcceptedResultAt = receivedAt;
        _lastAcceptedResultBytes = List<int>.from(bytes);
        _lastAcceptedResultDeviceIdentifier = deviceIdentifier;
        _setStage(
          BpMonitorBleStage.resultReceived,
          'Blood-pressure result received directly from $deviceName.',
        );
        return;
      }
    }

    // Unknown and short packets remain available in an active development
    // capture, but never become a caregiver-facing result.
    if (capturedPacket != null) {
      _notifySafely();
    }
  }

  void _beginDetectedMeasurement(DateTime startedAt) {
    _resetCurrentMeasurement(clearDeduplication: true);
    _measurementStartedAt = startedAt;
    _measurementState = BpMonitorMeasurementState.inProgress;
    _measurementTimeoutTimer = Timer(measurementResultTimeout, () {
      if (_closed ||
          _measurementState != BpMonitorMeasurementState.inProgress ||
          _measurementStartedAt != startedAt) {
        return;
      }
      _measurementCompletedAt = DateTime.now();
      _measurementState = BpMonitorMeasurementState.failed;
      _measurementFailureMessage =
          'No final 0x81 result was received within three minutes.';
      _setStage(
        BpMonitorBleStage.measurementFailed,
        'Measurement failed. No final result was received. Try again when the patient is ready.',
      );
    });
  }

  bool _isDuplicateVisibleResult({
    required List<int> bytes,
    required String deviceIdentifier,
    required DateTime receivedAt,
  }) {
    final previousAt = _lastAcceptedResultAt;
    final previousBytes = _lastAcceptedResultBytes;
    if (previousAt == null || previousBytes == null) return false;

    final elapsed = receivedAt.difference(previousAt);
    return !elapsed.isNegative &&
        elapsed <= _duplicateResultWindow &&
        _lastAcceptedResultDeviceIdentifier == deviceIdentifier &&
        listEquals(previousBytes, bytes);
  }

  void _resetCurrentMeasurement({bool clearDeduplication = false}) {
    _measurementTimeoutTimer?.cancel();
    _measurementTimeoutTimer = null;
    _currentResult = null;
    _latestProgressPressure = null;
    _measurementStartedAt = null;
    _measurementCompletedAt = null;
    _measurementFailureMessage = null;
    if (clearDeduplication) {
      _lastAcceptedResultAt = null;
      _lastAcceptedResultBytes = null;
      _lastAcceptedResultDeviceIdentifier = null;
    }
    _nextMeasurementPacketIndex = 1;
  }

  void _failActiveMeasurement(String message) {
    if (_measurementState != BpMonitorMeasurementState.inProgress ||
        _currentResult != null) {
      return;
    }
    _measurementTimeoutTimer?.cancel();
    _measurementTimeoutTimer = null;
    _measurementState = BpMonitorMeasurementState.failed;
    _measurementCompletedAt = DateTime.now();
    _measurementFailureMessage = message;
  }

  Future<void> disconnect() async {
    if (_closed) return;
    final wasConnecting = _connecting;
    _manualDisconnect = true;
    _connectionAttemptId++;
    _connectWhenDiscovered = false;
    _autoReconnectPaused = true;
    _connecting = false;
    _connectionCancellationPending = wasConnecting;
    _preparingNotifications = false;
    _autoScanTimer?.cancel();
    await stopScan();

    final device = _connectedDevice;
    _connectedDevice = null;
    await _cancelDeviceSubscriptions();

    try {
      if (device?.isConnected == true) {
        await device!.disconnect();
      } else if (device != null && wasConnecting) {
        try {
          await device.disconnect(queue: false, androidDelay: 0);
        } catch (_) {
          // The in-flight connect owns completion. Its attempt token will
          // disconnect the device if it connects after this cancellation.
        }
      }
      _failActiveMeasurement(
        'No final result was received before the monitor was disconnected.',
      );
      _setStage(BpMonitorBleStage.disconnected, 'Monitor disconnected.');
    } catch (error) {
      _setError('Disconnect failed: $error');
    }
  }

  Future<void> forgetSavedMonitor() async {
    if (_closed) return;
    await disconnect();
    try {
      await _preferenceStore.remove(_savedIdKey);
      await _preferenceStore.remove(_savedNameKey);
      await _preferenceStore.remove(_setupVerifiedKey);
      _savedIdentifier = null;
      _savedName = null;
      _savedMonitorVerified = false;
      _connectWhenDiscovered = false;
      _matchingDevices.clear();
      _nativeDevices.clear();
      _resetCurrentMeasurement(clearDeduplication: true);
      _measurementState = BpMonitorMeasurementState.waitingForMonitor;
      _setStage(
        BpMonitorBleStage.ready,
        'Saved monitor forgotten. Scan to select a monitor again.',
      );
    } catch (error) {
      _setError('Could not forget the saved monitor: $error');
    }
  }

  Future<void> setAutoConnect(bool enabled) async {
    if (_closed) return;
    _autoConnect = enabled;
    _autoReconnectPaused = !enabled;
    await _preferenceStore.setBool(_autoConnectKey, enabled);
    if (enabled) {
      _scheduleAutoScan(immediate: true);
    } else {
      _autoScanTimer?.cancel();
      await stopScan();
    }
    _notifySafely();
  }

  void clearPacketLog() => clearCapture();

  Future<void> _handleAdapterState(BluetoothAdapterState state) async {
    if (_closed) return;
    _adapterState = state;
    if (state != BluetoothAdapterState.on) {
      _autoScanTimer?.cancel();
      await stopScan();
      _failActiveMeasurement(
        'No final result was received because Bluetooth became unavailable.',
      );
      _setStage(
        BpMonitorBleStage.bluetoothOff,
        state == BluetoothAdapterState.off
            ? 'Bluetooth is off. Turn it on to use the monitor.'
            : 'Waiting for the Bluetooth adapter to become available.',
      );
      return;
    }

    await refreshPermissionStatus();
    if (_permissionState == BpMonitorPermissionState.granted) {
      _scheduleAutoScan(immediate: true);
    }
  }

  void _scheduleAutoScan({bool immediate = false}) {
    _autoScanTimer?.cancel();
    if (_closed ||
        !_appInForeground ||
        _activeClients.isEmpty ||
        !_autoConnect ||
        _autoReconnectPaused ||
        !hasSavedMonitor ||
        _adapterState != BluetoothAdapterState.on ||
        _permissionState != BpMonitorPermissionState.granted ||
        isConnecting ||
        isConnected ||
        _isScanning) {
      return;
    }
    _autoScanTimer = Timer(
      immediate ? Duration.zero : _scanRestartDelay,
      () => unawaited(startScan(manual: false)),
    );
  }

  Future<void> _cancelDeviceSubscriptions() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _notificationCharacteristic = null;
  }

  bool _isConnectionAttemptActive(int attemptId) {
    return !_closed && !_manualDisconnect && attemptId == _connectionAttemptId;
  }

  bool _isCurrentConnectedDevice(BluetoothDevice device) {
    return !_closed &&
        !_manualDisconnect &&
        device.remoteId == _connectedDevice?.remoteId;
  }

  bool _isNotificationSetupCurrent(
    BluetoothDevice device,
    int connectionAttemptId,
  ) {
    return connectionAttemptId == _connectionAttemptId &&
        _isCurrentConnectedDevice(device) &&
        device.isConnected;
  }

  String _bestName(BluetoothDevice device, {String? fallback}) {
    final platformName = device.platformName.trim();
    if (platformName.isNotEmpty) return platformName;
    final advertisedName = device.advName.trim();
    if (advertisedName.isNotEmpty) return advertisedName;
    return fallback?.trim().isNotEmpty == true ? fallback!.trim() : monitorName;
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _setStage(BpMonitorBleStage stage, String message) {
    if (_closed) return;
    _stage = stage;
    _statusMessage = message;
    if (stage != BpMonitorBleStage.error) _lastError = null;

    final captureEventType = switch (stage) {
      BpMonitorBleStage.scanning => BpMonitorCaptureEventType.scanning,
      BpMonitorBleStage.deviceDetected =>
        BpMonitorCaptureEventType.deviceDetected,
      BpMonitorBleStage.connecting => BpMonitorCaptureEventType.connecting,
      BpMonitorBleStage.connected => BpMonitorCaptureEventType.connected,
      BpMonitorBleStage.listening =>
        BpMonitorCaptureEventType.notificationsEnabled,
      BpMonitorBleStage.disconnected => BpMonitorCaptureEventType.disconnected,
      _ => null,
    };
    if (captureEventType != null) {
      _recordCaptureEvent(captureEventType, message);
    }
    if (stage == BpMonitorBleStage.disconnected && _captureActive) {
      _finishCapture(
        'Capture ended because the monitor disconnected.',
        updateStatus: false,
      );
    }
    _notifySafely();
  }

  void _setError(String message) {
    if (_closed) return;
    _failActiveMeasurement(message);
    _stage = BpMonitorBleStage.error;
    _lastError = message;
    _statusMessage = message;
    _recordCaptureEvent(BpMonitorCaptureEventType.bleError, message);
    _notifySafely();
  }

  void _recordCaptureEvent(BpMonitorCaptureEventType type, String details) {
    if (!_captureActive) return;
    final previous = _captureEvents.isEmpty ? null : _captureEvents.last;
    if (previous?.type == type && previous?.details == details) return;

    _captureEvents.add(
      BpMonitorCaptureEvent(
        index: _nextCaptureEventIndex++,
        timestamp: DateTime.now(),
        type: type,
        details: details,
      ),
    );
  }

  void _finishCapture(String reason, {bool updateStatus = true}) {
    if (!_captureActive) return;
    _recordCaptureEvent(BpMonitorCaptureEventType.captureStopped, reason);
    _captureEndTime = DateTime.now();
    _captureActive = false;
    if (updateStatus) _statusMessage = reason;
    _notifySafely();
  }

  void _notifySafely() {
    if (!_closed) notifyListeners();
  }

  Future<void> close() async {
    if (_closed) return;
    _connectionAttemptId++;
    _measurementTimeoutTimer?.cancel();
    _measurementTimeoutTimer = null;
    _closed = true;
    _finishCapture('Capture ended because the application BLE service closed.');
    _activeClients.clear();
    _autoScanTimer?.cancel();

    if (_ownsScan && FlutterBluePlus.isScanningNow) {
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {
        // Best-effort cleanup while the page is closing.
      }
    }

    final device = _connectedDevice;
    if (device?.isConnected == true) {
      try {
        await device!.disconnect(queue: false, androidDelay: 0);
      } catch (_) {
        // Best-effort cleanup while the page is closing.
      }
    }

    await _adapterSubscription?.cancel();
    await _scanResultsSubscription?.cancel();
    await _scanningSubscription?.cancel();
    await _cancelDeviceSubscriptions();
    await _packetController.close();
    super.dispose();
  }
}
