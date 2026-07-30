import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../repositories/notification_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
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
          child: Text(_updating ? 'Updating…' : 'Mark all'),
        ),
      ],
      child: _buildContent(grouped),
    );
  }

  Widget _buildContent(Map<String, List<AppNotification>> grouped) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(36),
          child: CircularProgressIndicator(),
        ),
      );
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
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final item in group.value.indexed) ...[
                  ListTile(
                    minTileHeight: 76,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        _iconFor(item.$2.kind),
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    title: Text(
                      item.$2.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: item.$2.isRead
                            ? FontWeight.w600
                            : FontWeight.w800,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${item.$2.body}\n${_timeLabel(item.$2.createdAt)}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: item.$2.isRead
                        ? null
                        : const CircleAvatar(
                            radius: 5,
                            backgroundColor: AppColors.primaryGreen,
                          ),
                    onTap: () => _openNotification(item.$2),
                  ),
                  if (item.$1 < group.value.length - 1)
                    const Divider(height: 1, indent: 76),
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
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          _iconFor(notification.kind),
          color: AppColors.primaryGreen,
          size: 34,
        ),
        title: Text(notification.title),
        content: Text(notification.body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
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

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: AppColors.danger,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
