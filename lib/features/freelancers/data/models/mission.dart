import '../../../../core/utils/media_url.dart';
import 'mission_media.dart';

/// Statuts canoniques Bantulink (voir MissionController::updateStatus).
enum MissionStatus {
  enAttente('En Attente'),
  acceptee('Acceptée'),
  enCours('En Cours'),
  enPause('En Pause'),
  terminee('Terminée'),
  annulee('Annulée'),
  inconnu('');

  const MissionStatus(this.apiValue);
  final String apiValue;

  static MissionStatus fromApi(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    if (s.isEmpty) return MissionStatus.inconnu;
    if (s.contains('attente') || s == 'pending') return MissionStatus.enAttente;
    if (s.contains('accept')) return MissionStatus.acceptee;
    if (s.contains('pause')) return MissionStatus.enPause;
    if (s.contains('cours') || s.contains('progress')) return MissionStatus.enCours;
    if (s.contains('termin') || s == 'completed' || s == 'done') return MissionStatus.terminee;
    if (s.contains('annul') || s == 'cancelled' || s == 'canceled') return MissionStatus.annulee;
    return MissionStatus.inconnu;
  }
}

class MissionClient {
  const MissionClient({required this.id, this.nomComplet, this.photoProfil});
  final int id;
  final String? nomComplet;
  final String? photoProfil;

  factory MissionClient.fromJson(Map<String, dynamic> j) {
    final prenom = j['prenom']?.toString().trim() ?? '';
    final nom = j['nom']?.toString().trim() ?? '';
    final full = j['nom_complet']?.toString() ??
        (prenom.isNotEmpty || nom.isNotEmpty ? '$prenom $nom'.trim() : null);
    return MissionClient(
      id: _i(j['id']),
      nomComplet: full,
      photoProfil: mediaUrl(j['photo_profil']?.toString()),
    );
  }
}

class MissionFreelancerSummary {
  const MissionFreelancerSummary({
    required this.id,
    this.nomComplet,
    this.photoProfil,
    this.titrePro,
    this.acceptPlatformPayment = true,
  });

  final int id;
  final String? nomComplet;
  final String? photoProfil;
  final String? titrePro;
  final bool acceptPlatformPayment;

  factory MissionFreelancerSummary.fromJson(Map<String, dynamic> j) {
    return MissionFreelancerSummary(
      id: _i(j['id']),
      nomComplet: j['nom_complet']?.toString(),
      photoProfil: mediaUrl(j['photo_profil']?.toString()),
      titrePro: j['titre_pro']?.toString(),
      acceptPlatformPayment: j['accept_platform_payment'] != false,
    );
  }
}

class Mission {
  const Mission({
    required this.id,
    this.titre,
    this.description,
    this.statutRaw,
    this.dateDebut,
    this.dateFin,
    this.cout,
    this.paymentStatus,
    this.freelancerId,
    this.freelancer,
    this.client,
    this.medias = const [],
    this.createdAt,
    this.updatedAt,
    this.raw = const {},
  });

  final int id;
  final String? titre;
  final String? description;
  final String? statutRaw;
  final String? dateDebut;
  final String? dateFin;
  final num? cout;
  final String? paymentStatus; // 'cash' | 'paid' | null
  final int? freelancerId;
  final MissionFreelancerSummary? freelancer;
  final MissionClient? client;
  final List<MissionMedia> medias;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic> raw;

  MissionStatus get status => MissionStatus.fromApi(statutRaw);

  String get titreSafe => titre ?? 'Mission #$id';

  String get dateDebutCourt =>
      (dateDebut != null && dateDebut!.length >= 10) ? dateDebut!.substring(0, 10) : (dateDebut ?? '');
  String get dateFinCourt =>
      (dateFin != null && dateFin!.length >= 10) ? dateFin!.substring(0, 10) : (dateFin ?? '');
  String get dateCreationCourt =>
      (createdAt != null && createdAt!.length >= 10) ? createdAt!.substring(0, 10) : (createdAt ?? '');

  List<MissionMedia> get images => medias.where((m) => m.isImage).toList(growable: false);
  List<MissionMedia> get documents => medias.where((m) => m.isDocument).toList(growable: false);
  List<MissionMedia> get videos => medias.where((m) => m.isVideo).toList(growable: false);

  bool get canReview => status == MissionStatus.terminee;
  bool get canFinish => status == MissionStatus.enCours || status == MissionStatus.enPause;
  bool get canCancelClient =>
      status == MissionStatus.enAttente ||
      status == MissionStatus.acceptee ||
      status == MissionStatus.enCours ||
      status == MissionStatus.enPause;
  bool get canAcceptFreelancer => status == MissionStatus.enAttente;
  bool get canStartFreelancer => status == MissionStatus.acceptee;
  bool get canFinishFreelancer =>
      status == MissionStatus.enCours || status == MissionStatus.enPause;

  factory Mission.fromJson(Map<String, dynamic> j) {
    final medias = <MissionMedia>[];
    final rawMedias = j['medias'];
    if (rawMedias is List) {
      for (final m in rawMedias) {
        if (m is Map) medias.add(MissionMedia.fromJson(Map<String, dynamic>.from(m)));
      }
    } else if (rawMedias is Map) {
      for (final key in const ['images', 'documents', 'videos']) {
        final v = rawMedias[key];
        if (v is List) {
          for (final m in v) {
            if (m is Map) {
              final map = Map<String, dynamic>.from(m);
              map['media_type'] ??= key.substring(0, key.length - 1);
              medias.add(MissionMedia.fromJson(map));
            }
          }
        }
      }
    }

    MissionFreelancerSummary? fs;
    final rawFl = j['freelancer'];
    if (rawFl is Map) fs = MissionFreelancerSummary.fromJson(Map<String, dynamic>.from(rawFl));

    MissionClient? cl;
    final rawCl = j['client'];
    if (rawCl is Map) cl = MissionClient.fromJson(Map<String, dynamic>.from(rawCl));

    return Mission(
      id: _i(j['id']),
      titre: _s(j['titre']),
      description: _s(j['description']),
      statutRaw: _s(j['statut']) ?? _s(j['status']),
      dateDebut: _s(j['date_debut']),
      dateFin: _s(j['date_fin']),
      cout: _num(j['cout']) ?? _num(j['budget']),
      paymentStatus: _s(j['payment_status']),
      freelancerId: _iOrNull(j['freelancer_id']) ?? (fs?.id),
      freelancer: fs,
      client: cl,
      medias: medias,
      createdAt: _s(j['created_at']),
      updatedAt: _s(j['updated_at']),
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
