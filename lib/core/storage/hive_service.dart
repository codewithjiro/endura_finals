import 'package:hive_flutter/hive_flutter.dart';
import 'package:endura/core/storage/hive_boxes.dart';

/// Centralized Hive initialization and box management.
class HiveService {
  HiveService._();

  static bool _initialized = false;

  /// Initialize Hive and open all required boxes.
  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await _openBoxes();
    _initialized = true;
  }

  static Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox(HiveBoxes.database),
      Hive.openBox<Map>(HiveBoxes.user),
      Hive.openBox<Map>(HiveBoxes.settings),
      Hive.openBox<Map>(HiveBoxes.activities),
      Hive.openBox<Map>(HiveBoxes.activeWorkout),
      Hive.openBox<Map>(HiveBoxes.feed),
      Hive.openBox<Map>(HiveBoxes.challenges),
      Hive.openBox<Map>(HiveBoxes.routes),
      Hive.openBox<Map>(HiveBoxes.notifications),
      Hive.openBox<Map>(HiveBoxes.media),
    ]);
  }

  // ── Typed box accessors ─────────────────────────────────────────────

  static Box get databaseBox => Hive.box(HiveBoxes.database);
  static Box<Map> get userBox => Hive.box<Map>(HiveBoxes.user);
  static Box<Map> get settingsBox => Hive.box<Map>(HiveBoxes.settings);
  static Box<Map> get activitiesBox => Hive.box<Map>(HiveBoxes.activities);
  static Box<Map> get activeWorkoutBox => Hive.box<Map>(HiveBoxes.activeWorkout);
  static Box<Map> get feedBox => Hive.box<Map>(HiveBoxes.feed);
  static Box<Map> get challengeBox => Hive.box<Map>(HiveBoxes.challenges);
  static Box<Map> get routesBox => Hive.box<Map>(HiveBoxes.routes);
  static Box<Map> get notificationsBox => Hive.box<Map>(HiveBoxes.notifications);
  static Box<Map> get mediaBox => Hive.box<Map>(HiveBoxes.media);

  /// Wipe all boxes — useful for logout.
  static Future<void> clearAll() async {
    await Future.wait([
      userBox.clear(),
      settingsBox.clear(),
      activitiesBox.clear(),
      activeWorkoutBox.clear(),
      feedBox.clear(),
      challengeBox.clear(),
      routesBox.clear(),
      notificationsBox.clear(),
      mediaBox.clear(),
    ]);
  }
}

