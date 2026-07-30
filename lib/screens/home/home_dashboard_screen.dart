import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../routes/app_routes.dart';
import '../../services/bp_monitor_ble_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/bp_monitor_ble_scope.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/section_header.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({required this.onSelectTab, super.key});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final bpMonitor = BpMonitorBleScope.watch(context);
    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MONDAY, JULY 20', style: AppTextStyles.eyebrow),
          const SizedBox(height: 7),
          const Text('Good morning, Maria', style: AppTextStyles.pageTitle),
          const SizedBox(height: 5),
          const Text(
            'Your caregiving overview for today.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 18),
          const CarePhotoBanner(
            assetPath: 'assets/images/dashboard_care.png',
            semanticLabel:
                'An elderly woman and her daughter reviewing a health notebook at home',
            title: 'Care that feels close to home',
            subtitle: 'Health, medicines, and visits organized in one place.',
            height: 180,
          ),
          const SizedBox(height: 20),
          _BloodPressureSummaryCard(
            service: bpMonitor,
            onTap: () => onSelectTab(1),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Today’s overview'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _OverviewTile(
                    width: width,
                    icon: Icons.medication_outlined,
                    color: AppColors.primaryGreen,
                    label: 'Medication',
                    value: '2 remaining',
                    detail: 'Next · 12:30 PM',
                    onTap: () => onSelectTab(2),
                  ),
                  _OverviewTile(
                    width: width,
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.blue,
                    label: 'Appointment',
                    value: MockData.upcomingAppointments.first.title,
                    detail:
                        '${MockData.upcomingAppointments.first.dateLabel} · ${MockData.upcomingAppointments.first.timeLabel}',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.appointmentDetails,
                      arguments: MockData.upcomingAppointments.first,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickAction(
                    width: width,
                    label: 'Add BP record',
                    icon: Icons.edit_note_rounded,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.manualRecord),
                  ),
                  _QuickAction(
                    width: width,
                    label: 'Medications',
                    icon: Icons.medication_outlined,
                    onTap: () => onSelectTab(2),
                  ),
                  _QuickAction(
                    width: width,
                    label: 'Appointments',
                    icon: Icons.event_available_outlined,
                    onTap: () => onSelectTab(3),
                  ),
                  _QuickAction(
                    width: width,
                    label: 'Emergency',
                    icon: Icons.sos_rounded,
                    color: AppColors.danger,
                    onTap: () => onSelectTab(6),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'More Care Services',
            subtitle: 'Extra support for everyday care',
          ),
          const SizedBox(height: 12),
          _CareServiceCard(
            icon: Icons.auto_stories_outlined,
            color: AppColors.purple,
            title: 'Journals',
            description: 'Record thoughts, symptoms, moods, and daily moments.',
            onTap: () => onSelectTab(4),
          ),
          const SizedBox(height: 11),
          _CareServiceCard(
            icon: Icons.menu_book_outlined,
            color: AppColors.primaryGreen,
            title: 'Care Book',
            description:
                'Read simplified notes and access the official NIA handbook.',
            onTap: () => onSelectTab(5),
          ),
          const SizedBox(height: 11),
          _CareServiceCard(
            icon: Icons.sos_rounded,
            color: AppColors.danger,
            title: 'Emergency',
            description:
                'Keep essential contacts and medical details close by.',
            onTap: () => onSelectTab(6),
          ),
        ],
      ),
    );
  }
}

