import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';
import 'models/offer.dart';
import 'models/candidature.dart';

class JobsRemoteDataSource {
  JobsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<Offer>> getOffers() async {
    try {
      final res = await _dio.get('/offres');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Offer.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Offer> getOffer(int id) async {
    try {
      final res = await _dio.get('/offres/$id');
      return Offer.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Scores de matching candidat -> { offre_id: score(0-100) }. Optionnel.
  Future<Map<int, double>> getMatchingScores(int userId) async {
    try {
      final res = await _dio.get('/matching/candidate/$userId');
      final map = <int, double>{};
      for (final e in unwrapList(res.data).whereType<Map>()) {
        final rawId = e['offre_id'] ?? e['id'];
        final oid = rawId is int ? rawId : int.tryParse('$rawId');
        final s = e['score'];
        final sc = s is num ? s.toDouble() : double.tryParse('$s');
        if (oid != null && sc != null) map[oid] = sc;
      }
      return map;
    } on DioException catch (_) {
      return {};
    }
  }

  Future<void> apply({
    required int offreId,
    String? lettreMotivation,
    bool cvGenere = true,
  }) async {
    try {
      final data = <String, dynamic>{'offre_id': offreId, 'cv_genere': cvGenere};
      if (lettreMotivation != null && lettreMotivation.trim().isNotEmpty) {
        data['motivation_text'] = lettreMotivation.trim();
      }
      await _dio.post('/candidatures', data: data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Candidature>> myCandidatures() async {
    try {
      final res = await _dio.get('/candidatures/me');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Candidature.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Candidature> getCandidature(int id) async {
    try {
      final res = await _dio.get('/candidatures/$id');
      return Candidature.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
