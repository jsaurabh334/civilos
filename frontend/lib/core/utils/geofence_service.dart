import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

class GeofenceService {
  // Checks if the current device location is within a radius of the target coordinates
  static Future<bool> isWithinGeofence({
    required double targetLat,
    required double targetLng,
    double radiusInMeters = 500.0,
  }) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them in settings to verify attendance/diary.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied. Geofencing check failed.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    // Calculate distance
    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLat,
      targetLng,
    );

    return distanceInMeters <= radiusInMeters;
  }
}
