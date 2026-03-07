import 'package:endura/shared/models/sync_status.dart';

/// Challenge type enum.
enum ChallengeType { distance, activityCount, streak, time }

extension ChallengeTypeX on ChallengeType {
  String get label {
    switch (this) {
      case ChallengeType.distance:
        return 'Distance';
      case ChallengeType.activityCount:
        return 'Activity Count';
      case ChallengeType.streak:
        return 'Streak';
      case ChallengeType.time:
        return 'Time';
    }
  }

  static ChallengeType fromString(String? s) {
    switch (s) {
      case 'activityCount':
        return ChallengeType.activityCount;
      case 'streak':
        return ChallengeType.streak;
      case 'time':
        return ChallengeType.time;
      default:
        return ChallengeType.distance;
    }
  }
}

/// Cached challenge model stored in Hive.
class CachedChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final double target;
  final double progress;
  final DateTime startDate;
  final DateTime endDate;
  final bool joined;
  final bool completed;
  final String? badge;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  CachedChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    this.progress = 0,
    required this.startDate,
    required this.endDate,
    this.joined = false,
    this.completed = false,
    this.badge,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.pending,
  }) : updatedAt = updatedAt ?? DateTime.now();

  double get progressPercent =>
      target > 0 ? (progress / target).clamp(0, 1) : 0;

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isExpired => DateTime.now().isAfter(endDate);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'target': target,
        'progress': progress,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'joined': joined,
        'completed': completed,
        'badge': badge,
        'updatedAt': updatedAt.toIso8601String(),
        'syncStatus': syncStatus.value,
      };

  factory CachedChallenge.fromMap(Map<String, dynamic> map) => CachedChallenge(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        type: ChallengeTypeX.fromString(map['type']),
        target: (map['target'] ?? 0).toDouble(),
        progress: (map['progress'] ?? 0).toDouble(),
        startDate:
            DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(map['endDate'] ?? '') ??
            DateTime.now().add(const Duration(days: 30)),
        joined: map['joined'] ?? false,
        completed: map['completed'] ?? false,
        badge: map['badge'],
        updatedAt: DateTime.tryParse(map['updatedAt'] ?? ''),
        syncStatus: SyncStatusX.fromString(map['syncStatus']),
      );

  CachedChallenge copyWith({
    double? progress,
    bool? joined,
    bool? completed,
    SyncStatus? syncStatus,
  }) {
    return CachedChallenge(
      id: id,
      title: title,
      description: description,
      type: type,
      target: target,
      progress: progress ?? this.progress,
      startDate: startDate,
      endDate: endDate,
      joined: joined ?? this.joined,
      completed: completed ?? this.completed,
      badge: badge,
      updatedAt: DateTime.now(),
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}


