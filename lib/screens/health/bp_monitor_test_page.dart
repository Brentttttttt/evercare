import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/bp_monitor_device.dart';
import '../../models/bp_monitor_packet.dart';
import '../../models/bp_monitor_result.dart';
import '../../services/bp_monitor_ble_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/bp_monitor_ble_scope.dart';

class BpMonitorTestPage extends StatefulWidget {
  const BpMonitorTestPage({super.key});

  @override
  State<BpMonitorTestPage> createState() => _BpMonitorTestPageState();
}

class _BpMonitorTestPageState extends State<BpMonitorTestPage> {
  late final BpMonitorBleService _service;
  final ScrollController _packetLogController = ScrollController();
  bool _attached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_attached) return;
    _service = BpMonitorBleScope.read(context);
    _service.attachClient(this);
    _attached = true;
  }

  @override
  void dispose() {
    if (_attached) _service.detachClient(this);
    _packetLogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BpMonitorBleScope.watch(context);
    return DetailPage(
      title: 'BLE Monitor Test',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DevelopmentNotice(message: _service.statusMessage),
          const SizedBox(height: 18),
          const Text('Bluetooth status', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          _StatusOverview(service: _service),
          if (_service.currentResult case final result?) ...[
            const SizedBox(height: 12),
            _ProvisionalResultDetails(result: result),
          ],
          if (_service.lastError != null) ...[
            const SizedBox(height: 12),
            _ErrorNotice(
              message: _service.lastError!,
              showSettings: _service.canOpenSettings,
              onOpenSettings: _service.openPermissionSettings,
            ),
          ],
          const SizedBox(height: 18),
          _AutoConnectCard(service: _service),
          const SizedBox(height: 18),
          _CaptureSessionPanel(service: _service),
          const SizedBox(height: 18),
          const Text('Test controls', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          _TestControls(service: _service),
          const SizedBox(height: 22),
          _DiscoveredDevices(service: _service),
          const SizedBox(height: 22),
          _PacketLog(
            service: _service,
            controller: _packetLogController,
            onExport: _showExportOptions,
          ),
          const SizedBox(height: 16),
          const AppCard(
            color: Color(0xFFFFF8EB),
            borderColor: Color(0xFFF1D89D),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined, color: AppColors.warning),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Development capture only. Packets are displayed exactly as '
                    'received. Caregiver-facing result decoding is separate and '
                    'provisional; captures are not saved to a database, uploaded, '
                    'or presented as medically verified readings.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportOptions() async {
    if (_service.captureActive) {
      _showMessage('Stop the capture before exporting the complete session.');
      return;
    }
    if (!_service.hasCaptureSession) {
      _showMessage('Start a capture session before exporting.');
      return;
    }

    final format = await showModalBottomSheet<_CaptureExportFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export complete session',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 4),
              const Text(
                'Copy the full event history and every retained packet.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Copy plain text'),
                subtitle: const Text('Human-readable session report'),
                onTap: () =>
                    Navigator.pop(context, _CaptureExportFormat.plainText),
              ),
              ListTile(
                leading: const Icon(Icons.data_object_rounded),
                title: const Text('Copy JSON'),
                subtitle: const Text('Structured events and packet arrays'),
                onTap: () => Navigator.pop(context, _CaptureExportFormat.json),
              ),
            ],
          ),
        ),
      ),
    );
    if (format == null || !mounted) return;

    final text = switch (format) {
      _CaptureExportFormat.plainText => _service.exportCaptureAsPlainText(),
      _CaptureExportFormat.json => _service.exportCaptureAsJson(),
    };
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      _showMessage(
        format == _CaptureExportFormat.json
            ? 'Complete capture copied as JSON.'
            : 'Complete capture copied as plain text.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProvisionalResultDetails extends StatelessWidget {
  const _ProvisionalResultDetails({required this.result});

  final BpMonitorResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.lightGreen,
      borderColor: AppColors.primaryGreen.withValues(alpha: .24),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provisional decoded result',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 4),
            const Text(
              'Development comparison only — not medically verified.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 13),
            Text(
              'SYS ${result.systolic} · DIA ${result.diastolic} · Pulse ${result.pulse}',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Received: ${_formatDateTime(result.receivedAt)}',
              style: AppTextStyles.small,
            ),
            Text(
              'Device: ${result.deviceName} (${result.deviceIdentifier})',
              style: AppTextStyles.small,
            ),
            Text(
              'Packet index: ${result.packetIndex} · ${result.decoderVersion}',
              style: AppTextStyles.small,
            ),
            Text(
              'Validation: ${result.validationStatus}',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 10),
            const Text('RAW HEX', style: AppTextStyles.eyebrow),
            const SizedBox(height: 3),
            Text(
              result.rawHex,
              style: AppTextStyles.small.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            Text(
              'Metadata bytes: [${result.metadataBytes.join(', ')}]',
              style: AppTextStyles.small.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CaptureExportFormat { plainText, json }

class _DevelopmentNotice extends StatelessWidget {
  const _DevelopmentNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.lightGreen,
      borderColor: AppColors.primaryGreen.withValues(alpha: .24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.bluetooth_searching_rounded,
            color: AppColors.primaryGreen,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YK-IBPA1 development test',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOverview extends StatelessWidget {
  const _StatusOverview({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = constraints.maxWidth >= 560
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatusTile(
                width: tileWidth,
                icon: Icons.bluetooth_rounded,
                label: 'Adapter',
                value: service.isSupported
                    ? service.adapterStatusLabel
                    : 'BLE unsupported',
                positive: service.adapterStatusLabel == 'Bluetooth on',
              ),
              _StatusTile(
                width: tileWidth,
                icon: Icons.verified_user_outlined,
                label: 'Permission',
                value: service.permissionStatusLabel,
                positive:
                    service.permissionState == BpMonitorPermissionState.granted,
              ),
              _StatusTile(
                width: tileWidth,
                icon: Icons.monitor_heart_outlined,
                label: 'Saved monitor',
                value: service.hasSavedMonitor
                    ? '${service.savedName ?? BpMonitorBleService.monitorName}\n'
                          '${service.savedIdentifier}'
                    : 'None selected',
                positive: service.hasSavedMonitor,
              ),
              _StatusTile(
                width: tileWidth,
                icon: Icons.radar_rounded,
                label: 'Scan',
                value: service.scanStatusLabel,
                positive: service.matchingDevices.isNotEmpty,
              ),
              _StatusTile(
                width: tileWidth,
                icon: service.isListening
                    ? Icons.sensors_rounded
                    : Icons.link_rounded,
                label: 'Connection',
                value: service.connectionStatusLabel,
                positive: service.isConnected,
              ),
              _StatusTile(
                width: tileWidth,
                icon: Icons.badge_outlined,
                label: 'Connected device',
                value: service.connectedIdentifier == null
                    ? 'No connected device'
                    : '${service.connectedName}\n${service.connectedIdentifier}',
                positive: service.isConnected,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.positive,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.primaryGreen : AppColors.secondaryText;
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: positive ? AppColors.lightGreen : AppColors.background,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.label),
                const SizedBox(height: 3),
                Text(value, style: AppTextStyles.body.copyWith(fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({
    required this.message,
    required this.showSettings,
    required this.onOpenSettings,
  });

  final String message;
  final bool showSettings;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFFF4F2),
      borderColor: AppColors.danger.withValues(alpha: .3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: AppTextStyles.bodyMuted)),
            ],
          ),
          if (showSettings) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Open app settings'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoConnectCard extends StatelessWidget {
  const _AutoConnectCard({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile.adaptive(
        value: service.autoConnect,
        onChanged: service.hasSavedMonitor ? service.setAutoConnect : null,
        secondary: const Icon(
          Icons.autorenew_rounded,
          color: AppColors.primaryGreen,
        ),
        title: const Text('Auto-connect', style: AppTextStyles.cardTitle),
        subtitle: Text(
          service.hasSavedMonitor
              ? 'Scan in timed cycles while this page is open and reconnect when the saved monitor advertises.'
              : 'Select and save a monitor to enable automatic reconnection.',
          style: AppTextStyles.bodyMuted,
        ),
      ),
    );
  }
}

class _CaptureSessionPanel extends StatelessWidget {
  const _CaptureSessionPanel({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    final start = service.captureStartTime;
    final end = service.captureEndTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Capture session', style: AppTextStyles.sectionTitle),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: service.captureActive
                    ? AppColors.lightGreen
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: service.captureActive
                          ? AppColors.primaryGreen
                          : AppColors.secondaryText,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    service.captureActive ? 'CAPTURING' : 'STOPPED',
                    style: AppTextStyles.eyebrow.copyWith(
                      color: service.captureActive
                          ? AppColors.darkGreen
                          : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Start this before scanning so connection events and the full measurement are included.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: [
              LabeledValue(
                label: 'Capture start time',
                value: start == null ? 'Not started' : _formatDateTime(start),
                icon: Icons.play_circle_outline_rounded,
              ),
              const Divider(),
              LabeledValue(
                label: 'Capture end time',
                value: end == null
                    ? service.captureActive
                          ? 'Recording until stopped or disconnected'
                          : 'Not recorded'
                    : _formatDateTime(end),
                icon: Icons.stop_circle_outlined,
              ),
              const Divider(),
              LabeledValue(
                label: 'Captured data',
                value:
                    '${service.totalPacketCount} packets · ${service.captureEvents.length} events',
                icon: Icons.data_array_rounded,
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: service.captureActive
                    ? null
                    : service.startNewCapture,
                icon: const Icon(Icons.fiber_manual_record_rounded),
                label: const Text('Start new capture'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: service.captureActive ? service.stopCapture : null,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop capture'),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: service.hasCaptureSession && !service.captureActive
                    ? service.clearCapture
                    : null,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Clear capture'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TestControls extends StatelessWidget {
  const _TestControls({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: service.requestPermissions,
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Request permissions'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: service.isScanning || service.isConnecting
              ? null
              : service.startScan,
          icon: service.isScanning
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.radar_rounded),
          label: Text(service.isScanning ? 'Scanning...' : 'Scan for monitor'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed:
              service.hasSavedMonitor &&
                  !service.isConnected &&
                  !service.isConnecting
              ? service.connectSavedMonitor
              : null,
          icon: const Icon(Icons.link_rounded),
          label: const Text('Connect'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed:
              !service.isCancellingConnection &&
                  (service.isConnected || service.isConnecting)
              ? service.disconnect
              : null,
          icon: const Icon(Icons.link_off_rounded),
          label: const Text('Disconnect'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: service.hasSavedMonitor
              ? service.forgetSavedMonitor
              : null,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Forget saved monitor'),
        ),
      ],
    );
  }
}

class _DiscoveredDevices extends StatelessWidget {
  const _DiscoveredDevices({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    final devices = service.matchingDevices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detected matching devices',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: 4),
        const Text(
          'The device name is used only for initial discovery. After saving, EverCare matches the Android device identifier.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 10),
        if (devices.isEmpty)
          const AppCard(
            child: Row(
              children: [
                Icon(Icons.search_off_rounded, color: AppColors.secondaryText),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'No YK-IBPA1 advertisement detected yet.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            ),
          )
        else
          ...devices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DeviceResultCard(
                device: device,
                isSaved: device.identifier == service.savedIdentifier,
                onSelect: () => service.saveAndConnect(device),
              ),
            ),
          ),
      ],
    );
  }
}

class _DeviceResultCard extends StatelessWidget {
  const _DeviceResultCard({
    required this.device,
    required this.isSaved,
    required this.onSelect,
  });

  final BpMonitorDevice device;
  final bool isSaved;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(device.identifier, style: AppTextStyles.small),
                    const SizedBox(height: 2),
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
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onSelect,
            icon: Icon(isSaved ? Icons.link_rounded : Icons.save_outlined),
            label: Text(isSaved ? 'Connect saved monitor' : 'Save and connect'),
          ),
        ],
      ),
    );
  }
}

class _PacketLog extends StatelessWidget {
  const _PacketLog({
    required this.service,
    required this.controller,
    required this.onExport,
  });

  final BpMonitorBleService service;
  final ScrollController controller;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final packets = service.packets.reversed.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Capture summary', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        _CaptureSummary(service: service),
        const SizedBox(height: 20),
        const Text('Raw notification log', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 4),
        Text(
          '${service.totalPacketCount} packet${service.totalPacketCount == 1 ? '' : 's'} retained in memory without deduplication',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF17231C),
          borderColor: const Color(0xFF2A3B31),
          child: SizedBox(
            height: 330,
            child: packets.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No packets retained. Start a new capture, connect the monitor, and complete a measurement.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFB9C9C0),
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  )
                : Scrollbar(
                    controller: controller,
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: controller,
                      itemCount: packets.length,
                      separatorBuilder: (_, _) =>
                          const Divider(color: Color(0xFF34483D), height: 22),
                      itemBuilder: (context, index) =>
                          _PacketEntry(packet: packets[index]),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: service.hasCaptureSession && !service.captureActive
              ? onExport
              : null,
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Export / Copy Complete Session'),
        ),
        if (service.captureActive) ...[
          const SizedBox(height: 7),
          const Center(
            child: Text(
              'Stop the capture or disconnect the monitor to enable export.',
              textAlign: TextAlign.center,
              style: AppTextStyles.small,
            ),
          ),
        ],
      ],
    );
  }
}

class _CaptureSummary extends StatelessWidget {
  const _CaptureSummary({required this.service});

  final BpMonitorBleService service;

  @override
  Widget build(BuildContext context) {
    final firstPacket = service.firstPacket;
    final lastPacket = service.lastPacket;
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 560
              ? (constraints.maxWidth - 10) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryTile(
                width: width,
                label: 'Total packets',
                value: '${service.totalPacketCount}',
              ),
              _SummaryTile(
                width: width,
                label: 'Unique structures',
                value: '${service.uniquePacketStructureCount}',
              ),
              _SummaryTile(
                width: width,
                label: 'Highlighted packets',
                value: '${service.highlightedPacketCount}',
                warning: service.highlightedPacketCount > 0,
              ),
              _SummaryTile(
                width: width,
                label: 'Connection events',
                value: '${service.captureEvents.length}',
              ),
              _SummaryTile(
                width: width,
                label: 'First packet',
                value: firstPacket?.hexadecimalString ?? 'None',
                monospace: firstPacket != null,
              ),
              _SummaryTile(
                width: width,
                label: 'Last packet',
                value: lastPacket?.hexadecimalString ?? 'None',
                monospace: lastPacket != null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.width,
    required this.label,
    required this.value,
    this.warning = false,
    this.monospace = false,
  });

  final double width;
  final String label;
  final String value;
  final bool warning;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFF3DC) : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: warning
              ? AppColors.warning.withValues(alpha: .45)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: monospace ? 'monospace' : null,
              fontSize: monospace ? 11.5 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PacketEntry extends StatelessWidget {
  const _PacketEntry({required this.packet});

  final BpMonitorPacket packet;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: Color(0xFF81C7A4),
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
    );
    const valueStyle = TextStyle(
      color: Colors.white,
      fontSize: 12.5,
      height: 1.45,
      fontFamily: 'monospace',
    );

    return Container(
      padding: packet.isHighlighted
          ? const EdgeInsets.all(10)
          : EdgeInsets.zero,
      decoration: packet.isHighlighted
          ? BoxDecoration(
              color: const Color(0xFF3B3321),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6A43A)),
            )
          : null,
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'PACKET #${packet.index.toString().padLeft(6, '0')} · ${packet.length} BYTES',
                    style: labelStyle,
                  ),
                ),
                if (packet.isHighlighted)
                  const Text(
                    'HIGHLIGHTED',
                    style: TextStyle(
                      color: Color(0xFFFFC76B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(_formatDateTime(packet.receivedAt), style: labelStyle),
            if (packet.highlightReasons.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                packet.highlightReasons.join(' · '),
                style: const TextStyle(
                  color: Color(0xFFFFD797),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 7),
            const Text('DECIMAL', style: labelStyle),
            const SizedBox(height: 2),
            Text(packet.decimalString, style: valueStyle),
            const SizedBox(height: 7),
            const Text('HEX', style: labelStyle),
            const SizedBox(height: 2),
            Text(packet.hexadecimalString, style: valueStyle),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  String threeDigits(int number) => number.toString().padLeft(3, '0');
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(hour)}:${twoDigits(value.minute)}:${twoDigits(value.second)}.'
      '${threeDigits(value.millisecond)} $period';
}
