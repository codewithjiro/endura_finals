import 'package:endura/core/maps/stadia_map_config.dart';

/// Tile URL templates for Stadia Maps styles.
class StadiaTileUrls {
  StadiaTileUrls._();

  static String _appendKey(String base) {
    if (StadiaMapConfig.apiKey.isEmpty) return base;
    return '$base?api_key=${StadiaMapConfig.apiKey}';
  }

  /// Alidade Smooth — clean light style (default).
  static String get alidadeSmooth =>
      _appendKey('https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png');

  /// Alidade Smooth Dark — dark mode.
  static String get alidadeSmoothDark =>
      _appendKey('https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png');

  /// Outdoors — topographic/outdoor style.
  static String get outdoors =>
      _appendKey('https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png');

  /// OSM Bright — standard map style.
  static String get osmBright =>
      _appendKey('https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}{r}.png');
}


