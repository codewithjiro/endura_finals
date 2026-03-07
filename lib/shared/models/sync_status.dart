 /// Sync statuses for local-first architecture.
enum SyncStatus { pending, synced, failed }

/// Extension for serialization.
extension SyncStatusX on SyncStatus {
  String get value => name;

  static SyncStatus fromString(String? s) {
    switch (s) {
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      default:
        return SyncStatus.pending;
    }
  }
}

