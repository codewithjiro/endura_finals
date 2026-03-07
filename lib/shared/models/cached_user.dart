import 'package:endura/shared/models/sync_status.dart';

/// Cached user profile model stored in Hive.
class CachedUser {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? avatarLocalPath;
  final String bio;
  final String location;
  final String preferredSport;
  final String goals;
  final String profileVisibility;
  final String measurementUnit; // 'metric' or 'imperial'
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String? remoteId;

  CachedUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.avatarLocalPath,
    this.bio = '',
    this.location = '',
    this.preferredSport = 'running',
    this.goals = '',
    this.profileVisibility = 'public',
    this.measurementUnit = 'metric',
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.pending,
    this.remoteId,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'avatarLocalPath': avatarLocalPath,
        'bio': bio,
        'location': location,
        'preferredSport': preferredSport,
        'goals': goals,
        'profileVisibility': profileVisibility,
        'measurementUnit': measurementUnit,
        'updatedAt': updatedAt.toIso8601String(),
        'syncStatus': syncStatus.value,
        'remoteId': remoteId,
      };

  factory CachedUser.fromMap(Map<String, dynamic> map) => CachedUser(
        id: map['id'] ?? '',
        displayName: map['displayName'] ?? '',
        avatarUrl: map['avatarUrl'],
        avatarLocalPath: map['avatarLocalPath'],
        bio: map['bio'] ?? '',
        location: map['location'] ?? '',
        preferredSport: map['preferredSport'] ?? 'running',
        goals: map['goals'] ?? '',
        profileVisibility: map['profileVisibility'] ?? 'public',
        measurementUnit: map['measurementUnit'] ?? 'metric',
        updatedAt: DateTime.tryParse(map['updatedAt'] ?? ''),
        syncStatus: SyncStatusX.fromString(map['syncStatus']),
        remoteId: map['remoteId'],
      );

  CachedUser copyWith({
    String? displayName,
    String? avatarUrl,
    String? avatarLocalPath,
    String? bio,
    String? location,
    String? preferredSport,
    String? goals,
    String? profileVisibility,
    String? measurementUnit,
    SyncStatus? syncStatus,
  }) {
    return CachedUser(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      preferredSport: preferredSport ?? this.preferredSport,
      goals: goals ?? this.goals,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      updatedAt: DateTime.now(),
      syncStatus: syncStatus ?? SyncStatus.pending,
      remoteId: remoteId,
    );
  }
}


