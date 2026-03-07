import 'package:flutter/cupertino.dart';

/// Endura app theme — Cupertino only.
class AppTheme {
  AppTheme._();

  // ── Brand colors ────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6F2DA8);
  static const Color primaryLight = Color(0xFF8E44AD);
  static const Color primarySurface = Color(0xFFF3E8FF);
  static const Color scaffoldLight = Color(0xFFF5F7FA);
  static const Color scaffoldDark = Color(0xFF1C1C1E);
  static const Color cardLight = CupertinoColors.white;
  static const Color cardDark = Color(0xFF2C2C2E);
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color danger = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);

  // ── Spacing ─────────────────────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double radius = 16;
  static const double radiusSm = 10;
  static const double radiusLg = 24;

  // ── Theme data ──────────────────────────────────────────────────────
  static CupertinoThemeData get lightTheme => const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: primary,
        scaffoldBackgroundColor: scaffoldLight,
        barBackgroundColor: Color(0xF0F5F7FA),
        textTheme: CupertinoTextThemeData(
          primaryColor: primary,
        ),
      );

  static CupertinoThemeData get darkTheme => const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: primary,
        scaffoldBackgroundColor: scaffoldDark,
        barBackgroundColor: Color(0xF01C1C1E),
        textTheme: CupertinoTextThemeData(
          primaryColor: primary,
        ),
      );

  // ── Helpers ─────────────────────────────────────────────────────────
  static Color cardColor(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    return brightness == Brightness.dark ? cardDark : cardLight;
  }

  static Color scaffoldColor(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    return brightness == Brightness.dark ? scaffoldDark : scaffoldLight;
  }

  static Color textColor(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    return brightness == Brightness.dark ? CupertinoColors.white : textPrimary;
  }
}

