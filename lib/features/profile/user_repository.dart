import 'package:hive_flutter/hive_flutter.dart';
import 'package:endura/core/storage/hive_service.dart';
import 'package:endura/shared/models/cached_user.dart';

/// Repository for user profile operations on Hive.
class UserRepository {
  static const String _profileKey = 'current_profile';

  static Box<Map> get _box => HiveService.userBox;

  /// Get the current user profile.
  static CachedUser? getProfile() {
    final data = _box.get(_profileKey);
    if (data == null) return null;
    return CachedUser.fromMap(Map<String, dynamic>.from(data));
  }

  /// Save or update the user profile.
  static Future<void> saveProfile(CachedUser user) async {
    await _box.put(_profileKey, user.toMap());
  }

  /// Delete the user profile.
  static Future<void> deleteProfile() async {
    await _box.delete(_profileKey);
  }

  /// Create initial profile from auth data.
  static Future<CachedUser> createFromAuth(String username) async {
    final user = CachedUser(
      id: username,
      displayName: username,
    );
    await saveProfile(user);
    return user;
  }
}


