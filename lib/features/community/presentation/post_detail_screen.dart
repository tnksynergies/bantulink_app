import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../application/community_providers.dart';
import '../data/models/community_comment.dart';
import 'widgets/post_card.dart';
import 'widgets/comment_tile.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});
  final int postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  int? _replyToId;
  String? _replyToName;
  bool _sending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(communityDataSourceProvider).storeComment(
            postId: widget.postId,
            content: text,
            parentId: _replyToId,
          );
      _commentCtrl.clear();
      setState(() { _replyToId = null; _replyToName = null; });
      ref.invalidate(communityPostDetailProvider(widget.postId));
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(communityPostDetailProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('community.post'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (post) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref
                    .invalidate(communityPostDetailProvider(widget.postId)),
                child: ListView(
                  children: [
                    PostCard(post: post),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(context.tr('community.comments'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                    if (post.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(context.tr('community.no_comments'),
                            style: TextStyle(color: AppColors.textMuted)),
                      )
                    else
                      ...post.comments.map((c) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: CommentTile(
                              comment: c,
                              onReply: (reply) {
                                setState(() {
                                  _replyToId = reply.id;
                                  _replyToName = reply.user?.name;
                                });
                                FocusScope.of(context).requestFocus(FocusNode());
                              },
                            ),
                          )),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_replyToName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text('Reponse a $_replyToName',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.primary)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() {
                                _replyToId = null;
                                _replyToName = null;
                              }),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentCtrl,
                            decoration: InputDecoration(
                              hintText: context.tr('community.write_comment'),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendComment(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: _sending ? null : _sendComment,
                          icon: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : Icon(Icons.send, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
