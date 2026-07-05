class FreelancerNote {
  const FreelancerNote({
    required this.id,
    required this.score,
    this.description,
    this.dateCreation,
    this.clientNom,
    this.clientPrenom,
    this.missionTitre,
  });

  final int id;
  final int score; // 1..5
  final String? description;
  final String? dateCreation;
  final String? clientNom;
  final String? clientPrenom;
  final String? missionTitre;

  String get authorName {
    final parts = [clientPrenom, clientNom].whereType<String>().where((e) => e.trim().isNotEmpty);
    final joined = parts.join(' ').trim();
    return joined.isEmpty ? 'Client' : joined;
  }

  String get dateCourt {
    final d = dateCreation;
    return (d != null && d.length >= 10) ? d.substring(0, 10) : (d ?? '');
  }

  factory FreelancerNote.fromJson(Map<String, dynamic> j) {
    final client = j['client'];
    final mission = j['mission'];
    return FreelancerNote(
      id: _i(j['id']),
      score: _i(j['score'] ?? j['note']),
      description: _s(j['description']) ?? _s(j['commentaire']),
      dateCreation: _s(j['created_at']) ?? _s(j['date']),
      clientNom: _s(j['client_nom']) ?? (client is Map ? _s(client['nom']) : null),
      clientPrenom: _s(j['client_prenom']) ?? (client is Map ? _s(client['prenom']) : null),
      missionTitre: mission is Map ? _s(mission['titre']) : null,
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
