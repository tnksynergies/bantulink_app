import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/community_comment.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.onReply,
    this.depth = 0,
  });

  final CommunityComment comment;
  final void Function(CommunityComment)? onReply;
  final int depth;

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'maintenant';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: comment.user?.photo != null
                      ? NetworkImage(comment.user!.photo!)
                      : null,
                  child: comment.user?.photo == null
                      ? Text(comment.user?.name.isNotEmpty == true
                          ? comment.user!.name[0].toUpperCase()
                          : '?',
                          style: const TextStyle(fontSize: 12))
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(comment.user?.name ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(_timeAgo(comment.createdAt),
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(comment.content,
                          style: const TextStyle(fontSize: 13, height: 1.3)),
                      if (onReply != null && depth < 2)
                        GestureDetector(
                          onTap: () => onReply!(comment),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Repondre',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...comment.replies.map((reply) => CommentTile(
                comment: reply,
                onReply: onReply,
                depth: depth + 1,
              )),
        ],
      ),
    );
  }
}
