import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_client.dart';

typedef WSMessageCallback = void Function(Map<String, dynamic> message);

class WsService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;

  void connect({
    required String token,
    required WSMessageCallback onMessage,
    Function? onConnected,
    Function(String)? onError,
    int tenantId = 0,
  }) {
    _disposed = false;
    final wsBase = ApiClient.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final wsUrl = '$wsBase/ws/chat?tenant_id=$tenantId';

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: [token],
      );

      onConnected?.call();

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String) as Map<String, dynamic>;
            onMessage(decoded);
          } catch (_) {}
        },
        onError: (error) {
          onError?.call(error.toString());
          _scheduleReconnect(token: token, onMessage: onMessage,
            onConnected: onConnected, onError: onError, tenantId: tenantId);
        },
        onDone: () {
          _scheduleReconnect(token: token, onMessage: onMessage,
            onConnected: onConnected, onError: onError, tenantId: tenantId);
        },
        cancelOnError: false,
      );
    } catch (e) {
      onError?.call(e.toString());
      _scheduleReconnect(token: token, onMessage: onMessage,
        onConnected: onConnected, onError: onError, tenantId: tenantId);
    }
  }

  void _scheduleReconnect({
    required String token,
    required WSMessageCallback onMessage,
    Function? onConnected,
    Function(String)? onError,
    int tenantId = 0,
  }) {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_disposed) {
        connect(
          token: token,
          onMessage: onMessage,
          onConnected: onConnected,
          onError: onError,
          tenantId: tenantId,
        );
      }
    });
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
