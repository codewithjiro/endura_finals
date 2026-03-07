import 'package:latlong2/latlong.dart';

/// Stadia Maps configuration.
///
/// For production, replace the API key below or load from env.
/// Free tier: https://stadiamaps.com/
class StadiaMapConfig {
  StadiaMapConfig._();

  /// Replace with your Stadia Maps API key.
  static const String apiKey = 'd65e479b-f622-4d71-94d8-163d01c3aa7d';

  /// Default center (San Francisco).
  static final LatLng defaultCenter = LatLng(37.7749, -122.4194);

  /// Default zoom level.
  static const double defaultZoom = 14.0;

  /// Min zoom.
  static const double minZoom = 3.0;

  /// Max zoom.
  static const double maxZoom = 18.0;

  /// Attribution text.
  static const String attribution =
      '© Stadia Maps © OpenMapTiles © OpenStreetMap';
}


