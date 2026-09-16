import 'community_post.dart';

class CommunityComment {
  CommunityComment({
    required this.id,
    required this.content,
    this.parentId,
    this.user,
    this.replies = const [],
    this.createdAt,
  });

  final int id;
  final String content;
  final int? parentId;
  final PostUser? user;
  final List<CommunityComment> replies;
  final String? createdAt;

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] as int,
      content: json['content'] as String? ?? '',
      parentId: json['parent_id'] as int?,
      user: json['user'] is Map
          ? PostUser.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
      replies: json['replies'] is List
          ? (json['replies'] as List)
              .whereType<Map>()
              .map((e) =>
                  CommunityComment.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      createdAt: json['created_at'] as String?,
    );
  }
}
