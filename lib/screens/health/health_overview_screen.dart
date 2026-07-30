import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'
    show BluetoothAdapterState;

import '../../models/bp_monitor_device.dart';
import '../../models/bp_monitor_result.dart';
import '../../routes/app_route_observer.dart';
import '../../routes/app_routes.dart';
import '../../services/bp_monitor_ble_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/bp_monitor_ble_scope.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/section_header.dart';

class HealthOverviewScreen extends StatefulWidget {
  const HealthOverviewScreen({this.isActive = true, super.key});

  /// The main shell uses an IndexedStack, so mounting alone does not mean the
  /// Health tab is visible. Auto-scan is leased only while this is true.
  final bool isActive;

  @override
  State<HealthOverviewScreen> createState() => _HealthOverviewScreenState();
}

class _HealthOverviewScreenState extends State<HealthOverviewScreen>
    with RouteAware {
  BpMonitorBleService? _service;
  PageRoute<dynamic>? _pageRoute;
  bool _attached = false;
  bool _routeVisible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && !identical(route, _pageRoute)) {
      if (_pageRoute != null) everCareRouteObserver.unsubscribe(this);
      _pageRoute = route;
      _routeVisible = route.isCurrent;
      everCareRouteObserver.subscribe(this, route);
    }
    final service = BpMonitorBleScope.read(context);
    if (!identical(service, _service)) {
      if (_attached) _service?.detachClient(this);
      _service = service;
      _attached = false;
    }
    _syncClientLease();
  }

  @override
  void didUpdateWidget(covariant HealthOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) _syncClientLease();
  }

  void _syncClientLease() {
    final service = _service;
    if (service == null) return;
    final shouldAttach = widget.isActive && _routeVisible;
    if (shouldAttach && !_attached) {
      service.attachClient(this);
      _attached = true;
    } else if (!shouldAttach && _attached) {
      service.detachClient(this);
      _attached = false;
    }
  }

  @override
  void didPush() {
    _routeVisible = true;
    _syncClientLease();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _syncClientLease();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _syncClientLease();
  }

  @override
  void dispose() {
    if (_pageRoute != null) everCareRouteObserver.unsubscribe(this);
    if (_attached) _service?.detachClient(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = BpMonitorBleScope.watch(context);
    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CarePhotoBanner(
            assetPath: 'assets/images/bp_monitor_home.png',
            semanticLabel:
                'A caregiver helping an older adult use an upper-arm blood pressure monitor',
            title: 'Measure with confidence',
            subtitle:
                'Connect the real monitor and keep the patient calm and still.',
            height: 170,
          ),
          const SizedBox(height: 20),
          _MonitorConnectionCard(service: service),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Measurement instructions'),
          const SizedBox(height: 12),
          const _MeasurementInstructionsCard(),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Live measurement status'),
          const SizedBox(height: 12),
          _LiveMeasurementCard(service: service),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Completed reading'),
          const SizedBox(height: 12),
          if (service.currentResult case final result?)
            _CompletedReadingCard(result: result)
          else
            const _NoResultCard(),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Current session'),
          const SizedBox(height: 12),
          _CurrentSessionCard(service: service),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Reading history'),
          const SizedBox(height: 12),
          const AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  color: AppColors.secondaryText,
                  size: 27,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No real monitor readings have been saved yet.',
                        style: AppTextStyles.cardTitle,
                      ),
                      SizedBox(height: 5),
                      Text(
                        'The real BLE reading stays only in the current app session. Database history is not enabled in this phase.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.manualRecord),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Enter Blood Pressure Manually'),
          ),
          const SizedBox(height: 24),
          const _SafetyNotice(),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.deviceConnection),
                icon: const Icon(Icons.science_outlined),
                label: const Text('Open BLE Diagnostics'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonitorConnectionCard extends StatelessWidget {
  const _MonitorConnectionCard({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    final status = _connectionPresentation(service);
    final canUseBluetooth =
        service.adapterState == BluetoothAdapterState.on &&
        service.permissionState == BpMonitorPermissionState.granted;
    final deviceName = service.savedName ?? BpMonitorBleService.monitorName;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(status.icon, color: status.color, size: 29),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deviceName, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 4),
                    Text(
                      service.savedIdentifier ??
                          'No monitor identifier saved yet',
                      style: AppTextStyles.small,
                    ),
                    const SizedBox(height: 8),
                    _StatusPill(label: status.label, color: status.color),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          _ConnectionDetail(
            icon: Icons.bluetooth_rounded,
            label: 'Bluetooth',
            value: service.adapterStatusLabel,
          ),
          _ConnectionDetail(
            icon: Icons.link_rounded,
            label: 'Connection',
            value: status.label,
          ),
          _ConnectionDetail(
            icon: Icons.schedule_rounded,
            label: 'Last connected',
            value: service.lastConnectedAt == null
                ? 'Not connected in this app session'
                : _formatDateTime(service.lastConnectedAt!),
          ),
          _ConnectionDetail(
            icon: Icons.battery_unknown_rounded,
            label: 'Monitor battery',
            value: 'Battery level unavailable.',
          ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: service.autoConnect,
              onChanged: service.hasSavedMonitor
                  ? service.setAutoConnect
                  : null,
              secondary: const Icon(
                Icons.autorenew_rounded,
                color: AppColors.primaryGreen,
              ),
              title: const Text(
                'Automatic reconnection',
                style: AppTextStyles.label,
              ),
              subtitle: Text(
                service.autoReconnectActive
                    ? 'On — searches for the saved monitor while this page is active.'
                    : service.hasSavedMonitor
                    ? 'Paused or turned off.'
                    : 'Available after initial setup.',
                style: AppTextStyles.small,
              ),
            ),
          ),
          if (service.hasSavedMonitor) ...[
            const SizedBox(height: 12),
            _SetupCompleteNotice(verified: service.isSavedMonitorVerified),
          ],
          if (service.lastError != null) ...[
            const SizedBox(height: 12),
            _InlineError(message: service.lastError!),
          ],
          const SizedBox(height: 16),
          if (service.permissionState != BpMonitorPermissionState.granted)
            FilledButton.icon(
              onPressed: service.isSupported
                  ? service.requestPermissions
                  : null,
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Allow Bluetooth Access'),
            ),
          if (service.canOpenSettings) ...[
            const SizedBox(height: 9),
            OutlinedButton.icon(
              onPressed: service.openPermissionSettings,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Open App Settings'),
            ),
          ],
          if (canUseBluetooth && !service.hasSavedMonitor)
            FilledButton.icon(
              onPressed: service.isScanning || service.isConnecting
                  ? null
                  : service.startScan,
              icon: service.isScanning
                  ? const SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching_rounded),
              label: Text(
                service.isScanning ? 'Searching...' : 'Set Up Monitor',
              ),
            ),
          if (canUseBluetooth && service.hasSavedMonitor) ...[
            if (service.stage == BpMonitorBleStage.error &&
                service.isConnected) ...[
              FilledButton.icon(
                onPressed: service.retryNotificationSetup,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Measurement Listener'),
              ),
              const SizedBox(height: 9),
            ],
            if (!service.isConnected && !service.isConnecting) ...[
              FilledButton.icon(
                onPressed: service.isScanning ? null : service.startScan,
                icon: service.isScanning
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.radar_rounded),
                label: Text(
                  service.isScanning ? 'Searching...' : 'Search Again',
                ),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: service.connectSavedMonitor,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Connect Saved Monitor'),
              ),
            ],
            if (service.isConnected || service.isConnecting)
              OutlinedButton.icon(
                onPressed: service.isCancellingConnection
                    ? null
                    : service.disconnect,
                icon: service.isCancellingConnection
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link_off_rounded),
                label: Text(
                  service.isCancellingConnection
                      ? 'Canceling Connection...'
                      : 'Disconnect',
                ),
              ),
            const SizedBox(height: 5),
            Center(
              child: TextButton.icon(
                onPressed: service.isConnecting
                    ? null
                    : service.forgetSavedMonitor,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Forget Monitor'),
              ),
            ),
          ],
          if (service.isScanning || service.matchingDevices.isNotEmpty) ...[
            const SizedBox(height: 17),
            _DetectedMonitors(service: service),
          ],
        ],
      ),
    );
  }
}

