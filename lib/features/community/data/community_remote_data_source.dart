import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';
import 'models/community_topic.dart';
import 'models/community_post.dart';
import 'models/community_comment.dart';

class CommunityRemoteDataSource {
  CommunityRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<CommunityTopic>> topics() async {
    try {
      final res = await _dio.get('/community/topics');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => CommunityTopic.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<CommunityPost>> feed({int? topicId, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (topicId != null) params['topic_id'] = topicId;
      final res = await _dio.get('/community/feed', queryParameters: params);
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => CommunityPost.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CommunityPost> show(int id) async {
    try {
      final res = await _dio.get('/community/posts/$id');
      return CommunityPost.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CommunityPost> store({
    required String content,
    int? topicId,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'content': content,
        if (topicId != null) 'topic_id': topicId,
        if (imagePath != null)
          'image': await MultipartFile.fromFile(imagePath),
      });
      final res = await _dio.post('/community/posts', data: formData);
      return CommunityPost.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deletePost(int id) async {
    try {
      await _dio.delete('/community/posts/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<int> like(int postId) async {
    try {
      final res = await _dio.post('/community/posts/$postId/like');
      return res.data['likes_count'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<int> unlike(int postId) async {
    try {
      final res = await _dio.delete('/community/posts/$postId/like');
      return res.data['likes_count'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CommunityComment> storeComment({
    required int postId,
    required String content,
    int? parentId,
  }) async {
    try {
      final res = await _dio.post('/community/posts/$postId/comments', data: {
        'content': content,
        if (parentId != null) 'parent_id': parentId,
      });
      return CommunityComment.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _dio.delete('/community/comments/$commentId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> report(int postId, String reason) async {
    try {
      await _dio.post('/community/posts/$postId/report', data: {
        'reason': reason,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
