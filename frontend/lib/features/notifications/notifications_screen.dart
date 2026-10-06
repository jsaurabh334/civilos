import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme.dart';
import '../../core/empty_state.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).connectWS();
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  @override
  void dispose() {
    ref.read(notificationProvider.notifier).disconnectWS();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notif = ref.watch(notificationProvider);
    final notifications = notif.notifications;

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF222B38), Color(0xFF161F2E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 600 : 800),
                  child: Column(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Notifications',
                                  style: const TextStyle(
                                      color: CivilTheme.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              if (notifications.isNotEmpty)
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        ref.read(notificationProvider.notifier).markAllAsRead();
                                      },
                                      icon: const Icon(Icons.done_all,
                                          color: Colors.greenAccent, size: 20),
                                      label: const Text('Mark Read',
                                          style: TextStyle(color: Colors.greenAccent)),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () {
                                        ref.read(notificationProvider.notifier).clearNotifications();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('All cleared')));
                                      },
                                      icon: const Icon(Icons.clear_all,
                                          color: Colors.redAccent, size: 20),
                                      label: const Text('Clear All',
                                          style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (notif.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Expanded(
                          child: notifications.isEmpty
                              ? EmptyState(
                                  icon: Icons.notifications_none,
                                  title: 'No notifications',
                                  subtitle: 'You\'re all caught up!',
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: notifications.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final notification = notifications[index]
                                        as Map<String, dynamic>;
                                    final title =
                                        notification['title']?.toString() ?? '';
                                    final message =
                                        notification['message']?.toString() ?? '';
                                    final createdAt =
                                        notification['created_at']?.toString() ?? '';
                                    final isRead =
                                        notification['read'] == true;
                                    final notifId =
                                        notification['id'] as int? ?? 0;

                                    return Dismissible(
                                      key: Key('notif_$notifId'),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (_) {
                                        ref.read(notificationProvider.notifier).deleteNotification(notifId);
                                      },
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            borderRadius: BorderRadius.circular(16)),
                                        child: const Icon(Icons.delete_outline,
                                            color: Colors.white),
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          if (!isRead) {
                                            ref.read(notificationProvider.notifier).markAsRead(notifId);
                                          }
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: CivilTheme.surface.withValues(alpha: isRead ? 0.4 : 0.6),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                                color: isRead
                                                    ? Colors.white.withValues(alpha: 0.05)
                                                    : Colors.blueAccent.withValues(alpha: 0.2)),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: isRead
                                                      ? Colors.grey.withValues(alpha: 0.15)
                                                      : Colors.blueAccent.withValues(alpha: 0.15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                    isRead
                                                        ? Icons.notifications_none
                                                        : Icons.notifications_active,
                                                    color: isRead
                                                        ? CivilTheme.textSecondary
                                                        : Colors.blueAccent,
                                                    size: 20),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(title,
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: isRead
                                                                ? CivilTheme.textSecondary
                                                                : CivilTheme.textPrimary)),
                                                    const SizedBox(height: 4),
                                                    Text(message,
                                                        style: const TextStyle(
                                                            color: CivilTheme.textSecondary,
                                                            fontSize: 14)),
                                                    if (createdAt.isNotEmpty) ...[
                                                      const SizedBox(height: 8),
                                                      Text(_timeAgo(createdAt),
                                                          style: TextStyle(
                                                              color: isRead
                                                                  ? CivilTheme.textSecondary
                                                                  : Colors.blueAccent,
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold)),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 8, height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.blueAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _timeAgo(String isoTimestamp) {
    try {
      final dt = DateTime.parse(isoTimestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return isoTimestamp;
    }
  }
}
