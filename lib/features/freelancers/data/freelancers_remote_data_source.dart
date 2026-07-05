import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';
import 'models/competence.dart';
import 'models/freelancer.dart';
import 'models/freelancer_note.dart';
import 'models/realisation.dart';
import 'upload_file.dart';

/// Encapsule tous les appels vers /freelancers, /profile/freelancer,
/// /freelancer/wallet, /admin/freelancers, /competences.
class FreelancersRemoteDataSource {
  FreelancersRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<Freelancer>> list() async {
    try {
      final res = await _dio.get('/freelancers');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Freelancer.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Freelancer> get(int id) async {
    try {
      final res = await _dio.get('/freelancers/$id');
      return Freelancer.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Freelancer> myProfile() async {
    try {
      final res = await _dio.get('/freelancers/me/profile');
      return Freelancer.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Retourne le profil du freelancer connecte ou null si le back renvoie 404.
  Future<Freelancer?> myProfileOrNull() async {
    try {
      return await myProfile();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<FreelancerNote>> notesOf(int freelancerId) async {
    try {
      final res = await _dio.get('/freelancers/$freelancerId/notes');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => FreelancerNote.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (_) {
      return const [];
    }
  }

  Future<List<Competence>> competencesOf(int freelancerId) async {
    try {
      final res = await _dio.get('/freelancers/$freelancerId/competences');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Competence.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (_) {
      return const [];
    }
  }

  Future<List<Realisation>> realisationsOf(int freelancerId) async {
    try {
      final res = await _dio.get('/freelancers/$freelancerId/realisations');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Realisation.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (_) {
      return const [];
    }
  }

  Future<List<Realisation>> myRealisations() async {
    try {
      final res = await _dio.get('/freelancers/me/realisations');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Realisation.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Cree ou met a jour le profil freelancer. Champs `String?` sur nomComplet
  /// pour rester tolerant, mais le back exige nom_complet + titre_pro + email_pro.
  Future<Freelancer> storeOrUpdateProfile({
    required String nomComplet,
    required String titrePro,
    required String emailPro,
    String? description,
    String? telephone,
    String? adresse,
    String? ville,
    String? pays,
    num? montantMinimum,
    List<String>? competences,
    UploadFile? photoProfil,
    UploadFile? photoCouverture,
  }) async {
    try {
      final form = FormData();
      form.fields.addAll([
        MapEntry('nom_complet', nomComplet),
        MapEntry('titre_pro', titrePro),
        MapEntry('email_pro', emailPro),
      ]);
      if (description != null) form.fields.add(MapEntry('description', description));
      if (telephone != null) form.fields.add(MapEntry('telephone', telephone));
      if (adresse != null) form.fields.add(MapEntry('adresse', adresse));
      if (ville != null) form.fields.add(MapEntry('ville', ville));
      if (pays != null) form.fields.add(MapEntry('pays', pays));
      if (montantMinimum != null) {
        form.fields.add(MapEntry('montant_minimum', montantMinimum.toString()));
      }
      if (competences != null) {
        for (final c in competences) {
          form.fields.add(MapEntry('competences[]', c));
        }
      }
      if (photoProfil != null) {
        form.files.add(MapEntry('photo_profil', photoProfil.toMultipart()));
      }
      if (photoCouverture != null) {
        form.files.add(MapEntry('photo_couverture', photoCouverture.toMultipart()));
      }

      final res = await _dio.post('/profile/freelancer', data: form);
      return Freelancer.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Attribue le role Freelancer (id=11) a un utilisateur.
  Future<void> assignFreelancerRole(int userId) async {
    try {
      await _dio.post('/user/$userId/role',
          data: {'id': Freelancer.freelancerRoleId, 'user_id': userId});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Verifie si l'utilisateur possede deja le role freelancer.
  Future<bool> hasFreelancerRole(int userId) async {
    try {
      final res = await _dio.get('/user/$userId/roles');
      final raw = res.data;
      final list = raw is List
          ? raw
          : (raw is Map ? (raw['roles'] ?? raw['data'] ?? const []) : const []);
      if (list is! List) return false;
      return list.any((r) {
        if (r is String) {
          final n = r.toLowerCase();
          return n == 'freelancer' || n == 'prestataire' || n == 'provider';
        }
        if (r is Map) {
          final id = r['id'];
          final name = (r['name'] ?? '').toString().toLowerCase();
          return id == Freelancer.freelancerRoleId ||
              name == 'freelancer' ||
              name == 'prestataire' ||
              name == 'provider';
        }
        return false;
      });
    } on DioException catch (_) {
      return false;
    }
  }

  /// Compétences globales du freelancer connecté.
  Future<List<Competence>> myCompetences() async {
    try {
      final res = await _dio.get('/freelancers/competences');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Competence.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Synchronise (remplace) la liste des competences du freelancer.
  Future<void> setMyCompetences(List<String> noms) async {
    try {
      await _dio.post('/freelancers/competences', data: {
        'competences': noms,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> removeMyCompetence(int competenceId) async {
    try {
      await _dio.delete('/freelancers/competences/$competenceId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Cree une realisation avec upload multi-fichiers.
  Future<Realisation> createRealisation({
    required String titre,
    required String description,
    required String dateRealisation,
    String? localisation,
    String? lien,
    List<UploadFile> images = const [],
    List<UploadFile> documents = const [],
    List<UploadFile> videos = const [],
  }) async {
    try {
      final form = FormData();
      form.fields.addAll([
        MapEntry('titre', titre),
        MapEntry('description', description),
        MapEntry('date_realisation', dateRealisation),
      ]);
      if (localisation != null) form.fields.add(MapEntry('localisation', localisation));
      if (lien != null) form.fields.add(MapEntry('lien', lien));
      for (final f in images) {
        form.files.add(MapEntry('images[]', f.toMultipart()));
      }
      for (final f in documents) {
        form.files.add(MapEntry('documents[]', f.toMultipart()));
      }
      for (final f in videos) {
        form.files.add(MapEntry('videos[]', f.toMultipart()));
      }

      final res = await _dio.post('/freelancers/realisations', data: form);
      return Realisation.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteRealisation(int realisationId) async {
    try {
      await _dio.delete('/freelancers/realisations/$realisationId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Soumet la demande de certification KYC (niu + document identite + selfie).
  Future<Freelancer> submitCertification({
    required UploadFile niu,
    required UploadFile documentIdentite,
    required UploadFile photoSelfie,
  }) async {
    try {
      final form = FormData();
      form.files.addAll([
        MapEntry('niu', niu.toMultipart()),
        MapEntry('document_identite', documentIdentite.toMultipart()),
        MapEntry('photo_selfie', photoSelfie.toMultipart()),
      ]);
      final res = await _dio.post('/freelancers/me/certification', data: form);
      return Freelancer.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Solde du wallet freelancer + transactions.
  Future<WalletData> getWallet() async {
    try {
      final res = await _dio.get('/freelancer/wallet');
      final data = unwrapMap(res.data);
      final txs = <WalletTransaction>[];
      final rawTxs = data['transactions'];
      if (rawTxs is List) {
        for (final t in rawTxs) {
          if (t is Map) txs.add(WalletTransaction.fromJson(Map<String, dynamic>.from(t)));
        }
      }
      return WalletData(
        balance: _num(data['solde'] ?? data['balance'] ?? data['wallet_balance']) ?? 0,
        transactions: txs,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> withdraw({
    required num amount,
    required String phone,
    required String method,
  }) async {
    try {
      await _dio.post('/wallet/withdraw', data: {
        'amount': amount,
        'phone': phone,
        'method': method,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

num? _num(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

class WalletData {
  const WalletData({required this.balance, required this.transactions});
  final num balance;
  final List<WalletTransaction> transactions;
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    this.type,
    this.amount,
    this.status,
    this.description,
    this.method,
    this.reference,
    this.createdAt,
  });

  final int id;
  final String? type; // 'withdrawal' | 'mission_payment' | ...
  final num? amount;
  final String? status;
  final String? description;
  final String? method;
  final String? reference;
  final String? createdAt;

  bool get isWithdrawal => type == 'withdrawal';

  factory WalletTransaction.fromJson(Map<String, dynamic> j) {
    return WalletTransaction(
      id: (j['id'] is int) ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
      type: j['type']?.toString(),
      amount: _num(j['amount']),
      status: j['status']?.toString(),
      description: j['description']?.toString(),
      method: j['method']?.toString(),
      reference: j['reference']?.toString(),
      createdAt: j['created_at']?.toString(),
    );
  }
}
