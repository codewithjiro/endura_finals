import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endura/features/activity/data/activity_repository.dart';
import 'package:endura/shared/models/cached_activity.dart';

final activityRepositoryListenableProvider = Provider<ValueListenable<Object?>>((ref) {
  final listenable = ActivityRepository.listenable;
  void listener() => ref.invalidateSelf();
  listenable.addListener(listener);
  ref.onDispose(() => listenable.removeListener(listener));
  return listenable;
});

final activityListProvider = Provider<List<CachedActivity>>((ref) {
  ref.watch(activityRepositoryListenableProvider);
  return ActivityRepository.getAll();
});

final activityByIdProvider = Provider.family<CachedActivity?, String>((ref, localId) {
  ref.watch(activityRepositoryListenableProvider);
  return ActivityRepository.getById(localId);
});

final activityWithRoutesProvider = Provider<List<CachedActivity>>((ref) {
  final activities = ref.watch(activityListProvider);
  return activities.where((activity) => activity.routePoints.length >= 2).toList();
});

final activityStatsProvider = Provider<ActivityStats>((ref) {
  final activities = ref.watch(activityListProvider);
  final totalDistance = activities.fold<double>(0, (sum, activity) => sum + activity.distance);
  final totalSeconds = activities.fold<int>(0, (sum, activity) => sum + activity.duration);
  return ActivityStats(
    count: activities.length,
    totalDistance: totalDistance,
    totalDuration: Duration(seconds: totalSeconds),
  );
});

class ActivityStats {
  final int count;
  final double totalDistance;
  final Duration totalDuration;

  const ActivityStats({
    required this.count,
    required this.totalDistance,
    required this.totalDuration,
  });
}
