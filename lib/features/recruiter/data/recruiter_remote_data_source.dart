import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';
import '../../jobs/data/models/candidature.dart';
import '../../jobs/data/models/offer.dart';

class UploadBytes {
  const UploadBytes(this.bytes, this.name);
  final Uint8List bytes;
  final String name;
}

/// Resultat du matching IA candidat/offre (endpoint matching/job/{id}).
class JobMatch {
  const JobMatch({required this.candidateId, required this.name, required this.score});
  final int candidateId;
  final String name;
  final double score; // 0..100

  factory JobMatch.fromJson(Map<String, dynamic> j) {
    return JobMatch(
      candidateId: j['candidate_id'] is int
          ? j['candidate_id'] as int
          : int.tryParse('${j['candidate_id']}') ?? 0,
      name: (j['name'] ?? '').toString(),
      score: j['score'] is num
          ? (j['score'] as num).toDouble()
          : double.tryParse('${j['score']}') ?? 0,
    );
  }
}

class RecruiterRemoteDataSource {
  RecruiterRemoteDataSource(this._dio);
  final Dio _dio;

  /// Recupere les noms de roles (minuscules) de l'utilisateur via /user/{id}/roles.
  /// Tolerant aux formes : [..], {roles:[..]}, {data:[..]}.
  Future<List<String>> getUserRoles(int userId) async {
    try {
      final res = await _dio.get('/user/$userId/roles');
      final data = res.data;
      List list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['roles'] is List) {
        list = data['roles'] as List;
      } else if (data is Map && data['data'] is List) {
        list = data['data'] as List;
      } else {
        list = const [];
      }
      final out = <String>[];
      for (final r in list) {
        if (r is String) {
          out.add(r.toLowerCase());
        } else if (r is Map && r['name'] != null) {
          out.add(r['name'].toString().toLowerCase());
        }
      }
      return out;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Match STRICT sur les noms de roles. On evite `contains(...)` qui matcherait
  /// par accident un role type "freelancer_pro" ou "professionnalisation".
  /// Un utilisateur "freelancer" ne doit surtout pas passer pour un recruteur.
  static bool isRecruiterRole(Iterable<String> roles) {
    const recruiterNames = <String>{
      'recruteur',
      'recruiter',
      'professionnel',
      'employeur',
      'employer',
      'entreprise',
      'company',
    };
    for (final n in roles) {
      if (recruiterNames.contains(n.trim())) return true;
    }
    return false;
  }

  Future<void> postOffer(Map<String, dynamic> payload) async {
    try {
      await _dio.post('/offres', data: payload);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Recupere les offres du recruteur connecte via /mesoffres.
  Future<List<Offer>> myOffers() async {
    try {
      final res = await _dio.get('/mesoffres');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Offer.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateOffer(int offerId, Map<String, dynamic> payload) async {
    try {
      await _dio.put('/offres/$offerId', data: payload);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteOffer(int offerId) async {
    try {
      await _dio.delete('/offres/$offerId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Toutes les candidatures pour les offres du recruteur (GET /candidatures).
  Future<List<Candidature>> listApplications() async {
    try {
      final res = await _dio.get('/candidatures');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Candidature.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Candidatures d'une offre precise (GET /offres/:id/candidatures).
  Future<List<Candidature>> applicationsByOffer(int offerId) async {
    try {
      final res = await _dio.get('/offres/$offerId/candidatures');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Candidature.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Candidature> getApplication(int candidatureId) async {
    try {
      final res = await _dio.get('/candidatures/$candidatureId');
      return Candidature.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Change le statut d'une candidature. Pour statut='invitation_entretien',
  /// les extras (date, mode, lieu ou lien) doivent etre fournis.
  Future<Candidature> updateApplicationStatus(
    int candidatureId, {
    required String statut,
    String? dateEntretien,
    String? modeEntretien, // 'visio' | 'presentiel'
    String? lieuEntretien,
    String? lienVisio,
  }) async {
    try {
      final res =
          await _dio.put('/candidatures/$candidatureId/status', data: {
        'statut': statut,
        if (dateEntretien != null) 'date_entretien': dateEntretien,
        if (modeEntretien != null) 'mode_entretien': modeEntretien,
        if (lieuEntretien != null) 'lieu_entretien': lieuEntretien,
        if (lienVisio != null) 'lien_visio': lienVisio,
      });
      return Candidature.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Envoie une invitation d'entretien manuelle (POST /candidatures/:id/invite).
  Future<void> sendInvitation(
    int candidatureId, {
    required String dateHeureEntretien,
    required String typeEntretien, // 'visio' | 'presentiel'
    String? lieu,
    String? lienVisio,
  }) async {
    try {
      await _dio.post('/candidatures/$candidatureId/invite', data: {
        'date_heure_entretien': dateHeureEntretien,
        'type_entretien': typeEntretien,
        if (lieu != null) 'lieu': lieu,
        if (lienVisio != null) 'lien_visio': lienVisio,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Apercu du matching IA pour une offre (GET matching/job/{offreId}).
  /// Reponse : liste triee par score decroissant.
  Future<List<JobMatch>> jobMatches(int offreId) async {
    try {
      final res = await _dio.get('/matching/job/$offreId');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((m) => JobMatch.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Inscription recruteur : cree le profil professionnel (POST /profile/professionnel).
  /// Multipart bytes (logo + photo_couverture) -> compatible web.
  Future<void> createProfessionnel({
    required Map<String, dynamic> fields,
    UploadBytes? logo,
    UploadBytes? cover,
  }) async {
    try {
      final fd = FormData.fromMap({...fields});
      if (logo != null) {
        fd.files.add(MapEntry('logo',
            MultipartFile.fromBytes(logo.bytes, filename: logo.name)));
      }
      if (cover != null) {
        fd.files.add(MapEntry('photo_couverture',
            MultipartFile.fromBytes(cover.bytes, filename: cover.name)));
      }
      await _dio.post('/profile/professionnel', data: fd);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
