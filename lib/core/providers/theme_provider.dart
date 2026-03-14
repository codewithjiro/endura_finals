import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:endura/core/storage/hive_boxes.dart';

final themeProvider = NotifierProvider<ThemeController, String>(
  ThemeController.new,
);

class ThemeController extends Notifier<String> {
  static const String storageKey = 'theme_mode';

  @override
  String build() {
    final box = Hive.box(HiveBoxes.database);
    return box.get(storageKey, defaultValue: 'system') as String;
  }

  Brightness? get brightness {
    switch (state) {
      case 'light':
        return Brightness.light;
      case 'dark':
        return Brightness.dark;
      default:
        return null;
    }
  }

  Future<void> setMode(String mode) async {
    if (mode == state) return;
    state = mode;
    final box = Hive.box(HiveBoxes.database);
    await box.put(storageKey, mode);
  }
}

