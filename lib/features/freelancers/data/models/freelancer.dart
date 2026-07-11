import '../../../../core/utils/media_url.dart';
import 'competence.dart';
import 'freelancer_note.dart';
import 'realisation.dart';

class Freelancer {
  const Freelancer({
    required this.id,
    this.userId,
    this.nomComplet,
    this.titrePro,
    this.description,
    this.emailPro,
    this.telephone,
    this.adresse,
    this.ville,
    this.pays,
    this.photoProfil,
    this.photoCouverture,
    this.montantMinimum,
    this.averageScore,
    this.missionsCount,
    this.isVerified = false,
    this.certificationStatus,
    this.profileViews = 0,
    this.acceptPlatformPayment = true,
    this.walletBalance,
    this.createdAt,
    this.competences = const [],
    this.realisations = const [],
    this.notes = const [],
    this.raw = const {},
  });

  final int id;
  final int? userId;
  final String? nomComplet;
  final String? titrePro;
  final String? description;
  final String? emailPro;
  final String? telephone;
  final String? adresse;
  final String? ville;
  final String? pays;
  final String? photoProfil;
  final String? photoCouverture;
  final num? montantMinimum;
  final double? averageScore;
  final int? missionsCount;
  final bool isVerified;
  final String? certificationStatus; // pending | approved | rejected
  final int profileViews;
  final bool acceptPlatformPayment;
  final num? walletBalance;
  final String? createdAt;
  final List<Competence> competences;
  final List<Realisation> realisations;
  final List<FreelancerNote> notes;
  final Map<String, dynamic> raw;

  String get nomSafe => nomComplet ?? 'Prestataire #$id';

  String get localisation {
    final parts = <String>[];
    if (ville != null && ville!.isNotEmpty) parts.add(ville!);
    if (pays != null && pays!.isNotEmpty) parts.add(pays!);
    return parts.join(', ');
  }

  int get memberSinceYear {
    if (createdAt == null || createdAt!.length < 4) return DateTime.now().year;
    return int.tryParse(createdAt!.substring(0, 4)) ?? DateTime.now().year;
  }

  double get computedRating {
    if (averageScore != null) return averageScore!;
    if (notes.isEmpty) return 0.0;
    final sum = notes.fold<int>(0, (acc, n) => acc + n.score);
    return sum / notes.length;
  }

  int get reviewCount => notes.length;

  static const int freelancerRoleId = 11;

  factory Freelancer.fromJson(Map<String, dynamic> j) {
    final competences = <Competence>[];
    final rawCompetences = j['competences'] ?? j['skills'];
    if (rawCompetences is List) {
      for (final c in rawCompetences) {
        if (c is Map) {
          competences.add(Competence.fromJson(Map<String, dynamic>.from(c)));
        } else if (c is String) {
          competences.add(Competence(id: 0, nom: c));
        }
      }
    }

    final realisations = <Realisation>[];
    final rawReals = j['realisations'];
    if (rawReals is List) {
      for (final r in rawReals) {
        if (r is Map) {
          realisations.add(Realisation.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    }

    final notes = <FreelancerNote>[];
    final rawNotes = j['notes'] ?? j['reviews'];
    if (rawNotes is List) {
      for (final n in rawNotes) {
        if (n is Map) {
          notes.add(FreelancerNote.fromJson(Map<String, dynamic>.from(n)));
        }
      }
    }

    return Freelancer(
      id: _i(j['id']),
      userId: _iOrNull(j['user_id']) ?? _iOrNull((j['user'] is Map) ? j['user']['id'] : null),
      nomComplet: _s(j['nom_complet']),
      titrePro: _s(j['titre_pro']),
      description: _s(j['description']),
      emailPro: _s(j['email_pro']),
      telephone: _s(j['telephone']),
      adresse: _s(j['adresse']),
      ville: _s(j['ville']),
      pays: _s(j['pays']),
      photoProfil: mediaUrl(_s(j['photo_profil'])),
      photoCouverture: mediaUrl(_s(j['photo_couverture'])),
      montantMinimum: _num(j['montant_minimum']),
      averageScore: _double(j['average_score']),
      missionsCount: _iOrNull(j['missions_count']),
      isVerified: j['is_verified'] == true || j['is_verified'] == 1,
      certificationStatus: _s(j['certification_status']),
      profileViews: _iOrNull(j['profile_views']) ?? 0,
      acceptPlatformPayment: j['accept_platform_payment'] != false,
      walletBalance: _num(j['wallet_balance']) ?? _num(j['solde']) ?? _num(j['balance']),
      createdAt: _s(j['created_at']),
      competences: competences,
      realisations: realisations,
      notes: notes,
      raw: j,
    );
  }
}

int _i(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

int? _iOrNull(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}

double? _double(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

num? _num(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

String? _s(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}
