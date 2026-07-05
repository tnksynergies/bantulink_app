class Competence {
  const Competence({required this.id, required this.nom, this.description, this.niveau});

  final int id;
  final String nom;
  final String? description;
  final String? niveau;

  factory Competence.fromJson(Map<String, dynamic> j) {
    return Competence(
      id: _i(j['id']),
      nom: _s(j['nom']) ?? _s(j['name']) ?? _s(j['libelle']) ?? '',
      description: _s(j['description']),
      niveau: _s(j['niveau']) ?? _s(j['pivot']?['niveau']),
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
