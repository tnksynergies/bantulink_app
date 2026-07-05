import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../auth/application/auth_controller.dart';
import '../application/messaging_providers.dart';
import '../data/models/conversation.dart';

/// Liste des conversations (onglet Messages). Conserve le nom MessagesScreen.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(authControllerProvider).valueOrNull?.id ?? -1;
    final async = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('messages.title')), centerTitle: false),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Error(
          message: e.toString(),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(conversationsProvider);
                await ref.read(conversationsProvider.future);
              },
              child: ListView(
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.forum_outlined, size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Center(
                      child: Text(context.tr('messages.empty'),
                          style: const TextStyle(color: AppColors.textMuted))),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(context.tr('messages.start_hint'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(conversationsProvider);
              await ref.read(conversationsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
              itemBuilder: (_, i) => _ConvTile(conv: list[i], myId: myId),
            ),
          );
        },
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  const _ConvTile({required this.conv, required this.myId});
  final Conversation conv;
  final int myId;

  @override
  Widget build(BuildContext context) {
    final other = conv.other(myId);
    final name = other?.name ?? 'Utilisateur';
    final last = conv.lastMessage?.content ?? context.tr('messages.no_messages');
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';
    return ListTile(
      onTap: () => context.push('/conversation/${conv.id}', extra: name),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(initials,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          if (other?.isActive == true)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: conv.unreadCount > 0
          ? CircleAvatar(
              radius: 11,
              backgroundColor: AppColors.brandRed,
              child: Text('${conv.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            )
          : null,
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(context.tr('common.retry'))),
          ],
        ),
      ),
    );
  }
}
