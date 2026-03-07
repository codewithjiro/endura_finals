import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:endura/core/storage/hive_boxes.dart';

/// Global theme mode notifier that persists to Hive.
/// Supports: system, light, dark.
class ThemeNotifier extends ChangeNotifier {
  static const String _key = 'theme_mode';
  static final ThemeNotifier _instance = ThemeNotifier._();

  factory ThemeNotifier() => _instance;
  ThemeNotifier._() {
    _load();
  }

  String _mode = 'system'; // 'system', 'light', 'dark'

  String get mode => _mode;

  Brightness? get brightness {
    switch (_mode) {
      case 'light':
        return Brightness.light;
      case 'dark':
        return Brightness.dark;
      default:
        return null; // system
    }
  }

  void _load() {
    final box = Hive.box(HiveBoxes.database);
    _mode = box.get(_key, defaultValue: 'system') as String;
  }

  Future<void> setMode(String mode) async {
    _mode = mode;
    final box = Hive.box(HiveBoxes.database);
    await box.put(_key, mode);
    notifyListeners();
  }
}

