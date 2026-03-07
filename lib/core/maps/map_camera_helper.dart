import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Helpers for fitting map camera to bounds, centering, etc.
class MapCameraHelper {
  MapCameraHelper._();

  /// Create CameraFit to show all points with padding.
  static CameraFit fitBounds(List<LatLng> points, {double padding = 50}) {
    if (points.isEmpty) {
      return CameraFit.bounds(
        bounds: LatLngBounds(LatLng(0, 0), LatLng(0, 0)),
        padding: EdgeInsets.all(padding),
      );
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // Add small buffer for single-point routes
    if (minLat == maxLat && minLng == maxLng) {
      minLat -= 0.002;
      maxLat += 0.002;
      minLng -= 0.002;
      maxLng += 0.002;
    }

    return CameraFit.bounds(
      bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
      padding: EdgeInsets.all(padding),
    );
  }
}
