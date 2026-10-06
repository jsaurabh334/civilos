import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_client.dart';

class FcmService {
  static String? pendingRoute;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Notification is received while app is in foreground
      // The WebSocket listener will handle in-app display
    });

    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      pendingRoute = _extractRoute(message);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      pendingRoute = _extractRoute(initialMessage);
    }
  }

  static String? _extractRoute(RemoteMessage message) {
    final route = message.data['route'] ?? message.data['screen'];
    if (route != null && route.toString().isNotEmpty) {
      return route.toString();
    }
    return null;
  }

  static String? consumePendingRoute() {
    final route = pendingRoute;
    pendingRoute = null;
    return route;
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
  }

  static Future<void> _registerToken(String token) async {
    try {
      final client = ApiClient();
      await client.post('/auth/fcm-token', {'token': token});
    } catch (_) {}
  }
}
