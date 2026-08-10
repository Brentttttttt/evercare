import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'
    show BluetoothAdapterState;

import '../../models/bp_monitor_device.dart';
import '../../models/bp_monitor_result.dart';
import '../../repositories/blood_pressure_repository.dart';
import '../../routes/app_route_observer.dart';
import '../../routes/app_routes.dart';
import '../../services/bp_monitor_ble_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/bp_monitor_ble_scope.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/section_header.dart';

class HealthOverviewScreen extends StatefulWidget {
  const HealthOverviewScreen({
    this.isActive = true,
    this.scrollController,
    super.key,
  });

  /// The main shell uses an IndexedStack, so mounting alone does not mean the
  /// Health tab is visible. Auto-scan is leased only while this is true.
  final bool isActive;
  final ScrollController? scrollController;

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
      controller: widget.scrollController,
      padding: mainPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MY HEALTH',
            style: AppTextStyles.eyebrow.copyWith(
              color: AppColors.primaryGreen,
              letterSpacing: .9,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Blood Pressure',
            style: AppTextStyles.display.copyWith(
              fontSize: 33,
              letterSpacing: -1.05,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Connect, measure, and review readings in one secure place.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 22),
          const CarePhotoBanner(
            assetPath: 'assets/images/bp_monitor_home.png',
            semanticLabel:
                'A caregiver helping an older adult use an upper-arm blood pressure monitor',
            title: 'Measure with confidence',
            subtitle:
                'Connect the real monitor and keep the patient calm and still.',
            height: 150,
          ),
          const SizedBox(height: 16),
          _MonitorConnectionCard(service: service),
          const SizedBox(height: 20),
          if (service.currentResult case final result?)
            _CompletedReadingSection(result: result)
          else ...[
            const SectionHeader(
              title: 'Latest reading',
              subtitle: 'Only completed monitor results appear here.',
            ),
            const SizedBox(height: 12),
            const _NoResultCard(),
          ],
          if (service.currentResult == null) ...[
            const SizedBox(height: 12),
            AppCard(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.bloodPressureHistory),
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
                        const Text(
                          'No BLE reading in this session yet.',
                          style: AppTextStyles.cardTitle,
                        ),
                        SizedBox(height: 5),
                        const Text(
                          'Open your secure history to review readings you intentionally saved to your account.',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const _MeasurementInstructionsCard(),
          const SizedBox(height: 10),
          _ConnectionDetailsCard(service: service),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.manualRecord),
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Enter Blood Pressure Manually'),
            ),
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: status.color.withValues(alpha: .18),
                  ),
                ),
                child: Icon(status.icon, color: status.color, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blood pressure monitor',
                      style: AppTextStyles.small,
                    ),
                    const SizedBox(height: 2),
                    Text(deviceName, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 4),
                    _StatusPill(label: status.label, color: status.color),
                  ],
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: .065),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  service.isMeasurementInProgress
                      ? Icons.monitor_heart_rounded
                      : Icons.info_outline_rounded,
                  color: status.color,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    service.statusMessage,
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: AppColors.foreground,
                      height: 1.36,
                    ),
                  ),
                ),
              ],
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
          if (service.measurementFailureMessage != null &&
              service.measurementFailureMessage != service.lastError) ...[
            const SizedBox(height: 12),
            _InlineError(message: service.measurementFailureMessage!),
          ],
          if (service.isMeasurementInProgress) ...[
            const SizedBox(height: 12),
            _LiveMeasurementProgress(service: service),
          ],
          const SizedBox(height: 16),
          if (service.permissionState != BpMonitorPermissionState.granted)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: service.isSupported
                    ? service.requestPermissions
                    : null,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Allow Bluetooth Access'),
              ),
            ),
          if (service.canOpenSettings) ...[
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: service.openPermissionSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Open App Settings'),
              ),
            ),
          ],
          if (canUseBluetooth && !service.hasSavedMonitor)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
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
            ),
          if (canUseBluetooth && service.hasSavedMonitor) ...[
            if (service.stage == BpMonitorBleStage.error &&
                service.isConnected) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: service.retryNotificationSetup,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Measurement Listener'),
                ),
              ),
              const SizedBox(height: 9),
            ],
            if (!service.isConnected && !service.isConnecting) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
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
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: service.connectSavedMonitor,
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Connect Saved Monitor'),
                ),
              ),
            ],
            if (service.isConnected || service.isConnecting)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
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
        borderRadius: BorderRadius.circular(12),
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
    return const _HealthAccordion(
      icon: Icons.checklist_rounded,
      title: 'How to measure',
      subtitle: 'Review the five steps before starting the monitor.',
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

class _ConnectionDetailsCard extends StatelessWidget {
  const _ConnectionDetailsCard({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    final status = _connectionPresentation(service);
    return _HealthAccordion(
      icon: Icons.bluetooth_rounded,
      title: 'Connection details',
      subtitle: 'Monitor settings and current BLE session information.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConnectionDetail(
            icon: Icons.tag_rounded,
            label: 'Identifier',
            value: service.savedIdentifier ?? 'No monitor saved',
          ),
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
          const _ConnectionDetail(
            icon: Icons.battery_unknown_rounded,
            label: 'Monitor battery',
            value: 'Battery level unavailable.',
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                    ? 'On — searches while the Health page is active.'
                    : service.hasSavedMonitor
                    ? 'Paused or turned off.'
                    : 'Available after initial setup.',
                style: AppTextStyles.small,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text('Current session', style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          const Text(
            'Technical session values are shown for transparency and troubleshooting.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 10),
          _CurrentSessionCard(service: service),
        ],
      ),
    );
  }
}

class _HealthAccordion extends StatelessWidget {
  const _HealthAccordion({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppColors.primaryGreen,
          collapsedIconColor: AppColors.mutedForeground,
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 21),
          ),
          title: Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.cardTitle),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(subtitle, style: AppTextStyles.small),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 10),
            child,
          ],
        ),
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

