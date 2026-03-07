import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:endura/core/theme/app_theme.dart';

/// Helpers for creating markers on the map.
class MarkerHelper {
  MarkerHelper._();

  /// Start marker — green circle.
  static Marker start(LatLng point) {
    return Marker(
      point: point,
      width: 20,
      height: 20,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.success,
          shape: BoxShape.circle,
          border: Border.all(color: CupertinoColors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0x40000000),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  /// End marker — red circle.
  static Marker end(LatLng point) {
    return Marker(
      point: point,
      width: 20,
      height: 20,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.danger,
          shape: BoxShape.circle,
          border: Border.all(color: CupertinoColors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0x40000000),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  /// Current user location marker — primary pulsing dot.
  static Marker currentLocation(LatLng point) {
    return Marker(
      point: point,
      width: 24,
      height: 24,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: CupertinoColors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}


