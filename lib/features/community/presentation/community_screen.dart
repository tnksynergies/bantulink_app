import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../application/community_providers.dart';
import '../data/models/community_post.dart';
import '../data/models/community_topic.dart';
import 'widgets/post_card.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  int? _selectedTopicId;
  List<CommunityPost> _localPosts = [];
  bool _hasLocalPosts = false;

  void _prependPost(CommunityPost post) {
    setState(() {
      _localPosts = [post, ..._localPosts];
      _hasLocalPosts = true;
    });
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreatePostSheet(
        topics: ref.read(communityTopicsProvider).valueOrNull ?? [],
        onCreated: _prependPost,
        dataSource: ref.read(communityDataSourceProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(communityTopicsProvider);
    final feedAsync = ref.watch(communityFeedProvider(_selectedTopicId));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('community.title'),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          topicsAsync.when(
            loading: () => const SizedBox(height: 50),
            error: (_, __) => const SizedBox.shrink(),
            data: (topics) => _TopicChips(
              topics: topics,
              selectedId: _selectedTopicId,
              onSelect: (id) {
                setState(() {
                  _selectedTopicId = id;
                  _localPosts = [];
                  _hasLocalPosts = false;
                });
              },
            ),
          ),
          Expanded(
            child: feedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$e'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref
                          .invalidate(communityFeedProvider(_selectedTopicId)),
                      child: Text(context.tr('common.retry')),
                    ),
                  ],
                ),
              ),
              data: (serverPosts) {
                final allPosts = _hasLocalPosts
                    ? [..._localPosts, ...serverPosts]
                    : serverPosts;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _localPosts = [];
                      _hasLocalPosts = false;
                    });
                    ref.invalidate(communityFeedProvider(_selectedTopicId));
                    ref.invalidate(communityTopicsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 0, bottom: 80),
                    itemCount: allPosts.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _CreatePostPrompt(
                          onTap: _showCreatePostSheet,
                        );
                      }
                      return PostCard(post: allPosts[i - 1]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePostPrompt extends StatelessWidget {
  const _CreatePostPrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        context.tr('community.content_hint'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library,
                            size: 22, color: Colors.green[600]),
                        const SizedBox(width: 6),
                        const Text('Photo',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: Colors.grey[300]),
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_emotions_outlined,
                            size: 22, color: Colors.amber[600]),
                        const SizedBox(width: 6),
                        const Text('Humeur',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicChips extends StatelessWidget {
  const _TopicChips({
    required this.topics,
    required this.selectedId,
    required this.onSelect,
  });

  final List<CommunityTopic> topics;
  final int? selectedId;
  final void Function(int?) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(context.tr('community.all')),
                selected: selectedId == null,
                onSelected: (_) => onSelect(null),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selectedId == null ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: const Color(0xFFF0F2F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none,
                ),
              ),
            ),
            ...topics.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t.nameFr),
                    selected: selectedId == t.id,
                    onSelected: (_) =>
                        onSelect(selectedId == t.id ? null : t.id),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color:
                          selectedId == t.id ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: const Color(0xFFF0F2F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({
    required this.topics,
    required this.onCreated,
    required this.dataSource,
  });

  final List<CommunityTopic> topics;
  final void Function(CommunityPost) onCreated;
  final dynamic dataSource;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _contentCtrl = TextEditingController();
  int? _selectedTopicId;
  XFile? _pickedImage;
  bool _submitting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _pickedImage = picked);
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty || _submitting) return;
    setState(() => _submitting = true);

    try {
      final newPost = await widget.dataSource.store(
        content: content,
        topicId: _selectedTopicId,
        imagePath: _pickedImage?.path,
      );
      widget.onCreated(newPost);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  context.tr('community.new_post'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          context.tr('community.publish'),
                          style: TextStyle(
                            color: _contentCtrl.text.trim().isEmpty
                                ? Colors.grey
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.person,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                if (widget.topics.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _selectedTopicId,
                          isDense: true,
                          isExpanded: true,
                          hint: Text(context.tr('community.no_topic'),
                              style: const TextStyle(fontSize: 13)),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(context.tr('community.no_topic'),
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            ...widget.topics.map((t) => DropdownMenuItem<int?>(
                                  value: t.id,
                                  child: Text(t.nameFr,
                                      style: const TextStyle(fontSize: 13)),
                                )),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedTopicId = v),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _contentCtrl,
              maxLines: 5,
              maxLength: 5000,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: context.tr('community.content_hint'),
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                border: InputBorder.none,
                counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (_pickedImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_pickedImage!.path),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _pickedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                const Text('Ajouter :',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo_library,
                      color: Colors.green[600], size: 26),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.emoji_emotions_outlined,
                      color: Colors.amber[600], size: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
