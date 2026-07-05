import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../data/models/app_notification.dart';
import '../data/notifications_remote_data_source.dart';

final notificationsDataSourceProvider = Provider<NotificationsRemoteDataSource>(
    (ref) => NotificationsRemoteDataSource(ref.watch(dioProvider)));

/// Notifier qui charge la liste des notifications et se rafraichit
/// automatiquement toutes les 30 secondes.
class NotificationsNotifier
    extends AutoDisposeAsyncNotifier<List<AppNotification>> {
  Timer? _timer;

  @override
  Future<List<AppNotification>> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Refresh silencieux : ne pas re-passer par loading pour ne pas
      // faire clignoter l'UI.
      refresh();
    });
    ref.onDispose(() => _timer?.cancel());
    return ref.read(notificationsDataSourceProvider).list();
  }

  /// Recharge la liste sans passer par un etat loading (garde l'ancienne
  /// liste visible pendant le fetch).
  Future<void> refresh() async {
    final list = await ref.read(notificationsDataSourceProvider).list();
    state = AsyncValue.data(list);
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
