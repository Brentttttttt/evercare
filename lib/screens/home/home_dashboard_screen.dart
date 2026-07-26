import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/blood_pressure_widgets.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/section_header.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({required this.onSelectTab, super.key});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
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
            'Your connected health snapshot for today.',
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
          _BloodPressureSummaryCard(onTap: () => onSelectTab(1)),
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
                'Read simple, practical lessons for everyday caregiving.',
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
  const _BloodPressureSummaryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final record = MockData.latestBloodPressure;
    return AppCard(
      color: AppColors.darkGreen,
      borderColor: AppColors.darkGreen,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CareCardArtwork(
              assetPath: 'assets/images/bp_monitor_home.png',
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
                    const Icon(
                      Icons.bluetooth_connected_rounded,
                      color: Color(0xFFBDE7CB),
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        'YK-BPA1 · CONNECTED',
                        style: TextStyle(
                          color: Color(0xFFCFE7D8),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                    BloodPressureStatusBadge(status: record.status),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'BLOOD PRESSURE',
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
                          '${record.systolic}/${record.diastolic}',
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
                      'Pulse: ${record.pulse} BPM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
                  child: const Row(
                    children: [
                      Icon(
                        Icons.sync_rounded,
                        color: Color(0xFFBDE7CB),
                        size: 20,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Synced today at 8:45 AM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
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
