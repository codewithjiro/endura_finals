import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endura/features/feed/data/feed_repository.dart';
import 'package:endura/shared/models/cached_feed_item.dart';

final feedRepositoryListenableProvider = Provider<ValueListenable<Object?>>((ref) {
  final listenable = FeedRepository.listenable;
  void listener() => ref.invalidateSelf();
  listenable.addListener(listener);
  ref.onDispose(() => listenable.removeListener(listener));
  return listenable;
});

final feedItemsProvider = Provider<List<CachedFeedItem>>((ref) {
  ref.watch(feedRepositoryListenableProvider);
  return FeedRepository.getAll();
});
