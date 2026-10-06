import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../api_client.dart';
import '../auth_provider.dart';

class LocationService {
  final Ref ref;
  Timer? _timer;

  LocationService(this.ref);

  Future<void> startTracking() async {
    // Only track if user is Supervisor
    final authState = ref.read(authProvider);
    if (authState.currentUser?['role'] != 'Supervisor') {
      return;
    }

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Ping every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _pingLocation();
    });
    
    // Initial ping
    _pingLocation();
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pingLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      await ref.read(apiClientProvider).post('/users/me/location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail if location fetching fails in background
      print('Location ping failed: $e');
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref);
});
