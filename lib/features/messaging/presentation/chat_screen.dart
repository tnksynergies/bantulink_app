import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/widgets/linkified_text.dart';
import '../../auth/application/auth_controller.dart';
import '../application/messaging_providers.dart';
import '../data/models/message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId, this.title});
  final int conversationId;
  final String? title;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Message> _messages = [];
  bool _loading = true;
  Timer? _poll;
  int _tempSeq = 0;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _subscribe();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    ref.read(echoServiceProvider).unsubscribeConversation(widget.conversationId);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    try {
      await ref.read(echoServiceProvider).subscribeConversation(
        widget.conversationId,
        (raw) {
          final m = Message.fromJson(raw);
          if (!mounted) return;
          if (_messages.any((e) => e.id == m.id && m.id != 0)) return;
          setState(() => _messages = [..._messages, m]);
          _scrollToBottom();
        },
      );
    } catch (_) {}
  }

  Future<void> _load({bool initial = false}) async {
    try {
      final conv = await ref
          .read(messagesDataSourceProvider)
          .getConversation(widget.conversationId);
      if (!mounted) return;
      // Conserver les messages en cours d'envoi (id negatif) non encore cote serveur
      final pending = _messages.where((m) => m.sending).toList();
      setState(() {
        _messages = [...conv.messages, ...pending];
        _loading = false;
      });
      if (initial) _scrollToBottom();
    } catch (_) {
      if (mounted && initial) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final myId = ref.read(authControllerProvider).valueOrNull?.id;
    final tempId = -(++_tempSeq);
    final temp = Message(
      id: tempId,
      content: text,
      senderId: myId,
      createdAt: DateTime.now().toIso8601String(),
      sending: true,
    );
    setState(() {
      _messages = [..._messages, temp];
      _input.clear();
    });
    _scrollToBottom();
    try {
      final sent = await ref
          .read(messagesDataSourceProvider)
          .sendMessage(widget.conversationId, text);
      if (!mounted) return;
      setState(() {
        _messages = _messages.map((m) => m.id == tempId ? sent : m).toList();
      });
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages = _messages.where((m) => m.id != tempId).toList());
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(authControllerProvider).valueOrNull?.id ?? -1;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? context.tr('messages.title'))),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(context.tr('messages.no_messages'),
                            style: const TextStyle(color: AppColors.textMuted)),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _Bubble(message: _messages[i], mine: _messages[i].senderId == myId),
                      ),
          ),
          _Composer(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        decoration: BoxDecoration(
          color: mine ? AppColors.brandGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selectionnable (copie) + liens cliquables.
            LinkifiedText(
              message.content ?? '',
              style: TextStyle(
                  color: mine ? Colors.white : AppColors.textPrimary),
              linkColor: mine ? Colors.white : AppColors.royalBlue,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.timeShort,
                    style: TextStyle(
                        fontSize: 10,
                        color: mine ? Colors.white70 : AppColors.textMuted)),
                if (message.sending) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.access_time, size: 11, color: mine ? Colors.white70 : AppColors.textMuted),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: context.tr('messages.write'),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSend,
                child: const Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