class _DetectedMonitors extends StatelessWidget {
  const _DetectedMonitors({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    final devices = service.matchingDevices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text('Nearby YK-IBPA1 monitors', style: AppTextStyles.cardTitle),
        const SizedBox(height: 5),
        Text(
          devices.isEmpty
              ? 'Keep the monitor nearby and press its physical Start button so it advertises.'
              : 'Select the correct monitor once. EverCare will remember its identifier.',
          style: AppTextStyles.bodyMuted,
        ),
        if (devices.isEmpty) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(minHeight: 4),
        ] else ...[
          const SizedBox(height: 12),
          ...devices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DetectedMonitorTile(
                device: device,
                isSaved: device.identifier == service.savedIdentifier,
                onSelect: () => service.saveAndConnect(device),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetectedMonitorTile extends StatelessWidget {
  const _DetectedMonitorTile({
    required this.device,
    required this.isSaved,
    required this.onSelect,
  });

  final BpMonitorDevice device;
  final bool isSaved;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_heart_outlined,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: AppTextStyles.label),
                    Text(device.identifier, style: AppTextStyles.small),
                    Text(
                      'Signal: ${device.rssi} dBm',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
              if (isSaved)
                const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.primaryGreen,
                ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onSelect,
            icon: Icon(isSaved ? Icons.link_rounded : Icons.save_outlined),
            label: Text(isSaved ? 'Connect' : 'Select and Save Monitor'),
          ),
        ],
      ),
    );
  }
}

