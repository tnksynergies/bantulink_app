import '../../../../core/utils/media_url.dart';
import 'offer.dart';

/// Statut canonique cote back : envoyee | recue | preselectionne | rejete
/// | invitation_entretien | embauche.
enum CandidatureStatus {
  envoyee('envoyee'),
  recue('recue'),
  preselectionne('preselectionne'),
  invitationEntretien('invitation_entretien'),
  embauche('embauche'),
  rejete('rejete'),
  inconnu('');

  const CandidatureStatus(this.apiValue);
  final String apiValue;

  static CandidatureStatus fromApi(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    if (s.isEmpty) return CandidatureStatus.inconnu;
    if (s.contains('envoy')) return CandidatureStatus.envoyee;
    if (s.contains('recu') || s == 'received' || s == 'seen') {
      return CandidatureStatus.recue;
    }
    if (s.contains('presel')) return CandidatureStatus.preselectionne;
    if (s.contains('invitation') || s.contains('entretien')) {
      return CandidatureStatus.invitationEntretien;
    }
    if (s.contains('embauch') || s == 'hired') return CandidatureStatus.embauche;
    if (s.contains('rejet') || s == 'rejected' || s == 'refuse') {
      return CandidatureStatus.rejete;
    }
    return CandidatureStatus.inconnu;
  }
}

/// Infos synthetiques du candidat (particulier) telles que renvoyees par
/// CandidatureResource cote back.
class CandidatureCandidate {
  const CandidatureCandidate({
    required this.id,
    this.nom,
    this.prenom,
    this.email,
    this.telephone,
    this.photoProfil,
    this.ville,
    this.pays,
  });

  final int id;
  final String? nom;
  final String? prenom;
  final String? email;
  final String? telephone;
  final String? photoProfil;
  final String? ville;
  final String? pays;

  String get displayName {
    final parts = [prenom, nom]
        .where((e) => e != null && e!.trim().isNotEmpty)
        .cast<String>()
        .toList();
    return parts.isEmpty ? 'Candidat #$id' : parts.join(' ');
  }

  String get initials {
    final full = displayName;
    if (full.isEmpty) return '?';
    return full.trim().substring(0, 1).toUpperCase();
  }

  factory CandidatureCandidate.fromJson(Map<String, dynamic> j) {
    // Le back renvoie parfois `particulier` avec un `user` imbrique.
    final u = j['user'];
    final userMap = u is Map ? Map<String, dynamic>.from(u) : null;
    return CandidatureCandidate(
      id: _i(j['id']),
      nom: _s(j['nom']) ?? _s(userMap?['nom']),
      prenom: _s(j['prenom']) ?? _s(userMap?['prenom']),
      email: _s(j['email']) ?? _s(userMap?['email']),
      telephone: _s(j['telephone']) ?? _s(userMap?['telephone']),
      photoProfil: mediaUrl(_s(j['photo_profil']) ?? _s(userMap?['photo_profil'])),
      ville: _s(j['ville']),
      pays: _s(j['pays']),
    );
  }
}

class CandidatureDocument {
  const CandidatureDocument({required this.title, required this.url});
  final String title;
  final String url;
}

class Candidature {
  const Candidature({
    required this.id,
    this.statutRaw,
    this.dateCreation,
    this.offre,
    this.offreTitre,
    this.candidat,
    this.cvUrl,
    this.motivationUrl,
    this.lettreMotivation,
    this.documents = const [],
    this.disponibilite,
    this.raw = const {},
  });

  final int id;
  final String? statutRaw;
  final String? dateCreation;
  final Offer? offre;
  final String? offreTitre;
  final CandidatureCandidate? candidat;
  final String? cvUrl;
  final String? motivationUrl;
  final String? lettreMotivation;
  final List<CandidatureDocument> documents;
  final String? disponibilite;
  final Map<String, dynamic> raw;

  CandidatureStatus get status => CandidatureStatus.fromApi(statutRaw);

  String get dateCourt =>
      (dateCreation != null && dateCreation!.length >= 10)
          ? dateCreation!.substring(0, 10)
          : (dateCreation ?? '');

  factory Candidature.fromJson(Map<String, dynamic> j) {
    final off = j['offre'] ?? j['offre_emploi'];
    Offer? offre;
    String? titre;
    if (off is Map) {
      offre = Offer.fromJson(Map<String, dynamic>.from(off));
      titre = offre.titre;
    }
    titre ??= j['offre_titre']?.toString() ?? j['titre_poste']?.toString();

    CandidatureCandidate? candidat;
    final part = j['particulier'] ?? j['candidat'] ?? j['candidate'];
    if (part is Map) {
      candidat = CandidatureCandidate.fromJson(Map<String, dynamic>.from(part));
    }

    // autres_documents peut etre une Map {titre: url} ou une liste
    final docs = <CandidatureDocument>[];
    final rawDocs = j['autres_documents'] ?? j['documents'];
    if (rawDocs is Map) {
      rawDocs.forEach((k, v) {
        final url = mediaUrl(v?.toString());
        if (url != null) docs.add(CandidatureDocument(title: k.toString(), url: url));
      });
    } else if (rawDocs is List) {
      for (final d in rawDocs) {
        if (d is Map) {
          final title = _s(d['title']) ?? _s(d['titre']) ?? 'Document';
          final url = mediaUrl(_s(d['url']) ?? _s(d['path']));
          if (url != null) docs.add(CandidatureDocument(title: title, url: url));
        }
      }
    }

    return Candidature(
      id: _i(j['id']),
      statutRaw: _s(j['statut']) ?? _s(j['status']),
      dateCreation: _s(j['created_at']) ??
          _s(j['date_candidature']) ??
          _s(j['date']),
      offre: offre,
      offreTitre: titre,
      candidat: candidat,
      cvUrl: mediaUrl(_s(j['cv_url']) ?? _s(j['cv'])),
      motivationUrl: mediaUrl(_s(j['motivation_url']) ?? _s(j['motivation'])),
      lettreMotivation: _s(j['lettre_motivation']),
      documents: docs,
      disponibilite: _s(j['disponibilite']),
      raw: j,
    );
  }
}

int _i(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String? _s(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}
