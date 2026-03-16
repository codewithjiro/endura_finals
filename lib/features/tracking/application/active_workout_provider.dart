import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'package:endura/core/utils/formatters.dart';
import 'package:endura/core/utils/location_service.dart';
import 'package:endura/features/profile/user_repository.dart';
import 'package:endura/shared/models/cached_activity.dart';

final activeWorkoutProvider =
    NotifierProvider<ActiveWorkoutController, ActiveWorkoutState>(
  ActiveWorkoutController.new,
);

class ActiveWorkoutState {
  final WorkoutStatus status;
  final ActivityType selectedType;
  final List<LatLng> routePoints;
  final LatLng? currentLocation;
  final double distance; // meters
  final int elapsedSeconds;
  final double calories;
  final double elevationGain;
  final DateTime? startTime;

  const ActiveWorkoutState({
    this.status = WorkoutStatus.idle,
    this.selectedType = ActivityType.walking,
    this.routePoints = const <LatLng>[],
    this.currentLocation,
    this.distance = 0,
    this.elapsedSeconds = 0,
    this.calories = 0,
    this.elevationGain = 0,
    this.startTime,
  });

  bool get isActive =>
      status == WorkoutStatus.tracking || status == WorkoutStatus.paused;

  ActiveWorkoutState copyWith({
    WorkoutStatus? status,
    ActivityType? selectedType,
    List<LatLng>? routePoints,
    LatLng? currentLocation,
    double? distance,
    int? elapsedSeconds,
    double? calories,
    double? elevationGain,
    DateTime? startTime,
  }) {
    return ActiveWorkoutState(
      status: status ?? this.status,
      selectedType: selectedType ?? this.selectedType,
      routePoints: routePoints ?? this.routePoints,
      currentLocation: currentLocation ?? this.currentLocation,
      distance: distance ?? this.distance,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      calories: calories ?? this.calories,
      elevationGain: elevationGain ?? this.elevationGain,
      startTime: startTime ?? this.startTime,
    );
  }
}

enum WorkoutStatus { idle, tracking, paused }

class ActiveWorkoutController extends Notifier<ActiveWorkoutState> {
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;
  DateTime? _lastPositionTime;
  double? _lastAltitude;

  @override
  ActiveWorkoutState build() {
      // Ensure resources are cleaned up when the provider is disposed
      ref.onDispose(() {
          _positionSub?.cancel();
          _timer?.cancel();
      });
      return const ActiveWorkoutState();
  }

  void selectType(ActivityType type) {
    if (state.status != WorkoutStatus.idle) return;
    if (state.selectedType == type) return;
    state = state.copyWith(selectedType: type);
  }

  Future<void> start() async {
    if (state.status == WorkoutStatus.tracking) return;
    _positionSub?.cancel();
    _timer?.cancel();
    _lastAltitude = null;
    _lastPositionTime = null;

    final startTime = DateTime.now();
    state = ActiveWorkoutState(
      status: WorkoutStatus.tracking,
      selectedType: state.selectedType,
      currentLocation: state.currentLocation,
      routePoints: const <LatLng>[],
      distance: 0,
      elapsedSeconds: 0,
      calories: 0,
      elevationGain: 0,
      startTime: startTime,
    );

    _positionSub =
        LocationService.getPositionStream(distanceFilter: 3).listen(_onPosition);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == WorkoutStatus.tracking) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void pause() {
    if (state.status != WorkoutStatus.tracking) return;
    state = state.copyWith(status: WorkoutStatus.paused);
  }

  void resume() {
    if (state.status != WorkoutStatus.paused) return;
    state = state.copyWith(status: WorkoutStatus.tracking);
  }

  Future<CachedActivity?> stop() async {
    if (state.status == WorkoutStatus.idle) return null;

    _positionSub?.cancel();
    _timer?.cancel();
    _positionSub = null;
    _timer = null;

    final activity = _buildActivity();

    _lastAltitude = null;
    _lastPositionTime = null;

    state = ActiveWorkoutState(
      status: WorkoutStatus.idle,
      selectedType: state.selectedType,
      currentLocation: state.currentLocation,
    );

    return activity;
  }

  void _onPosition(Position pos) {
    if (state.status != WorkoutStatus.tracking) return;
    if (pos.accuracy > 20) return;

    final newPoint = LatLng(pos.latitude, pos.longitude);
    final now = DateTime.now();
    final updatedRoute = List<LatLng>.from(state.routePoints);
    double distance = state.distance;

    if (updatedRoute.isNotEmpty) {
      final last = updatedRoute.last;
      final distFromLast = LocationService.distanceBetween(
        last.latitude,
        last.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );

      if (distFromLast < 5) {
        state = state.copyWith(currentLocation: newPoint);
        return;
      }

      if (_lastPositionTime != null) {
        final elapsedSec =
            now.difference(_lastPositionTime!).inMilliseconds / 1000.0;
        if (elapsedSec > 0) {
          final impliedSpeed = distFromLast / elapsedSec;
          if (impliedSpeed > _maxSpeedForActivity) {
            state = state.copyWith(currentLocation: newPoint);
            return;
          }
        }
      }

      distance += distFromLast;
    }

    _lastPositionTime = now;

    double elevationGain = state.elevationGain;
    if (_lastAltitude != null && pos.altitude > _lastAltitude!) {
      elevationGain += pos.altitude - _lastAltitude!;
    }
    _lastAltitude = pos.altitude;

    updatedRoute.add(newPoint);
    final calories = (distance / 1000) * _caloriesPerKm;

    state = state.copyWith(
      routePoints: List.unmodifiable(updatedRoute),
      distance: distance,
      elevationGain: elevationGain,
      calories: calories,
      currentLocation: newPoint,
    );
  }

  double get _maxSpeedForActivity {
    switch (state.selectedType) {
      case ActivityType.running:
        return LocationService.maxSpeedRunning;
      case ActivityType.cycling:
        return LocationService.maxSpeedCycling;
      case ActivityType.walking:
        return LocationService.maxSpeedWalking;
      case ActivityType.hiking:
        return LocationService.maxSpeedHiking;
      case ActivityType.riding:
        return LocationService.maxSpeedRiding;
    }
  }

  double get _caloriesPerKm {
    switch (state.selectedType) {
      case ActivityType.running:
        return 62;
      case ActivityType.cycling:
        return 30;
      case ActivityType.walking:
        return 45;
      case ActivityType.hiking:
        return 55;
      case ActivityType.riding:
        return 10;
    }
  }

  CachedActivity _buildActivity() {
    final userId = UserRepository.getProfile()?.id ?? '';
    final durationSeconds = state.elapsedSeconds;
    final distanceKm = state.distance / 1000;
    return CachedActivity(
      localId: const Uuid().v4(),
      userId: userId,
      type: state.selectedType,
      distance: state.distance,
      duration: durationSeconds,
      avgPace: Formatters.pace(
        Duration(seconds: durationSeconds),
        state.distance,
      ),
      avgSpeed: durationSeconds > 0
          ? (distanceKm) / (durationSeconds / 3600)
          : 0,
      calories: state.calories,
      elevationGain: state.elevationGain,
      routePoints: state.routePoints
          .map((p) => <double>[p.latitude, p.longitude])
          .toList(),
      startTime: state.startTime ?? DateTime.now(),
      endTime: DateTime.now(),
    );
  }
}
