import 'package:local_auth/local_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:endura/core/storage/hive_boxes.dart';

/// Centralized biometric authentication service.
/// Uses fingerprint on Android and Face ID / Touch ID on iOS.
class BiometricService {
  BiometricService._();

  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricKey = 'biometrics_enabled';

  /// Check if the device supports biometrics.
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Check if biometrics are enrolled on the device.
  static Future<bool> canAuthenticate() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, iris).
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate using biometrics.
  /// [reason] is the message shown in the system prompt.
  static Future<bool> authenticate({
    String reason = 'Authenticate to continue',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Check if the user has enabled biometric login in settings.
  static bool isEnabled() {
    final box = Hive.box(HiveBoxes.database);
    return box.get(_biometricKey, defaultValue: false) == true;
  }

  /// Enable or disable biometric login.
  static Future<void> setEnabled(bool enabled) async {
    final box = Hive.box(HiveBoxes.database);
    await box.put(_biometricKey, enabled);
  }
}

