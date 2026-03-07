import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:endura/core/theme/app_theme.dart';

/// Helpers for creating polylines for route rendering.
class PolylineHelper {
  PolylineHelper._();

  /// Primary route polyline (active workout, saved activity).
  static Polyline route(List<LatLng> points, {Color? color, double width = 4}) {
    return Polyline(
      points: points,
      color: color ?? AppTheme.primary,
      strokeWidth: width,
      borderColor: const Color(0x40000000),
      borderStrokeWidth: 1,
    );
  }

  /// Preview polyline (feed, explore).
  static Polyline preview(List<LatLng> points) {
    return Polyline(
      points: points,
      color: AppTheme.primary.withValues(alpha: 0.7),
      strokeWidth: 3,
    );
  }

  /// Segment overlay polyline.
  static Polyline segment(List<LatLng> points) {
    return Polyline(
      points: points,
      color: AppTheme.warning,
      strokeWidth: 5,
    );
  }
}