class _CareServiceCard extends StatelessWidget {
  const _CareServiceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
          const SizedBox(width: 7),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.secondaryText,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _BloodPressureSummaryCard extends StatelessWidget {
  const _BloodPressureSummaryCard({required this.service, required this.onTap});

  final BpMonitorBleService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final result = service.currentResult;
    final monitorName = _monitorName;
    final statusLabel = _statusLabel;
    return AppCard(
      color: AppColors.darkGreen,
      borderColor: AppColors.darkGreen,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CareCardArtwork(
              assetPath: 'assets/images/bp_card_care_v2.png',
              alignment: Alignment.centerRight,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_statusIcon, color: const Color(0xFFBDE7CB), size: 20),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '$monitorName · ${statusLabel.toUpperCase()}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCFE7D8),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (result == null)
                  _EmptyBloodPressureSummary(message: _emptyStateMessage)
                else
                  _RealBloodPressureSummary(
                    systolic: result.systolic,
                    diastolic: result.diastolic,
                    pulse: result.pulse,
                  ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        result == null
                            ? Icons.monitor_heart_outlined
                            : Icons.bluetooth_connected_rounded,
                        color: const Color(0xFFBDE7CB),
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          result == null
                              ? 'Open My Health to connect and take a real measurement.'
                              : 'Received through BLE · ${_formatResultTime(result.receivedAt)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _monitorName {
    if (service.isConnected) {
      return service.connectedName ??
          service.savedName ??
          BpMonitorBleService.monitorName;
    }
    if (service.hasSavedMonitor) {
      return service.savedName ?? BpMonitorBleService.monitorName;
    }
    if (service.matchingDevices.isNotEmpty) {
      return service.matchingDevices.first.name;
    }
    return 'No monitor selected';
  }

  String get _statusLabel {
    if (service.stage == BpMonitorBleStage.initializing) {
      return 'Checking Bluetooth';
    }
    if (service.stage == BpMonitorBleStage.unsupported) {
      return 'Bluetooth unavailable';
    }
    if (service.stage == BpMonitorBleStage.bluetoothOff) {
      return 'Bluetooth off';
    }
    if (service.stage == BpMonitorBleStage.permissionRequired) {
      return 'Permission required';
    }
    if (service.isCancellingConnection) return 'Canceling connection';
    if (service.isScanning) return 'Searching';
    if (service.isConnecting) return 'Connecting';
    if (service.isListening) {
      if (service.isMeasurementInProgress) return 'Measurement in progress';
      if (service.currentResult != null) return 'Result received';
      return 'Ready and listening';
    }
    if (service.isConnected) return 'Preparing listener';
    if (!service.hasSavedMonitor) {
      return service.matchingDevices.isNotEmpty
          ? 'Monitor detected'
          : 'Not set up';
    }
    if (service.stage == BpMonitorBleStage.monitorNotFound) {
      return 'Monitor not found';
    }
    if (service.lastError != null) return 'Connection issue';
    return 'Saved monitor disconnected';
  }

  IconData get _statusIcon {
    if (service.isListening || service.isConnected) {
      return Icons.bluetooth_connected_rounded;
    }
    if (service.isScanning || service.isConnecting) {
      return Icons.bluetooth_searching_rounded;
    }
    return Icons.bluetooth_disabled_rounded;
  }

  String get _emptyStateMessage {
    if (service.isMeasurementInProgress) {
      return 'A real measurement is in progress on the connected monitor.';
    }
    if (service.isListening) {
      return 'Press Start on the physical monitor when the patient is ready.';
    }
    if (service.isScanning || service.isConnecting) {
      return 'EverCare is working on the real monitor connection.';
    }
    if (!service.hasSavedMonitor) {
      return 'Set up a YK-IBPA1 monitor from My Health to begin.';
    }
    return 'Reconnect the saved monitor from My Health to take a measurement.';
  }

  String _formatResultTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year} · $hour:$minute $period';
  }
}

class _EmptyBloodPressureSummary extends StatelessWidget {
  const _EmptyBloodPressureSummary({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'No real reading received yet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          message,
          style: const TextStyle(
            color: Color(0xFFD9E9DF),
            fontSize: 13.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RealBloodPressureSummary extends StatelessWidget {
  const _RealBloodPressureSummary({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
  });

  final int systolic;
  final int diastolic;
  final int pulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LATEST REAL BLE READING',
          style: TextStyle(
            color: Color(0xFFCFE7D8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$systolic/$diastolic',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 39,
                    height: .95,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.3,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 7, bottom: 3),
              child: Text(
                'mmHg',
                style: TextStyle(
                  color: Color(0xFFCFE7D8),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFFC3BD),
              size: 20,
            ),
            const SizedBox(width: 7),
            Text(
              'Pulse: $pulse BPM',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.width,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.detail,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 19,
                  color: AppColors.secondaryText,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(label, style: AppTextStyles.label),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 7),
            Text(detail, style: AppTextStyles.small),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.width,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppColors.primaryGreen,
  });

  final double width;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 14.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
