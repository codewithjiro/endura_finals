import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:endura/core/utils/formatters.dart';
import 'package:endura/shared/models/cached_activity.dart'; // Add this to see ActivityTypeX
import 'package:endura/features/tracking/application/active_workout_provider.dart';

final workoutNotificationServiceProvider =
    Provider<WorkoutNotificationService>((ref) {
  final service = WorkoutNotificationService(ref);
  return service;
});

class WorkoutNotificationService {
  WorkoutNotificationService(this._ref) {
    _ref.listen<ActiveWorkoutState>(
      activeWorkoutProvider,
      (previous, next) => _handleWorkoutChange(previous, next),
    );
  }

  static const _notificationId = 4101;
  static const _androidChannelId = 'active_workout_channel';
  static const _androidChannelName = 'Active workout';
  static const _androidChannelDescription =
      'Shows live workout progress with quick actions.';

  static const _actionPause = 'workout_pause';
  static const _actionResume = 'workout_resume';
  static const _actionEnd = 'workout_end';

  static const _iosActiveCategory = 'active_workout_active';
  static const _iosPausedCategory = 'active_workout_paused';

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionsRequested = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final darwinSettings = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          _iosActiveCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              _actionPause,
              'Pause',
            ),
            DarwinNotificationAction.plain(
              _actionEnd,
              'End',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
        DarwinNotificationCategory(
          _iosPausedCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              _actionResume,
              'Resume',
            ),
            DarwinNotificationAction.plain(
              _actionEnd,
              'End',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
      ],
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> _handleWorkoutChange(
    ActiveWorkoutState? previous,
    ActiveWorkoutState next,
  ) async {
    if (!_initialized) return;

    if (!next.isActive) {
      if (previous?.isActive ?? false) {
        await _plugin.cancel(_notificationId);
      }
      return;
    }

    await _ensurePermissions();
    await _showOrUpdate(next);
  }

  Future<void> _ensurePermissions() async {
    if (_permissionsRequested) return;
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _permissionsRequested = true;
  }

  Future<void> _showOrUpdate(ActiveWorkoutState state) async {
    final duration =
        Formatters.durationTrack(Duration(seconds: state.elapsedSeconds));
    final distanceKm = state.distance / 1000;
    final distanceLabel = distanceKm >= 100
        ? distanceKm.toStringAsFixed(1)
        : distanceKm.toStringAsFixed(2);
    final calories = state.calories.toStringAsFixed(0);

    final titlePrefix =
        state.status == WorkoutStatus.paused ? 'Paused' : 'Tracking';
    final title = '$titlePrefix ${state.selectedType.label}';
    final body = '$duration • $distanceLabel km • $calories kcal';

    final androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.status,
      ticker: 'Workout running',
      actions: state.status == WorkoutStatus.paused
          ? const [
              AndroidNotificationAction(
                _actionResume,
                'Resume',
                showsUserInterface: false,
              ),
              AndroidNotificationAction(
                _actionEnd,
                'End',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ]
          : const [
              AndroidNotificationAction(
                _actionPause,
                'Pause',
                showsUserInterface: false,
              ),
              AndroidNotificationAction(
                _actionEnd,
                'End',
                showsUserInterface: false,
                cancelNotification: true,
              ),
            ],
    );

    final darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: state.status == WorkoutStatus.paused
          ? _iosPausedCategory
          : _iosActiveCategory,
      interruptionLevel: InterruptionLevel.timeSensitive,
      presentAlert: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      _notificationId,
      title,
      body,
      details,
      payload: 'active_workout',
    );
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    final actionId = response.actionId;
    if (actionId == null || actionId.isEmpty) return;

    final controller = _ref.read(activeWorkoutProvider.notifier);

    switch (actionId) {
      case _actionPause:
        controller.pause();
        break;
      case _actionResume:
        controller.resume();
        break;
      case _actionEnd:
        await controller.stop();
        break;
    }
  }
}
