import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';
import 'models/app_notification.dart';

/// Contrat backend (a implementer / valider cote Laravel) :
///
/// GET  /notifications                    -> List de notifications
/// POST /notifications/{id}/read          -> marque une notification lue
/// POST /notifications/read-all           -> marque toutes les notifications lues
///
/// Chaque notification suit typiquement le schema Laravel natif :
/// {
///   "id": "uuid",
///   "type": "App\\Notifications\\NewMessage",  // ou "new_message"
///   "data": {"title": "...", "message": "...", "mission_id": 12, ...},
///   "read_at": null | "2026-01-01T00:00:00Z",
///   "created_at": "2026-01-01T00:00:00Z"
/// }
///
/// Si les endpoints retournent 404/405 (non implementes), on renvoie une
/// liste vide sans casser l'app.
class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<AppNotification>> list() async {
    try {
      final res = await _dio.get('/notifications');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) return const [];
      throw ApiException.fromDio(e);
    }
  }

  /// Marque une notification comme lue. Silencieux si l'endpoint n'existe
  /// pas encore cote back (404/405).
  Future<void> markRead(String id) async {
    try {
      await _dio.post('/notifications/$id/read');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) return;
      throw ApiException.fromDio(e);
    }
  }

  /// Marque toutes les notifications non lues comme lues.
  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/read-all');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) return;
      throw ApiException.fromDio(e);
    }
  }
}
