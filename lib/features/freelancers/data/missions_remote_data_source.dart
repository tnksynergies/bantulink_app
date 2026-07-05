import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';
import 'models/mission.dart';
import 'upload_file.dart';

class MissionsRemoteDataSource {
  MissionsRemoteDataSource(this._dio);
  final Dio _dio;

  /// Cree une mission avec upload multi-fichiers optionnel.
  Future<Mission> create({
    required int freelancerId,
    required String titre,
    required String description,
    required String dateDebut,
    String? dateFin,
    num? cout,
    List<UploadFile> images = const [],
    List<UploadFile> documents = const [],
    List<UploadFile> videos = const [],
  }) async {
    try {
      final form = FormData();
      form.fields.addAll([
        MapEntry('freelancer_id', freelancerId.toString()),
        MapEntry('titre', titre),
        MapEntry('description', description),
        MapEntry('date_debut', dateDebut),
      ]);
      if (dateFin != null && dateFin.isNotEmpty) {
        form.fields.add(MapEntry('date_fin', dateFin));
      }
      if (cout != null) form.fields.add(MapEntry('cout', cout.toString()));

      for (final f in images) {
        form.files.add(MapEntry('images[]', f.toMultipart()));
      }
      for (final f in documents) {
        form.files.add(MapEntry('documents[]', f.toMultipart()));
      }
      for (final f in videos) {
        form.files.add(MapEntry('videos[]', f.toMultipart()));
      }

      final res = await _dio.post('/missions', data: form);
      return Mission.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Mission>> myMissions() async {
    try {
      final res = await _dio.get('/missions/me');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Mission.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Mission>> freelancerMissions() async {
    try {
      final res = await _dio.get('/missions/freelancer');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Mission.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Mission> get(int id) async {
    try {
      final res = await _dio.get('/missions/$id');
      return Mission.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Change le statut de la mission. `paymentMode` = 'cash' pour marquer terminee
  /// hors plateforme.
  Future<Mission> updateStatus(int missionId,
      {required MissionStatus status, String? paymentMode}) async {
    try {
      final res = await _dio.put('/missions/$missionId/statut', data: {
        'statut': status.apiValue,
        if (paymentMode != null) 'payment_mode': paymentMode,
      });
      return Mission.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Initie un paiement mobile money pour la mission. Retourne la reference
  /// utilisable pour polling /paiements/status/:reference.
  Future<String?> initiatePayment(int missionId,
      {required String phone, required String provider}) async {
    try {
      final res = await _dio.post('/missions/$missionId/pay', data: {
        'phone': phone,
        'provider': provider,
      });
      final data = res.data;
      final ref = _extractReference(data);
      return ref;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Poll unique /paiements/status/:ref. Retourne 'success'|'failed'|'pending'|null.
  Future<String?> paymentStatus(String reference) async {
    try {
      final res = await _dio.get('/paiements/status/$reference');
      final data = res.data;
      if (data is Map) {
        final s = (data['status'] ?? data['data']?['status'])?.toString().toLowerCase();
        return s;
      }
    } on DioException catch (_) {
      return null;
    }
    return null;
  }

  Future<void> leaveNote(int missionId, {required int score, required String description}) async {
    try {
      await _dio.post('/missions/$missionId/note', data: {
        'score': score,
        'description': description,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  String? _extractReference(dynamic data) {
    if (data is! Map) return null;
    return (data['data']?['partnerId'] ??
            data['partnerId'] ??
            data['reference'] ??
            data['data']?['reference'])
        ?.toString();
  }
}
