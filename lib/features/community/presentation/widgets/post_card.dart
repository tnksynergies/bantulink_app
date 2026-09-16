import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../application/community_providers.dart';
import '../../data/models/community_post.dart';
import '../../data/models/community_comment.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({super.key, required this.post});
  final CommunityPost post;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  late bool _liked;
  late int _likesCount;
  bool _loading = false;
  bool _showFullContent = false;
  bool _showComments = false;
  bool _loadingComments = false;
  bool _sendingComment = false;
  List<CommunityComment> _comments = [];
  final _commentCtrl = TextEditingController();
  final _commentFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _liked = !_liked;
      _likesCount += _liked ? 1 : -1;
    });
    try {
      final ds = ref.read(communityDataSourceProvider);
      if (!_liked) {
        final count = await ds.unlike(widget.post.id);
        if (mounted) setState(() => _likesCount = count);
      } else {
        final count = await ds.like(widget.post.id);
        if (mounted) setState(() => _likesCount = count);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = !_liked;
          _likesCount += _liked ? 1 : -1;
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toggleComments() {
    setState(() => _showComments = !_showComments);
    if (_showComments && _comments.isEmpty) {
      _fetchComments();
    }
    if (_showComments) {
      Future.delayed(const Duration(milliseconds: 150), () {
        _commentFocus.requestFocus();
      });
    }
  }

  Future<void> _fetchComments() async {
    setState(() => _loadingComments = true);
    try {
      final ds = ref.read(communityDataSourceProvider);
      final detail = await ds.show(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = detail.comments;
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sendingComment) return;
    setState(() => _sendingComment = true);
    try {
      final ds = ref.read(communityDataSourceProvider);
      final newComment = await ds.storeComment(
        postId: widget.post.id,
        content: text,
      );
      if (mounted) {
        setState(() {
          _comments = [..._comments, newComment];
          _sendingComment = false;
        });
        _commentCtrl.clear();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sendingComment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi')),
        );
      }
    }
  }

  void _sharePost() {
    final text = widget.post.content.length > 100
        ? '${widget.post.content.substring(0, 100)}...'
        : widget.post.content;
    Share.share('$text\n\nPartagé via BantuLink');
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    if (diff.inDays > 0) return 'il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes} min';
    return context.tr('community.just_now');
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isLong = post.content.length > 300;
    final displayContent = isLong && !_showFullContent
        ? '${post.content.substring(0, 300)}...'
        : post.content;

    final commentsCount =
        _comments.isNotEmpty ? _comments.length : post.commentsCount;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.user?.photo != null
                      ? NetworkImage(post.user!.photo!)
                      : null,
                  backgroundColor: AppColors.primary,
                  child: post.user?.photo == null
                      ? Text(
                          post.user?.name.isNotEmpty == true
                              ? post.user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.user?.name ?? 'Utilisateur',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _timeAgo(post.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          Text(' · ',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12)),
                          Icon(Icons.public, size: 12, color: Colors.grey[500]),
                          if (post.topic != null) ...[
                            Text(' · ',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12)),
                            Text(
                              post.topic!.nameFr,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayContent,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                if (isLong && !_showFullContent)
                  GestureDetector(
                    onTap: () => setState(() => _showFullContent = true),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Voir plus',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Image
          if (post.image != null) ...[
            const SizedBox(height: 10),
            Image.network(
              post.image!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ],

          // Like & comment counts
          if (_likesCount > 0 || commentsCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_likesCount > 0)
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1877F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.thumb_up,
                              size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_likesCount',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    )
                  else
                    const SizedBox.shrink(),
                  if (commentsCount > 0)
                    GestureDetector(
                      onTap: _toggleComments,
                      child: Text(
                        '$commentsCount commentaire${commentsCount > 1 ? 's' : ''}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.grey[200], height: 20),
          ),

          // Action Bar — 3 buttons (no Envoyer)
          Row(
            children: [
              _ActionButton(
                icon: Icons.thumb_up_outlined,
                activeIcon: Icons.thumb_up,
                label: "J'aime",
                isActive: _liked,
                activeColor: const Color(0xFF1877F2),
                onTap: _toggleLike,
              ),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Commenter',
                onTap: _toggleComments,
              ),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Partager',
                onTap: _sharePost,
              ),
            ],
          ),

          // Inline comments section
          if (_showComments) ...[
            Container(
              color: const Color(0xFFF7F8FA),
              child: Column(
                children: [
                  if (_loadingComments)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_comments.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        itemCount: _comments.length,
                        itemBuilder: (_, i) => _CommentTile(
                            comment: _comments[i], timeAgo: _timeAgo),
                      ),
                    ),
                  // Comment input
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentCtrl,
                                    focusNode: _commentFocus,
                                    decoration: const InputDecoration(
                                      hintText: 'Écrire un commentaire...',
                                      hintStyle: TextStyle(fontSize: 13),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      isDense: true,
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    onSubmitted: (_) => _submitComment(),
                                  ),
                                ),
                                _sendingComment
                                    ? const Padding(
                                        padding: EdgeInsets.only(right: 10),
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      )
                                    : IconButton(
                                        icon: Icon(Icons.send_rounded,
                                            color: AppColors.primary, size: 20),
                                        onPressed: _submitComment,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 36, minHeight: 36),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.timeAgo});
  final CommunityComment comment;
  final String Function(String?) timeAgo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.user?.photo != null
                ? NetworkImage(comment.user!.photo!)
                : null,
            backgroundColor: const Color(0xFFDDE5F4),
            child: comment.user?.photo == null
                ? Text(
                    comment.user?.name.isNotEmpty == true
                        ? comment.user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF3366CC),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.user?.name ?? 'Utilisateur',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comment.content,
                        style: const TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text(
                    timeAgo(comment.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.activeIcon,
    this.isActive = false,
    this.activeColor,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? (activeColor ?? AppColors.primary) : Colors.grey[600];

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? (activeIcon ?? icon) : icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
