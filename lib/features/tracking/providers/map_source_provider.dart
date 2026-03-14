import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endura/core/maps/map_tile_source.dart';

final trackingMapSourceProvider =
    AsyncNotifierProvider<TrackingMapSourceController, MapTileSource>(
  TrackingMapSourceController.new,
);

class TrackingMapSourceController extends AsyncNotifier<MapTileSource> {
  @override
  Future<MapTileSource> build() async {
    return MapTileSources.loadSelected();
  }

  Future<void> setSource(MapTileSource source) async {
    final current = state.value;
    if (current?.id == source.id) return;

    state = AsyncData(source);
    await MapTileSources.saveSelected(source.id);
  }
}