class _LiveMeasurementProgress extends StatelessWidget {
  const _LiveMeasurementProgress({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    final presentation = _measurementPresentation(service);
    final progress = service.latestProgressPressure;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: presentation.color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: presentation.color.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  presentation.icon,
                  color: presentation.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
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
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: .88),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
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
                    style: AppTextStyles.metric.copyWith(fontSize: 34),
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

class _CompletedReadingSection extends StatelessWidget {
  const _CompletedReadingSection({required this.result});

  final BpMonitorResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BloodPressureResultCard(result: result),
        const SizedBox(height: 12),
        _BloodPressureDetailsLayout(result: result),
        const SizedBox(height: 12),
        const _BleResultBanner(),
        const SizedBox(height: 12),
        const _ReadingInsightCard(),
        const SizedBox(height: 12),
        _BloodPressureActionBar(result: result),
      ],
    );
  }
}

class _BloodPressureResultCard extends StatelessWidget {
  const _BloodPressureResultCard({required this.result});

  final BpMonitorResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.primaryGreen.withValues(alpha: .24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final stackContent =
                  constraints.maxWidth < 330 || textScale > 1.2;
              final readingDetails = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reading received',
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.darkGreen,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Your blood pressure reading was received successfully.',
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 7,
                    runSpacing: 4,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: AppColors.darkGreen,
                      ),
                      Text(
                        '${_formatMeasurementDate(result.receivedAt)}  ·  ${_formatMeasurementTime(result.receivedAt)}',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              );

              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/bp_result_care_v1.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      cacheWidth: 1200,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.card,
                            Color(0xFAFFFFFF),
                            Color(0xD9FFFFFF),
                            Color(0x32FFFFFF),
                          ],
                          stops: [0, .42, .72, 1],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.primaryGreen.withValues(
                                alpha: .13,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 17,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  'COMPLETED READING',
                                  style: AppTextStyles.eyebrow.copyWith(
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (stackContent) ...[
                          readingDetails,
                          const SizedBox(height: 14),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: _BloodPressureStatusIndicator(),
                          ),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: readingDetails),
                              const SizedBox(width: 12),
                              const _BloodPressureStatusIndicator(),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Container(
            width: double.infinity,
            color: AppColors.card,
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 10.0;
                final threeColumns = constraints.maxWidth >= 390;
                final twoColumns = !threeColumns && constraints.maxWidth >= 230;
                final columns = threeColumns ? 3 : (twoColumns ? 2 : 1);
                final baseWidth =
                    (constraints.maxWidth - (gap * (columns - 1))) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _BloodPressureValueTile(
                      width: baseWidth,
                      icon: Icons.arrow_upward_rounded,
                      iconColor: AppColors.primaryGreen,
                      label: 'SYS',
                      value: result.systolic.toString(),
                      unit: 'mmHg',
                      semanticLabel:
                          'Systolic pressure, ${result.systolic} millimeters of mercury',
                    ),
                    _BloodPressureValueTile(
                      width: baseWidth,
                      icon: Icons.arrow_downward_rounded,
                      iconColor: AppColors.blue,
                      label: 'DIA',
                      value: result.diastolic.toString(),
                      unit: 'mmHg',
                      semanticLabel:
                          'Diastolic pressure, ${result.diastolic} millimeters of mercury',
                    ),
                    _BloodPressureValueTile(
                      width: twoColumns ? constraints.maxWidth : baseWidth,
                      icon: Icons.favorite_rounded,
                      iconColor: AppColors.danger,
                      label: 'Pulse',
                      value: result.pulse.toString(),
                      unit: 'BPM',
                      semanticLabel: 'Pulse, ${result.pulse} beats per minute',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BloodPressureStatusIndicator extends StatelessWidget {
  const _BloodPressureStatusIndicator();

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final diameter = (108 + ((textScale - 1) * 58)).clamp(108, 166).toDouble();
    final indicator = Semantics(
      label: 'Status: Reading received',
      excludeSemantics: true,
      child: Container(
        width: diameter,
        height: diameter,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .96),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: .68),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withValues(alpha: .09),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lightGreen.withValues(alpha: .78),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.monitor_heart_rounded,
                color: AppColors.primaryGreen,
                size: 27,
              ),
              const SizedBox(height: 4),
              Text(
                'Reading\nreceived',
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return indicator;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .94, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.emphasizedCurve,
      child: indicator,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: value, child: child),
      ),
    );
  }
}

