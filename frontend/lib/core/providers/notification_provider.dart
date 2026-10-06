import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';
import '../ws_service.dart';

class NotificationState {
  final bool isLoading;
  final List<dynamic> notifications;
  final int unreadCount;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<dynamic>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  WsService? _ws;

  @override
  NotificationState build() {
    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated && prev?.token != next.token) {
        connectWS();
        fetchNotifications();
      } else if (!next.isAuthenticated) {
        disconnectWS();
      }
    });
    return const NotificationState();
  }

  void _onWSMessage(Map<String, dynamic> msg) {
    final msgId = msg['id'];
    if (msgId != null && state.notifications.any((n) => n['id'] == msgId)) {
      return; // deduplicate
    }
    final updated = [msg, ...state.notifications];
    state = state.copyWith(
      notifications: updated,
      unreadCount: state.unreadCount + 1,
    );
  }

  void connectWS() {
    final auth = ref.read(authProvider);
    final token = auth.token;
    if (token == null || _ws != null) return;

    _ws = WsService();
    _ws!.connect(
      token: token,
      onMessage: _onWSMessage,
      tenantId: auth.currentTenant?['id'] ?? 0,
    );
  }

  void disconnectWS() {
    _ws?.disconnect();
    _ws = null;
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/notifications');
      if (response is Map) {
        state = state.copyWith(
          isLoading: false,
          notifications: response['notifications'] is List ? response['notifications'] : [],
          unreadCount: response['unread_count'] ?? 0,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await ref.read(apiClientProvider).put('/notifications/$id/read', {});
      await fetchNotifications();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await ref.read(apiClientProvider).put('/notifications/all/read', {});
      await fetchNotifications();
    } catch (_) {}
  }

  Future<void> clearNotifications() async {
    try {
      await ref.read(apiClientProvider).delete('/notifications/all');
      state = const NotificationState();
    } catch (_) {}
  }

  Future<void> deleteNotification(int id) async {
    try {
      await ref.read(apiClientProvider).delete('/notifications/$id');
      await fetchNotifications();
    } catch (_) {}
  }

  void addLocalNotification(Map<String, dynamic> notif) {
    state = state.copyWith(notifications: [notif, ...state.notifications]);
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(() => NotificationNotifier());
