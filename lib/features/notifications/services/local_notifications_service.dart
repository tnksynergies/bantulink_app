import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notifications systeme (barre du telephone) — point 1 de la seance de
/// travail : les alertes BantuLink (nouveau message, offre d'emploi,
/// candidature, mission, paiement...) remontent dans la barre de
/// notifications Android/iOS meme quand l'app est en arriere-plan.
///
/// Sur le web ce service est neutralise (no-op) : la cloche in-app suffit.
class LocalNotificationsService {
  LocalNotificationsService._();
  static final LocalNotificationsService instance =
      LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Callback optionnel invoque quand l'utilisateur tape la notification
  /// (payload = id de la notification serveur). Branche par le router/app.
  void Function(String payload)? onTap;

  static const _channelId = 'bantulink_alerts';
  static const _channelName = 'Alertes BantuLink';
  static const _channelDescription =
      'Nouveaux messages, offres d\'emploi, candidatures, missions et paiements';

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) onTap?.call(payload);
      },
    );

    // Android 13+ : permission runtime POST_NOTIFICATIONS.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Affiche une notification dans la barre systeme.
  /// [id] doit etre stable par notification serveur pour eviter les doublons
  /// (on hash l'uuid Laravel).
  Future<void> show({
    required String serverId,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      // hashCode d'un uuid : stable pour la meme notification serveur.
      serverId.hashCode & 0x7fffffff,
      title,
      body,
      details,
      payload: serverId,
    );
  }
}