class _BloodPressureValueTile extends StatelessWidget {
  const _BloodPressureValueTile({
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.semanticLabel,
  });

  final double width;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 17, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: AppTextStyles.label)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: AppTextStyles.metric),
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit, style: AppTextStyles.small),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodPressureDetailsLayout extends StatelessWidget {
  const _BloodPressureDetailsLayout({required this.result});

  final BpMonitorResult result;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trend = _BloodPressureTrendCard(result: result);
        final information = _MeasurementInfoCard(result: result);
        if (constraints.maxWidth < 680) {
          return Column(
            children: [trend, const SizedBox(height: 12), information],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: trend),
            const SizedBox(width: 12),
            Expanded(child: information),
          ],
        );
      },
    );
  }
}

class _MeasurementInfoCard extends StatelessWidget {
  const _MeasurementInfoCard({required this.result});

  final BpMonitorResult result;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MeasurementInfoData(
        icon: Icons.schedule_rounded,
        label: 'Time measured',
        value:
            '${_formatMeasurementDate(result.receivedAt)}\n${_formatMeasurementTime(result.receivedAt)}',
      ),
      _MeasurementInfoData(
        icon: Icons.monitor_heart_outlined,
        label: 'Connected monitor',
        value: result.deviceName,
      ),
      const _MeasurementInfoData(
        icon: Icons.bluetooth_rounded,
        label: 'Measurement source',
        value: 'Bluetooth (BLE)',
      ),
      const _MeasurementInfoData(
        icon: Icons.sensors_rounded,
        label: 'Result status',
        value: 'Received directly through BLE',
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Measurement information',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              Icon(
                Icons.fact_check_outlined,
                size: 21,
                color: AppColors.primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 220) {
                  return Column(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        _MeasurementInfoItem(data: items[index]),
                        if (index != items.length - 1) const Divider(height: 1),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _MeasurementInfoItem(data: items[0])),
                          const VerticalDivider(width: 1, thickness: 1),
                          Expanded(child: _MeasurementInfoItem(data: items[1])),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _MeasurementInfoItem(data: items[2])),
                          const VerticalDivider(width: 1, thickness: 1),
                          Expanded(child: _MeasurementInfoItem(data: items[3])),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementInfoData {
  const _MeasurementInfoData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _MeasurementInfoItem extends StatelessWidget {
  const _MeasurementInfoItem({required this.data});

  final _MeasurementInfoData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 18, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 8),
          Text(data.label, style: AppTextStyles.small),
          const SizedBox(height: 3),
          Text(
            data.value,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingInsightCard extends StatelessWidget {
  const _ReadingInsightCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.warningContainer,
      borderColor: AppColors.warning.withValues(alpha: .24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 78,
              child: Image.asset(
                'assets/images/bp_result_care_v1.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                cacheWidth: 260,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Caregiver insight', style: AppTextStyles.cardTitle),
                const SizedBox(height: 5),
                Text(
                  'Review this result together with the patient’s previous readings. Consult a healthcare professional if readings remain unusual or the patient feels unwell.',
                  style: AppTextStyles.bodyMuted.copyWith(height: 1.38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BloodPressureTrendCard extends StatelessWidget {
  const _BloodPressureTrendCard({required this.result});

  final BpMonitorResult result;

  @override
  Widget build(BuildContext context) {
    final historyChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text('Saved history required', style: AppTextStyles.small),
    );
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const title = Text(
                'Recent trend',
                style: AppTextStyles.cardTitle,
              );
              if (constraints.maxWidth < 330) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 8), historyChip],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(child: title),
                  const SizedBox(width: 8),
                  historyChip,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TrendSummaryChip(
                      icon: Icons.monitor_heart_outlined,
                      text: '${result.systolic}/${result.diastolic} mmHg',
                    ),
                    _TrendSummaryChip(
                      icon: Icons.favorite_outline_rounded,
                      text: '${result.pulse} BPM',
                    ),
                    _TrendSummaryChip(
                      icon: Icons.schedule_rounded,
                      text:
                          '${_formatMeasurementDate(result.receivedAt)} · ${_formatMeasurementTime(result.receivedAt)}',
                      fullWidth: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'More saved readings are needed before a trend can be displayed.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendSummaryChip extends StatelessWidget {
  const _TrendSummaryChip({
    required this.icon,
    required this.text,
    this.fullWidth = false,
  });

  final IconData icon;
  final String text;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.primaryGreen),
          const SizedBox(width: 6),
          if (fullWidth)
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            )
          else
            Flexible(
              child: Text(
                text,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BleResultBanner extends StatelessWidget {
  const _BleResultBanner();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.accent,
      borderColor: AppColors.primaryGreen.withValues(alpha: .18),
      padding: EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              size: 22,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Result received directly through BLE.',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  'Decoder is provisional. Raw packet metadata is preserved and available through BLE Diagnostics.',
                  style: AppTextStyles.small.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.secondaryText,
          ),
        ],
      ),
    );
  }
}

class _BloodPressureActionBar extends StatefulWidget {
  const _BloodPressureActionBar({required this.result});

  final BpMonitorResult result;

  @override
  State<_BloodPressureActionBar> createState() =>
      _BloodPressureActionBarState();
}

class _BloodPressureActionBarState extends State<_BloodPressureActionBar> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    final client = EverCareBackendScope.maybeClient(context);
    if (client == null || client.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in before saving this result.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await BloodPressureRepository(client).saveBleResult(widget.result);
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result saved. It is not medically verified.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the result: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stackButtons = constraints.maxWidth < 270 || textScale > 1.15;
        final saveButton = PressScale(
          child: OutlinedButton.icon(
            onPressed: _saving || _saved ? null : _save,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: Icon(
              _saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
            ),
            label: Text(
              _saved
                  ? 'Saved'
                  : _saving
                  ? 'Saving…'
                  : 'Save Result',
            ),
          ),
        );
        final historyButton = PressScale(
          child: FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.bloodPressureHistory),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.history_rounded),
            label: const Text('View History'),
          ),
        );
        final trendButton = PressScale(
          child: OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.bloodPressureTrend),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.show_chart_rounded),
            label: const Text('View Trend'),
          ),
        );

        if (stackButtons) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: saveButton),
              const SizedBox(height: 9),
              SizedBox(width: double.infinity, child: historyButton),
              const SizedBox(height: 9),
              SizedBox(width: double.infinity, child: trendButton),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(width: double.infinity, child: saveButton),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: historyButton),
                const SizedBox(width: 10),
                Expanded(child: trendButton),
              ],
            ),
          ],
        );
      },
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
    return Column(
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
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      color: AppColors.warningContainer,
      borderColor: Color(0x3DB87317),
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

String _formatMeasurementDate(DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

String _formatMeasurementTime(DateTime value) {
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${hour.toString().padLeft(2, '0')}:$minute $period';
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
