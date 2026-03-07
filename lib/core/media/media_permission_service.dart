import 'package:permission_handler/permission_handler.dart';

/// Centralized permission handling for media features.
class MediaPermissionService {
  MediaPermissionService._();

  /// Request camera permission. Returns true if granted.
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request photo library permission.
  static Future<bool> requestPhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  /// Check if camera is available.
  static Future<bool> isCameraGranted() => Permission.camera.isGranted;

  /// Check if photos access is available.
  static Future<bool> isPhotosGranted() => Permission.photos.isGranted;
}

