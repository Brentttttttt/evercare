import 'package:flutter/material.dart';

import '../../repositories/dashboard_repository.dart';
import '../../routes/app_routes.dart';
import '../../services/bp_monitor_ble_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/bp_monitor_ble_scope.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/section_header.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({required this.onSelectTab, super.key});

  final ValueChanged<int> onSelectTab;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  Future<DashboardSummary>? _summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _summary ??= _loadSummary();
  }

  Future<DashboardSummary> _loadSummary() async {
    final client = EverCareBackendScope.maybeClient(context);
    if (client == null || client.auth.currentUser == null) {
      return const DashboardSummary();
    }
    return DashboardRepository(client).load();
  }

  void _reloadSummary() {
    setState(() => _summary = _loadSummary());
  }

  @override
  Widget build(BuildContext context) {
    final bpMonitor = BpMonitorBleScope.watch(context);
    return SingleChildScrollView(
      padding: mainPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _todayLabel(),
            style: AppTextStyles.eyebrow.copyWith(
              color: AppColors.primaryGreen,
              letterSpacing: .85,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<DashboardSummary>(
            future: _summary,
            builder: (context, snapshot) {
              final name = snapshot.data?.fullName;
              return Text(
                name == null ? 'Welcome to EverCare' : '${_greeting()}, $name',
                style: AppTextStyles.display.copyWith(
                  fontSize: 33,
                  letterSpacing: -1.05,
                ),
              );
            },
          ),
          const SizedBox(height: 7),
          const Text(
            'Your caregiving overview for today.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 22),
          const CarePhotoBanner(
            assetPath: 'assets/images/dashboard_care.png',
            semanticLabel:
                'An elderly woman and her daughter reviewing a health notebook at home',
            title: 'Care that feels close to home',
            subtitle: 'Health, medicines, and visits organized in one place.',
            height: 156,
          ),
          const SizedBox(height: 16),
          _BloodPressureSummaryCard(
            service: bpMonitor,
            onTap: () => widget.onSelectTab(1),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Today’s overview'),
          const SizedBox(height: 10),
          FutureBuilder<DashboardSummary>(
            future: _summary,
            builder: (context, snapshot) => _DashboardOverview(
              summary: snapshot.data ?? const DashboardSummary(),
              loading: snapshot.connectionState != ConnectionState.done,
              hasError: snapshot.hasError,
              onRetry: _reloadSummary,
              onMedication: () => widget.onSelectTab(2),
              onAppointment: () => widget.onSelectTab(3),
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 10),
          _QuickActionsPanel(
            actions: [
              _QuickActionData(
                label: 'Add BP record',
                icon: Icons.edit_note_rounded,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.manualRecord),
              ),
              _QuickActionData(
                label: 'Medications',
                icon: Icons.medication_outlined,
                onTap: () => widget.onSelectTab(2),
              ),
              _QuickActionData(
                label: 'Appointments',
                icon: Icons.event_available_outlined,
                onTap: () => widget.onSelectTab(3),
              ),
              _QuickActionData(
                label: 'Emergency',
                icon: Icons.sos_rounded,
                color: AppColors.danger,
                onTap: () => widget.onSelectTab(6),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Care tools',
            subtitle: 'Helpful spaces for everyday caregiving',
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _CareServiceCard(
                  icon: Icons.auto_stories_outlined,
                  color: AppColors.purple,
                  title: 'Journals',
                  description:
                      'Record thoughts, symptoms, moods, and daily moments.',
                  onTap: () => widget.onSelectTab(4),
                ),
                const Divider(height: 1, indent: 80),
                _CareServiceCard(
                  icon: Icons.menu_book_outlined,
                  color: AppColors.primaryGreen,
                  title: 'Care Book',
                  description:
                      'Read simplified notes and access the official NIA handbook.',
                  onTap: () => widget.onSelectTab(5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _todayLabel() {
    const weekdays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview({
    required this.summary,
    required this.loading,
    required this.hasError,
    required this.onRetry,
    required this.onMedication,
    required this.onAppointment,
  });

  final DashboardSummary summary;
  final bool loading;
  final bool hasError;
  final VoidCallback onRetry;
  final VoidCallback onMedication;
  final VoidCallback onAppointment;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AppCard(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Column(
          children: [
            _OverviewLoadingRow(icon: Icons.medication_outlined),
            Divider(height: 1),
            _OverviewLoadingRow(icon: Icons.calendar_month_outlined),
          ],
        ),
      );
    }

    if (hasError) {
      return AppCard(
        color: AppColors.warningContainer,
        borderColor: AppColors.warning.withValues(alpha: .28),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.cloud_off_outlined,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today’s details didn’t refresh',
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Your care pages are still available below.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Column(
        children: [
          _OverviewRow(
            icon: Icons.medication_outlined,
            color: AppColors.primaryGreen,
            label: 'Next medication',
            value: summary.nextMedicationName ?? 'Nothing scheduled',
            detail: summary.nextMedicationTime == null
                ? 'Review medication schedule'
                : 'Scheduled · ${summary.nextMedicationTime}',
            onTap: onMedication,
          ),
          const Divider(height: 1),
          _OverviewRow(
            icon: Icons.calendar_month_outlined,
            color: AppColors.blue,
            label: 'Next appointment',
            value: summary.nextAppointmentTitle ?? 'No upcoming visit',
            detail: _appointmentLabel(summary.nextAppointmentAt),
            onTap: onAppointment,
          ),
        ],
      ),
    );
  }

  String _appointmentLabel(DateTime? value) {
    if (value == null) return 'Open appointments';
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.month}/${value.day}/${value.year} · $hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
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
    return Semantics(
      button: true,
      label: '$title. $description',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppColors.primaryGreen,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({required this.actions});

  final List<_QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final singleColumn = constraints.maxWidth < 300 || textScale > 1.2;
          final width = singleColumn
              ? constraints.maxWidth
              : (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in actions)
                _QuickAction(
                  width: width,
                  label: action.label,
                  icon: action.icon,
                  color: action.color,
                  horizontal: singleColumn,
                  onTap: action.onTap,
                ),
            ],
          );
        },
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
    required this.horizontal,
    this.color = AppColors.primaryGreen,
  });

  final double width;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool horizontal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final iconTile = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 22),
    );
    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: AppColors.background.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(15),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: horizontal
                  ? Row(
                      children: [
                        iconTile,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(label, style: AppTextStyles.cardTitle),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 21,
                          color: AppColors.secondaryText,
                        ),
                      ],
                    )
                  : SizedBox(
                      height: 82,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          iconTile,
                          const Spacer(),
                          Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
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
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 22,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
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
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 22,
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
            fontSize: 25,
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

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$label, $value, $detail',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.small),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewLoadingRow extends StatelessWidget {
  const _OverviewLoadingRow({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading today’s care details',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.secondaryText, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: .38,
                      child: _OverviewSkeletonBar(height: 9),
                    ),
                    SizedBox(height: 8),
                    FractionallySizedBox(
                      widthFactor: .68,
                      child: _OverviewSkeletonBar(height: 13),
                    ),
                    SizedBox(height: 7),
                    FractionallySizedBox(
                      widthFactor: .50,
                      child: _OverviewSkeletonBar(height: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewSkeletonBar extends StatelessWidget {
  const _OverviewSkeletonBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
