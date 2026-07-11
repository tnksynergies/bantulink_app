import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/network/network_providers.dart';
import '../data/models/app_notification.dart';
import '../data/notifications_remote_data_source.dart';
import '../services/local_notifications_service.dart';

final notificationsDataSourceProvider = Provider<NotificationsRemoteDataSource>(
    (ref) => NotificationsRemoteDataSource(ref.watch(dioProvider)));

/// Notifier qui charge la liste des notifications et se rafraichit
/// automatiquement toutes les 30 secondes.
class NotificationsNotifier
    extends AutoDisposeAsyncNotifier<List<AppNotification>> {
  Timer? _timer;

  /// Ids deja annonces dans la barre systeme. Statique : survit a la
  /// re-creation du notifier (autoDispose) pour ne jamais notifier deux fois.
  static final Set<String> _announcedIds = <String>{};
  static bool _bootstrapped = false;

  @override
  Future<List<AppNotification>> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Refresh silencieux : ne pas re-passer par loading pour ne pas
      // faire clignoter l'UI.
      refresh();
    });
    ref.onDispose(() => _timer?.cancel());
    final list = await ref.read(notificationsDataSourceProvider).list();
    _announceNew(list);
    return list;
  }

  /// Recharge la liste sans passer par un etat loading (garde l'ancienne
  /// liste visible pendant le fetch).
  Future<void> refresh() async {
    final list = await ref.read(notificationsDataSourceProvider).list();
    _announceNew(list);
    state = AsyncValue.data(list);
  }

  /// Pousse dans la barre systeme les notifications non lues jamais vues
  /// (point 1 seance de travail). Au premier chargement on marque tout comme
  /// deja vu sans notifier, pour ne pas rejouer l'historique au demarrage.
  void _announceNew(List<AppNotification> list) {
    final unread = list.where((n) => n.isUnread && n.id.isNotEmpty);
    if (!_bootstrapped) {
      _announcedIds.addAll(unread.map((n) => n.id));
      _bootstrapped = true;
      return;
    }
    final lang = ref.read(localeProvider).languageCode;
    String tr(String key) =>
        kStrings[lang]?[key] ?? kStrings['fr']?[key] ?? key;

    var shown = 0;
    for (final n in unread) {
      if (_announcedIds.contains(n.id)) continue;
      _announcedIds.add(n.id);
      if (shown >= 3) continue; // anti-spam : max 3 par cycle de polling
      shown++;
      final title = (n.title != null && n.title!.trim().isNotEmpty)
          ? n.title!
          : tr(n.kind.i18nTitleKey);
      final body = (n.body != null && n.body!.trim().isNotEmpty)
          ? n.body!
          : tr('notif.tap_to_open');
      // Fire-and-forget : l'affichage systeme ne doit pas bloquer le fetch.
      LocalNotificationsService.instance
          .show(serverId: n.id, title: title, body: body);
    }
  }
}

final notificationsProvider = AutoDisposeAsyncNotifierProvider<
    NotificationsNotifier, List<AppNotification>>(NotificationsNotifier.new);

/// Compteur de notifications non lues, utilise pour le badge de la cloche.
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final list = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return list.where((n) => n.isUnread).length;
});

/// Marque une notification comme lue.
class MarkReadController extends AutoDisposeFamilyAsyncNotifier<bool, String> {
  @override
  Future<bool> build(String arg) async => false;

  Future<void> run() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(notificationsDataSourceProvider).markRead(arg);
      // Refresh sans loading visible.
      await ref.read(notificationsProvider.notifier).refresh();
      return true;
    });
  }
}

final markReadControllerProvider =
    AutoDisposeAsyncNotifierProvider.family<MarkReadController, bool, String>(
        MarkReadController.new);

/// Marque toutes les notifications comme lues.
class MarkAllReadController extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> run() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(notificationsDataSourceProvider).markAllRead();
      await ref.read(notificationsProvider.notifier).refresh();
      return true;
    });
  }
}

final markAllReadControllerProvider =
    AutoDisposeAsyncNotifierProvider<MarkAllReadController, bool>(
        MarkAllReadController.new);
