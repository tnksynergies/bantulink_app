import '../../../../core/utils/media_url.dart';

class Employeur {
  const Employeur({
    this.id,
    this.nom,
    this.logo,
    this.ville,
    this.adresse,
    this.email,
    this.telephone,
    this.siteWeb,
    this.description,
  });

  final int? id;
  final String? nom;
  final String? logo;
  final String? ville;
  final String? adresse;
  final String? email;
  final String? telephone;
  final String? siteWeb;
  final String? description;

  factory Employeur.fromJson(Map<String, dynamic> j) {
    return Employeur(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}'),
      nom: _s(j['nom_entreprise']) ?? _s(j['nom']) ?? _s(j['name']) ?? _s(j['raison_sociale']),
      logo: mediaUrl(_s(j['logo']) ?? _s(j['logo_img']) ?? _s(j['image'])),
      ville: _s(j['ville']),
      adresse: _s(j['adresse']),
      email: _s(j['email_pro']) ?? _s(j['email']),
      telephone: _s(j['telephone_pro']) ?? _s(j['telephone']),
      siteWeb: _s(j['site_web']) ?? _s(j['siteweb']),
      description: _s(j['description_entreprise']) ?? _s(j['description']),
    );
  }
}

String? _s(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}