class _MeasurementInstructionsCard extends StatelessWidget {
  const _MeasurementInstructionsCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      color: Color(0xFFF7FBF8),
      child: Column(
        children: [
          _InstructionStep(
            number: 1,
            text: 'Place the cuff correctly on the patient’s bare upper arm.',
          ),
          _InstructionStep(
            number: 2,
            text: 'Keep the patient still and seated.',
          ),
          _InstructionStep(
            number: 3,
            text: 'Keep the patient’s arm supported.',
          ),
          _InstructionStep(
            number: 4,
            text: 'Press the physical Start button on the monitor.',
          ),
          _InstructionStep(
            number: 5,
            text: 'Keep EverCare open until the result appears.',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.number,
    required this.text,
    this.showDivider = true,
  });

  final int number;
  final String text;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.lightGreen,
                child: Text(
                  '$number',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(child: Text(text, style: AppTextStyles.body)),
            ],
          ),
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
}

class _LiveMeasurementCard extends StatelessWidget {
  const _LiveMeasurementCard({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    final presentation = _measurementPresentation(service);
    final progress = service.latestProgressPressure;
    return AppCard(
      color: presentation.color.withValues(alpha: .08),
      borderColor: presentation.color.withValues(alpha: .22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(presentation.icon, color: presentation.color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(presentation.title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 4),
                    Text(service.statusMessage, style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
          if (service.isMeasurementInProgress && progress != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .86),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE CUFF PRESSURE / RAW PROGRESS VALUE',
                    style: AppTextStyles.eyebrow,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$progress',
                    style: AppTextStyles.metric.copyWith(fontSize: 38),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Elapsed: ${_formatDuration(service.measurementElapsed)} · ${service.connectionStatusLabel}',
                    style: AppTextStyles.small,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'This changing value is measurement progress, not a completed systolic or diastolic result.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoResultCard extends StatelessWidget {
  const _NoResultCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            color: AppColors.secondaryText,
            size: 29,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No blood-pressure measurement received yet.',
                  style: AppTextStyles.cardTitle,
                ),
                SizedBox(height: 5),
                Text(
                  'EverCare will not insert a sample or fallback value. Complete a measurement on the physical YK-IBPA1 monitor.',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedReadingCard extends StatelessWidget {
  const _CompletedReadingCard({required this.result});

  final BpMonitorResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.lightGreen,
      borderColor: AppColors.primaryGreen.withValues(alpha: .24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('RESULT RECEIVED', style: AppTextStyles.eyebrow),
              ),
              const Icon(
                Icons.bluetooth_connected_rounded,
                color: AppColors.primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ResultMetric(
                    width: width,
                    label: 'SYS',
                    value: '${result.systolic}',
                    unit: 'mmHg',
                  ),
                  _ResultMetric(
                    width: width,
                    label: 'DIA',
                    value: '${result.diastolic}',
                    unit: 'mmHg',
                  ),
                  _ResultMetric(
                    width: width,
                    label: 'Pulse',
                    value: '${result.pulse}',
                    unit: 'BPM',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 17),
          _ResultDetail(
            icon: Icons.schedule_rounded,
            label: 'Time measured',
            value: _formatDateTime(result.receivedAt),
          ),
          _ResultDetail(
            icon: Icons.monitor_heart_outlined,
            label: 'Connected monitor',
            value: result.deviceName,
          ),
          const _ResultDetail(
            icon: Icons.bluetooth_rounded,
            label: 'Measurement source',
            value: 'YK-IBPA1 Bluetooth monitor',
          ),
          const _ResultDetail(
            icon: Icons.sensors_rounded,
            label: 'Status',
            value: 'Received directly through BLE',
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 20,
                  color: AppColors.primaryGreen,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Decoder is provisional. Raw packet metadata is preserved and available through BLE Diagnostics.',
                    style: AppTextStyles.small,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentSessionCard extends StatelessWidget {
  const _CurrentSessionCard({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    final hasSession =
        service.measurementStartedAt != null ||
        service.currentResult != null ||
        service.latestProgressPressure != null ||
        service.measurementFailureMessage != null;
    return AppCard(
      child: Column(
        children: [
          _SessionRow(
            label: 'Measurement started',
            value: service.measurementStartedAt == null
                ? 'Not started'
                : _formatDateTime(service.measurementStartedAt!),
          ),
          const Divider(),
          _SessionRow(
            label: 'Measurement completed',
            value: service.measurementCompletedAt == null
                ? 'Not completed'
                : _formatDateTime(service.measurementCompletedAt!),
          ),
          const Divider(),
          _SessionRow(
            label: 'Current BLE status',
            value: _connectionPresentation(service).label,
          ),
          const Divider(),
          _SessionRow(
            label: 'Latest raw progress value',
            value: service.latestProgressPressure?.toString() ?? 'None',
          ),
          const Divider(),
          _SessionRow(
            label: 'Final 0x81 result received',
            value: service.hasFinalResult ? 'Yes' : 'No',
          ),
          if (service.measurementFailureMessage != null) ...[
            const Divider(),
            _SessionRow(
              label: 'Session issue',
              value: service.measurementFailureMessage!,
              warning: true,
            ),
          ],
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: service.hasSavedMonitor
                ? service.prepareForNextMeasurement
                : null,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Retry Measurement'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: hasSession ? service.clearCurrentResult : null,
            icon: const Icon(Icons.clear_rounded),
            label: const Text('Clear Current Result'),
          ),
          const SizedBox(height: 3),
          const Text(
            'Retry only prepares EverCare to listen. Start the measurement with the monitor’s physical button.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      color: Color(0xFFFFF8EB),
      borderColor: Color(0xFFF1D89D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.health_and_safety_outlined, color: AppColors.warning),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'EverCare receives this reading from the connected monitor. Confirm the result on the physical monitor before using it for care decisions.',
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 12),
          Text(
            'EverCare does not provide a medical diagnosis. Contact a qualified healthcare professional regarding concerning readings or symptoms.',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _ConnectionDetail extends StatelessWidget {
  const _ConnectionDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.primaryGreen),
          const SizedBox(width: 9),
          SizedBox(width: 104, child: Text(label, style: AppTextStyles.label)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultDetail extends StatelessWidget {
  const _ResultDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.primaryGreen),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.small),
                const SizedBox(height: 1),
                Text(value, style: AppTextStyles.label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.unit,
  });

  final double width;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.small),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 25),
            ),
          ),
          Text(unit, style: AppTextStyles.small),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.label,
    required this.value,
    this.warning = false,
  });

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.label)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMuted.copyWith(
                color: warning ? AppColors.danger : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupCompleteNotice extends StatelessWidget {
  const _SetupCompleteNotice({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            verified ? Icons.check_circle_rounded : Icons.pending_outlined,
            size: 20,
            color: verified ? AppColors.primaryGreen : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              verified
                  ? 'Monitor setup verified — the measurement listener has connected successfully.'
                  : 'Monitor selected and saved. Connect once to verify its measurement listener.',
              style: AppTextStyles.small,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.danger.withValues(alpha: .20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(message, style: AppTextStyles.bodyMuted)),
        ],
      ),
    );
  }
}

({String label, IconData icon, Color color}) _connectionPresentation(
  BpMonitorBleService service,
) {
  if (service.stage == BpMonitorBleStage.unsupported) {
    return (
      label: 'Bluetooth unavailable',
      icon: Icons.bluetooth_disabled_rounded,
      color: AppColors.danger,
    );
  }
  if (service.stage == BpMonitorBleStage.initializing ||
      service.adapterState == BluetoothAdapterState.unknown) {
    return (
      label: 'Checking Bluetooth availability',
      icon: Icons.bluetooth_searching_rounded,
      color: AppColors.blue,
    );
  }
  if (service.adapterState == BluetoothAdapterState.off) {
    return (
      label: 'Bluetooth is off',
      icon: Icons.bluetooth_disabled_rounded,
      color: AppColors.warning,
    );
  }
  if (service.permissionState == BpMonitorPermissionState.unknown) {
    return (
      label: 'Checking Bluetooth permissions',
      icon: Icons.admin_panel_settings_outlined,
      color: AppColors.blue,
    );
  }
  if (service.permissionState != BpMonitorPermissionState.granted) {
    return (
      label: 'Permission required',
      icon: Icons.admin_panel_settings_outlined,
      color: AppColors.warning,
    );
  }
  if (!service.hasSavedMonitor) {
    return (
      label: service.isScanning
          ? 'Scanning for a monitor'
          : 'No monitor set up',
      icon: Icons.bluetooth_searching_rounded,
      color: AppColors.blue,
    );
  }
  if (service.stage == BpMonitorBleStage.error) {
    return (
      label: service.isConnected
          ? 'Notifications unavailable'
          : 'Connection failed',
      icon: Icons.error_outline_rounded,
      color: AppColors.danger,
    );
  }
  if (service.isCancellingConnection) {
    return (
      label: 'Canceling connection',
      icon: Icons.link_off_rounded,
      color: AppColors.warning,
    );
  }
  if (service.isScanning) {
    return (
      label: 'Searching for saved monitor',
      icon: Icons.radar_rounded,
      color: AppColors.blue,
    );
  }
  if (service.isConnecting) {
    return (
      label: 'Connecting',
      icon: Icons.bluetooth_searching_rounded,
      color: AppColors.blue,
    );
  }
  if (service.isListening) {
    return (
      label: service.isMeasurementInProgress
          ? 'Measurement in progress'
          : service.hasFinalResult
          ? 'Result received'
          : service.measurementState == BpMonitorMeasurementState.failed
          ? 'Connected — measurement failed'
          : 'Ready — press Start on monitor',
      icon: Icons.bluetooth_connected_rounded,
      color: AppColors.primaryGreen,
    );
  }
  if (service.isConnected) {
    return (
      label: 'Preparing measurement listener',
      icon: Icons.sync_rounded,
      color: AppColors.blue,
    );
  }
  if (service.stage == BpMonitorBleStage.monitorNotFound) {
    return (
      label: 'Monitor not found',
      icon: Icons.search_off_rounded,
      color: AppColors.warning,
    );
  }
  return (
    label: 'Monitor disconnected',
    icon: Icons.bluetooth_disabled_rounded,
    color: AppColors.secondaryText,
  );
}

({String title, IconData icon, Color color}) _measurementPresentation(
  BpMonitorBleService service,
) {
  if (service.stage == BpMonitorBleStage.error &&
      service.currentResult == null) {
    return (
      title: service.isConnected
          ? 'Measurement listener unavailable'
          : 'Unexpected BLE error',
      icon: Icons.error_outline_rounded,
      color: AppColors.danger,
    );
  }
  return switch (service.measurementState) {
    BpMonitorMeasurementState.inProgress => (
      title: 'Measurement in progress',
      icon: Icons.monitor_heart_rounded,
      color: AppColors.warning,
    ),
    BpMonitorMeasurementState.resultReceived => (
      title: 'Result received',
      icon: Icons.task_alt_rounded,
      color: AppColors.primaryGreen,
    ),
    BpMonitorMeasurementState.failed => (
      title: 'Measurement failed',
      icon: Icons.error_outline_rounded,
      color: AppColors.danger,
    ),
    BpMonitorMeasurementState.ready => (
      title: 'Ready — press Start on the physical monitor',
      icon: Icons.play_circle_outline_rounded,
      color: AppColors.primaryGreen,
    ),
    BpMonitorMeasurementState.waitingForMonitor => (
      title: 'Waiting for a real monitor connection',
      icon: Icons.bluetooth_searching_rounded,
      color: AppColors.blue,
    ),
  };
}

String _formatDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(hour)}:${two(value.minute)}:${two(value.second)} $period';
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
