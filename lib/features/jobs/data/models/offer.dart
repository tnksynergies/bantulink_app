import 'employeur.dart';

class Offer {
  const Offer({
    required this.id,
    this.titre,
    this.description,
    this.responsabilites,
    this.exigences,
    this.ville,
    this.typeContrat,
    this.niveauExperience,
    this.remuneration,
    this.fonction,
    this.statut,
    this.datePublication,
    this.dateLimite,
    this.nombreVues,
    this.urlCandidature,
    this.emailCandidature,
    this.candidaturesCount = 0,
    this.isFavoris = false,
    this.dejaCandidature = false,
    this.employeur,
    this.categorie,
    this.skills = const [],
    this.raw = const {},
  });

  final int id;
  final String? titre;
  final String? description;
  final String? responsabilites;
  final String? exigences;
  final String? ville;
  final String? typeContrat;
  final String? niveauExperience;
  final String? remuneration;
  final String? fonction;
  final String? statut;
  final String? datePublication;
  final String? dateLimite;
  final int? nombreVues;
  final String? urlCandidature;
  final String? emailCandidature;
  final int candidaturesCount;
  final bool isFavoris;
  final bool dejaCandidature;
  final Employeur? employeur;
  final String? categorie;
  final List<String> skills;
  final Map<String, dynamic> raw;

  String get titreSafe => titre ?? 'Offre #$id';
  String _short(String? d) => (d != null && d.length >= 10) ? d.substring(0, 10) : (d ?? '');
  String get datePubCourt => _short(datePublication);
  String get dateLimiteCourt => _short(dateLimite);

  factory Offer.fromJson(Map<String, dynamic> j) {
    final emp = j['employeur'] ?? j['entreprise'] ?? j['professionnel'];
    final cat = j['categorie'] ?? j['category'];

    final skills = <String>[];
    final rawSkills = j['skills'] ?? j['competences'];
    if (rawSkills is List) {
      for (final s in rawSkills) {
        if (s is String) {
          skills.add(s);
        } else if (s is Map) {
          final n = s['nom'] ?? s['name'] ?? s['libelle'];
          if (n != null) skills.add(n.toString());
        }
      }
    }

    return Offer(
      id: _i(j['id']),
      titre: _s(j['titre_poste']) ?? _s(j['titre']) ?? _s(j['poste']) ?? _s(j['intitule']),
      description: _s(j['description']) ?? _s(j['description_poste']) ?? _s(j['contenu']),
      responsabilites: _s(j['responsabilites']) ?? _s(j['missions']),
      exigences: _s(j['exigences']) ?? _s(j['profil_requis']) ?? _s(j['competences_requises']),
      ville: _s(j['ville']) ?? _s(j['lieu']) ?? _s(j['localisation']),
      typeContrat: _s(j['type_contrat']) ?? _s(j['contrat']) ?? _s(j['typeContrat']),
      niveauExperience: _s(j['niveau_experience']) ?? _s(j['experience']) ?? _s(j['niveau_exp']),
      remuneration: _s(j['remuneration']) ?? _s(j['salaire']) ?? _s(j['salaire_propose']),
      fonction: _s(j['fonction']),
      statut: _s(j['statut']),
      datePublication: _s(j['date_publication']) ?? _s(j['created_at']) ?? _s(j['date_pub']),
      dateLimite: _s(j['date_limite']) ?? _s(j['date_expiration']) ?? _s(j['date_limite_soumission']) ?? _s(j['deadline']),
      nombreVues: j['nombre_vues'] is int ? j['nombre_vues'] as int : int.tryParse('${j['nombre_vues']}'),
      urlCandidature: _s(j['url_candidature']),
      emailCandidature: _s(j['email_candidature']) ?? _s(j['email_recrutement']),
      candidaturesCount: j['candidatures_count'] is int
          ? j['candidatures_count'] as int
          : int.tryParse('${j['candidatures_count']}') ?? 0,
      isFavoris: j['is_favoris'] == true,
      dejaCandidature: j['deja_candidature'] == true,
      employeur: emp is Map ? Employeur.fromJson(Map<String, dynamic>.from(emp)) : null,
      categorie: cat is Map ? (_s(cat['nom']) ?? _s(cat['name'])) : _s(cat),
      skills: skills,
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
