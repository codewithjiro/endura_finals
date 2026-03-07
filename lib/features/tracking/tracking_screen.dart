import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:endura/core/theme/app_theme.dart';
import 'package:endura/core/maps/endura_map.dart';
import 'package:endura/core/maps/polyline_helper.dart';
import 'package:endura/core/maps/marker_helper.dart';
import 'package:endura/core/utils/location_service.dart';
import 'package:endura/core/utils/formatters.dart';
import 'package:endura/shared/models/cached_activity.dart';
import 'package:endura/features/activity/summary_screen.dart';

/// Track tab — live workout recording with map.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

enum _WorkoutState { idle, tracking, paused }

class _TrackingScreenState extends State<TrackingScreen> {
  _WorkoutState _state = _WorkoutState.idle;
  ActivityType _selectedType = ActivityType.running;
  bool _permissionGranted = false;
  bool _checkingPermission = true;

  // Workout data
  final List<LatLng> _routePoints = [];
  LatLng? _currentLocation;
  double _distance = 0; // meters
  int _elapsedSeconds = 0;
  double _calories = 0;
  double _elevationGain = 0;
  DateTime? _startTime;
  double? _lastAltitude;

  StreamSubscription<Position>? _positionSub;
  Timer? _timer;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await LocationService.ensurePermission();
    if (mounted) {
      setState(() {
        _permissionGranted = granted;
        _checkingPermission = false;
      });
      if (granted) _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (_) {}
  }

  void _startWorkout() {
    _routePoints.clear();
    _distance = 0;
    _elapsedSeconds = 0;
    _calories = 0;
    _elevationGain = 0;
    _lastAltitude = null;
    _startTime = DateTime.now();

    _positionSub = LocationService.getPositionStream(distanceFilter: 5)
        .listen(_onPosition);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state == _WorkoutState.tracking && mounted) {
        setState(() => _elapsedSeconds++);
      }
    });

    setState(() => _state = _WorkoutState.tracking);
  }

  void _onPosition(Position pos) {
    if (_state != _WorkoutState.tracking) return;
    final newPoint = LatLng(pos.latitude, pos.longitude);

    setState(() {
      if (_routePoints.isNotEmpty) {
        final last = _routePoints.last;
        _distance += LocationService.distanceBetween(
          last.latitude, last.longitude,
          newPoint.latitude, newPoint.longitude,
        );
      }

      // Elevation tracking
      if (_lastAltitude != null && pos.altitude > _lastAltitude!) {
        _elevationGain += pos.altitude - _lastAltitude!;
      }
      _lastAltitude = pos.altitude;

      // Calorie estimation (rough: ~60 cal/km running)
      _calories = (_distance / 1000) * _caloriesPerKm;

      _routePoints.add(newPoint);
      _currentLocation = newPoint;
    });

    // Auto-follow
    try {
      _mapController.move(newPoint, _mapController.camera.zoom);
    } catch (_) {}
  }

  double get _caloriesPerKm {
    switch (_selectedType) {
      case ActivityType.running:
        return 62;
      case ActivityType.cycling:
        return 30;
      case ActivityType.walking:
        return 45;
      case ActivityType.hiking:
        return 55;
    }
  }

  void _confirmStop() {
    // Pause while user decides
    if (_state == _WorkoutState.tracking) {
      _pauseWorkout();
    }

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Finish Workout?'),
        content: const Text('Do you want to stop and save this workout?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Resume'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _resumeWorkout();
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Finish'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _stopWorkout();
            },
          ),
        ],
      ),
    );
  }

  void _pauseWorkout() => setState(() => _state = _WorkoutState.paused);

  void _resumeWorkout() => setState(() => _state = _WorkoutState.tracking);

  void _stopWorkout() {
    _positionSub?.cancel();
    _timer?.cancel();

    final activity = CachedActivity(
      localId: const Uuid().v4(),
      userId: '', // Will be filled by summary screen
      type: _selectedType,
      distance: _distance,
      duration: _elapsedSeconds,
      avgPace: Formatters.pace(Duration(seconds: _elapsedSeconds), _distance),
      avgSpeed: _elapsedSeconds > 0
          ? (_distance / 1000) / (_elapsedSeconds / 3600)
          : 0,
      calories: _calories,
      elevationGain: _elevationGain,
      routePoints: _routePoints.map((p) => [p.latitude, p.longitude]).toList(),
      startTime: _startTime ?? DateTime.now(),
      endTime: DateTime.now(),
    );

    setState(() => _state = _WorkoutState.idle);

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => SummaryScreen(activity: activity),
      ),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermission) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Track')),
        child: Center(child: CupertinoActivityIndicator(radius: 16)),
      );
    }

    if (!_permissionGranted) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Track')),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.location_slash_fill,
                  size: 48, color: CupertinoColors.systemGrey3),
              const SizedBox(height: 16),
              const Text('Location Permission Required',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Enable location to track workouts.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              CupertinoButton.filled(
                onPressed: _checkPermission,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Map
          EnduraMap(
            center: _currentLocation,
            zoom: 16,
            mapController: _mapController,
            interactive: true,
            polylines: _routePoints.length >= 2
                ? [PolylineHelper.route(_routePoints, color: const Color(0xFFFC4C02), width: 5)]
                : [],
            markers: [
              if (_routePoints.isNotEmpty)
                MarkerHelper.start(_routePoints.first),
              if (_currentLocation != null && _state != _WorkoutState.idle)
                MarkerHelper.currentLocation(_currentLocation!),
            ],
          ),

          // Stats overlay
          if (_state != _WorkoutState.idle)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(AppTheme.spacingMd),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x1A000000),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Time',
                        value: Formatters.duration(
                            Duration(seconds: _elapsedSeconds)),
                      ),
                      _StatColumn(
                        label: 'Distance',
                        value: Formatters.distanceKm(_distance),
                      ),
                      _StatColumn(
                        label: 'Pace',
                        value: Formatters.pace(
                            Duration(seconds: _elapsedSeconds), _distance),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context).withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1A000000),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: _state == _WorkoutState.idle
                    ? _buildIdleControls()
                    : _buildActiveControls(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Activity type picker
        CupertinoSlidingSegmentedControl<ActivityType>(
          groupValue: _selectedType,
          children: {
            for (final type in ActivityType.values)
              type: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(type.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
          },
          onValueChanged: (v) {
            if (v != null) setState(() => _selectedType = v);
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            onPressed: _startWorkout,
            child: const Text('Start Workout',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Stop button
        GestureDetector(
          onTap: _confirmStop,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.danger,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.danger.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(CupertinoIcons.stop_fill,
                color: CupertinoColors.white, size: 24),
          ),
        ),
        // Pause/Resume button
        GestureDetector(
          onTap: _state == _WorkoutState.paused
              ? _resumeWorkout
              : _pauseWorkout,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              _state == _WorkoutState.paused
                  ? CupertinoIcons.play_fill
                  : CupertinoIcons.pause_fill,
              color: CupertinoColors.white,
              size: 30,
            ),
          ),
        ),
        // Spacer for symmetry
        const SizedBox(width: 60, height: 60),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor(context))),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}








