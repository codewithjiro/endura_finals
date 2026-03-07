import 'dart:io';

/// Helpers for media file operations.
class MediaFileHelper {
  MediaFileHelper._();

  /// Check if a local file exists.
  static Future<bool> exists(String? path) async {
    if (path == null || path.isEmpty) return false;
    return File(path).exists();
  }

  /// Get file size in bytes.
  static Future<int> fileSize(String path) async {
    final file = File(path);
    if (await file.exists()) return file.length();
    return 0;
  }

  /// Validate that a path points to a supported image.
  static bool isImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext);
  }
}

