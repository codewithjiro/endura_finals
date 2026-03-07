import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Centralized location permission and streaming service.
class LocationService {
  LocationService._();

  /// Check current permission status.
  static Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  /// Request permission from user.
  static Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  /// Returns true if location services are enabled and permission granted.
  static Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Get current position once.
  static Future<Position> getCurrentPosition() =>
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

  /// Stream continuous position updates for workout tracking.
  static Stream<Position> getPositionStream({
    int distanceFilter = 5,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Calculate distance in meters between two coordinates.
  static double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}

