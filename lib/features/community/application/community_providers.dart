import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../data/community_remote_data_source.dart';
import '../data/models/community_topic.dart';
import '../data/models/community_post.dart';

final communityDataSourceProvider = Provider<CommunityRemoteDataSource>(
    (ref) => CommunityRemoteDataSource(ref.watch(dioProvider)));

final communityTopicsProvider =
    FutureProvider.autoDispose<List<CommunityTopic>>((ref) async {
  return ref.watch(communityDataSourceProvider).topics();
});

final communityFeedProvider =
    FutureProvider.autoDispose.family<List<CommunityPost>, int?>((ref, topicId) async {
  return ref.watch(communityDataSourceProvider).feed(topicId: topicId);
});

final communityPostDetailProvider =
    FutureProvider.autoDispose.family<CommunityPost, int>((ref, id) async {
  return ref.watch(communityDataSourceProvider).show(id);
});
