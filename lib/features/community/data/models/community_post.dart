import 'community_comment.dart';
import 'community_topic.dart';

class PostUser {
  PostUser({required this.id, required this.name, this.photo});
  final int id;
  final String name;
  final String? photo;

  factory PostUser.fromJson(Map<String, dynamic> json) {
    return PostUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      photo: json['photo'] as String?,
    );
  }
}

class CommunityPost {
  CommunityPost({
    required this.id,
    required this.content,
    this.image,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.user,
    this.topic,
    this.comments = const [],
    this.createdAt,
  });

  final int id;
  final String content;
  final String? image;
  int likesCount;
  final int commentsCount;
  bool isLiked;
  final PostUser? user;
  final CommunityTopic? topic;
  final List<CommunityComment> comments;
  final String? createdAt;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as int,
      content: json['content'] as String? ?? '',
      image: json['image'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      user: json['user'] is Map
          ? PostUser.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
      topic: json['topic'] is Map
          ? CommunityTopic.fromJson(
              Map<String, dynamic>.from(json['topic'] as Map))
          : null,
      comments: json['comments'] is List
          ? (json['comments'] as List)
              .whereType<Map>()
              .map((e) =>
                  CommunityComment.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      createdAt: json['created_at'] as String?,
    );
  }
}
