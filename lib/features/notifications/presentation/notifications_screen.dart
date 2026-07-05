import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/notifications_providers.dart';
import '../data/models/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notif.title')),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref.read(markAllReadControllerProvider.notifier).run();
                messenger.showSnackBar(
                  SnackBar(
                      content: Text(context.mounted
                          ? context.tr('notif.all_read_toast')
                          : '')),
                );
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(
                context.tr('notif.mark_all_read'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (list) {
          if (list.isEmpty) return _EmptyView(ref: ref);
          final groups = _groupByDay(list);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              await ref.read(notificationsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: groups.length,
              itemBuilder: (_, i) => _DayGroup(group: groups[i]),
            ),
          );
        },
      ),
    );
  }

  /// Regroupe les notifications par bucket "Aujourd'hui / Hier / Plus ancien".
  List<_Group> _groupByDay(List<AppNotification> list) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final buckets = <String, List<AppNotification>>{
      'notif.today': [],
      'notif.yesterday': [],
      'notif.earlier': [],
    };

    // On trie plus recent d'abord.
    final sorted = [...list]
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    for (final n in sorted) {
      final dt = DateTime.tryParse(n.createdAt ?? '');
      if (dt == null) {
        buckets['notif.earlier']!.add(n);
      } else if (sameDay(dt, today)) {
        buckets['notif.today']!.add(n);
      } else if (sameDay(dt, yesterday)) {
        buckets['notif.yesterday']!.add(n);
      } else {
        buckets['notif.earlier']!.add(n);
      }
    }

    return buckets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => _Group(labelKey: e.key, items: e.value))
        .toList(growable: false);
  }
}

class _Group {
  const _Group({required this.labelKey, required this.items});
  final String labelKey;
  final List<AppNotification> items;
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.group});
  final _Group group;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            context.tr(group.labelKey),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1.2),
          ),
        ),
        for (final n in group.items) _NotificationTile(notification: n),
      ],
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final AppNotification notification;

  ({Color bg, Color fg, IconData icon}) _style() {
    switch (notification.kind) {
      case NotificationKind.newMessage:
        return (
          bg: const Color(0xFFDBEAFE),
          fg: const Color(0xFF1E40AF),
          icon: Icons.forum_outlined
        );
      case NotificationKind.newOffer:
        return (
          bg: const Color(0xFFE0F2FE),
          fg: const Color(0xFF0369A1),
          icon: Icons.work_outline
        );
      case NotificationKind.newApplication:
        return (
          bg: const Color(0xFFEDE9FE),
          fg: const Color(0xFF6D28D9),
          icon: Icons.description_outlined
        );
      case NotificationKind.newMissionRequest:
        return (
          bg: const Color(0xFFFFEDD5),
          fg: const Color(0xFFC2410C),
          icon: Icons.assignment_outlined
        );
      case NotificationKind.missionStatusChanged:
        return (
          bg: const Color(0xFFDCFCE7),
          fg: const Color(0xFF15803D),
          icon: Icons.change_history
        );
      case NotificationKind.applicationStatusChanged:
        return (
          bg: const Color(0xFFF3E8FF),
          fg: const Color(0xFF7C3AED),
          icon: Icons.rule
        );
      case NotificationKind.interviewInvitation:
        return (
          bg: const Color(0xFFEDE9FE),
          fg: const Color(0xFF6D28D9),
          icon: Icons.event_available_outlined
        );
      case NotificationKind.paymentReceived:
        return (
          bg: const Color(0xFFDCFCE7),
          fg: const Color(0xFF15803D),
          icon: Icons.payments_outlined
        );
      case NotificationKind.paymentCompleted:
        return (
          bg: const Color(0xFFDCFCE7),
          fg: const Color(0xFF15803D),
          icon: Icons.check_circle_outline
        );
      case NotificationKind.reviewReceived:
        return (
          bg: const Color(0xFFFEF3C7),
          fg: const Color(0xFFB45309),
          icon: Icons.star_outline
        );
      case NotificationKind.system:
      case NotificationKind.other:
        return (
          bg: const Color(0xFFF3F4F6),
          fg: const Color(0xFF4B5563),
          icon: Icons.notifications_outlined
        );
    }
  }

  String _defaultTitle(BuildContext context) =>
      context.tr(notification.kind.i18nTitleKey);

  /// Retourne la route de navigation cible en fonction du type + entite liee.
  /// Null si aucune ressource pertinente n'est associee.
  String? _resolveRoute() {
    switch (notification.kind) {
      case NotificationKind.newMessage:
        if (notification.conversationId != null) {
          return '/conversation/${notification.conversationId}';
        }
        return '/messages';
      case NotificationKind.newOffer:
        if (notification.offerId != null) {
          return '/offre/${notification.offerId}';
        }
        return '/emploi';
      case NotificationKind.newApplication:
      case NotificationKind.applicationStatusChanged:
        if (notification.applicationId != null) {
          return '/recruteur/candidature/${notification.applicationId}';
        }
        return '/recruteur/candidatures';
      case NotificationKind.newMissionRequest:
      case NotificationKind.missionStatusChanged:
        if (notification.missionId != null) {
          return '/mission/${notification.missionId}';
        }
        return '/mes-missions';
      case NotificationKind.interviewInvitation:
        if (notification.applicationId != null) {
          return '/recruteur/candidature/${notification.applicationId}';
        }
        return null;
      case NotificationKind.paymentReceived:
      case NotificationKind.paymentCompleted:
        return '/prestataire/wallet';
      case NotificationKind.reviewReceived:
        if (notification.freelancerId != null) {
          return '/prestataire/${notification.freelancerId}';
        }
        return null;
      case NotificationKind.system:
      case NotificationKind.other:
        return null;
    }
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    // Marque en lu (silencieux si l'endpoint n'existe pas).
    if (notification.isUnread && notification.id.isNotEmpty) {
      ref
          .read(markReadControllerProvider(notification.id).notifier)
          .run();
    }
    final route = _resolveRoute();
    if (route != null) {
      // On utilise push pour laisser la possibilite de revenir.
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = _style();
    final unread = notification.isUnread;
    final title = notification.title?.isNotEmpty == true
        ? notification.title!
        : _defaultTitle(context);
    final body = notification.body;
    final createdAt = notification.createdAt ?? '';
    final short = createdAt.length >= 16
        ? createdAt.substring(0, 16).replaceAll('T', ' ')
        : createdAt;

    return Container(
      color: unread ? style.bg.withOpacity(0.4) : Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.bg,
                ),
                alignment: Alignment.center,
                child: Icon(style.icon, color: style.fg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight:
                            unread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (body != null && body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (short.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(short,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(notificationsProvider);
        await ref.read(notificationsProvider.future);
      },
      child: ListView(
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.notifications_none,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Center(
            child: Text(context.tr('notif.empty'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
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
            const Icon(Icons.cloud_off,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            OutlinedButton(
                onPressed: onRetry,
                child: Text(context.tr('common.retry'))),
          ],
        ),
      ),
    );
  }
}
