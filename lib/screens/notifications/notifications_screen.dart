import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../repositories/notification_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/section_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationRepository? _repository;
  List<AppNotification> _notifications = const [];
  bool _initialized = false;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final client = EverCareBackendScope.maybeClient(context);
    if (client?.auth.currentUser == null) {
      _loading = false;
      return;
    }
    _repository = NotificationRepository(client!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<AppNotification>>{};
    for (final notification in _notifications) {
      grouped
          .putIfAbsent(_groupLabel(notification.createdAt), () => [])
          .add(notification);
    }
    final hasUnread = _notifications.any(
      (notification) => !notification.isRead,
    );

    return DetailPage(
      title: 'Notifications',
      actions: [
        TextButton(
          onPressed: hasUnread && !_updating ? _markAllRead : null,
          child: _updating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Mark read'),
        ),
      ],
      child: _buildContent(grouped),
    );
  }

  Widget _buildContent(Map<String, List<AppNotification>> grouped) {
    if (_loading) {
      return const _NotificationsLoading();
    }
    if (_repository == null) {
      return const EmptyStateCard(
        title: 'Sign in to see notifications',
        message: 'Updates connected to your EverCare account will appear here.',
        icon: Icons.lock_outline_rounded,
      );
    }
    if (_error != null) {
      return _NotificationError(message: _error!, onRetry: _load);
    }
    if (_notifications.isEmpty) {
      return const EmptyStateCard(
        title: 'No notifications',
        message: 'Important EverCare updates will appear here when available.',
        icon: Icons.notifications_none_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in grouped.entries) ...[
          SectionHeader(title: group.key),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final item in group.value.indexed) ...[
                  _NotificationRow(
                    notification: item.$2,
                    icon: _iconFor(item.$2.kind),
                    timeLabel: _timeLabel(item.$2.createdAt),
                    onTap: () => _openNotification(item.$2),
                  ),
                  if (item.$1 < group.value.length - 1)
                    const Divider(height: 1, indent: 76, endIndent: 16),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
      ],
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifications = await _repository!.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'EverCare could not load notifications. Please try again.';
      });
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _updating = true);
    try {
      await _repository!.markAllRead();
      if (!mounted) return;
      setState(() {
        _updating = false;
        _notifications = _notifications
            .map((item) => item.copyWith(isRead: true))
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _updating = false);
      _showError('EverCare could not update notifications.');
    }
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.isRead) {
      try {
        await _repository!.markRead(notification.id);
        if (!mounted) return;
        setState(() {
          _notifications = _notifications
              .map(
                (item) => item.id == notification.id
                    ? item.copyWith(isRead: true)
                    : item,
              )
              .toList(growable: false);
        });
      } catch (_) {
        if (!mounted) return;
        _showError('EverCare could not mark this notification as read.');
      }
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => _NotificationDetailSheet(
        notification: notification,
        icon: _iconFor(notification.kind),
        timeLabel: _fullTimeLabel(notification.createdAt),
        onDone: () => Navigator.pop(sheetContext),
      ),
    );
  }

  String _groupLabel(DateTime value) {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = DateUtils.dateOnly(value);
    final difference = today.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return 'Earlier';
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _fullTimeLabel(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year} • '
        '${_timeLabel(value)}';
  }

  IconData _iconFor(String kind) => switch (kind.toLowerCase()) {
    'medication' => Icons.medication_outlined,
    'appointment' => Icons.event_outlined,
    'health' || 'blood_pressure' => Icons.monitor_heart_outlined,
    'emergency' => Icons.sos_outlined,
    'caregiver' => Icons.people_outline_rounded,
    _ => Icons.notifications_none_rounded,
  };

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  const _NotificationDetailSheet({
    required this.notification,
    required this.icon,
    required this.timeLabel,
    required this.onDone,
  });

  final AppNotification notification;
  final IconData icon;
  final String timeLabel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .78,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Notification', style: AppTextStyles.cardTitle),
                ),
                TextButton(onPressed: onDone, child: const Text('Done')),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: .1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 25),
            ),
            const SizedBox(height: 18),
            Text(notification.title, style: AppTextStyles.pageTitle),
            const SizedBox(height: 7),
            Text(timeLabel, style: AppTextStyles.bodyMuted),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SelectableText(
                notification.body,
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading notifications',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 72, height: 18, borderRadius: 6),
          SizedBox(height: 12),
          AppCardSkeleton(lines: 3),
          SizedBox(height: 12),
          AppCardSkeleton(lines: 3),
          SizedBox(height: 12),
          AppCardSkeleton(lines: 3),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.icon,
    required this.timeLabel,
    required this.onTap,
  });

  final AppNotification notification;
  final IconData icon;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Semantics(
      button: true,
      label: unread
          ? 'Unread notification: ${notification.title}'
          : 'Notification: ${notification.title}',
      child: Material(
        color: unread
            ? AppColors.accent.withValues(alpha: .42)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: unread ? AppColors.primaryGreen : AppColors.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: unread ? Colors.white : AppColors.mutedForeground,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTextStyles.cardTitle.copyWith(
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'New',
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.primaryContainerForeground,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMuted,
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.mutedForeground,
                          ),
                          const SizedBox(width: 5),
                          Text(timeLabel, style: AppTextStyles.small),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      title: 'Notifications unavailable',
      message: message,
      icon: Icons.cloud_off_outlined,
      actionLabel: 'Try Again',
      actionIcon: Icons.refresh_rounded,
      onAction: onRetry,
    );
  }
}
