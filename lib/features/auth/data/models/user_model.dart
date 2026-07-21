class User {
  const User({
    required this.id,
    required this.email,
    this.name,
    this.nom,
    this.prenom,
    this.telephone,
    this.photoProfil,
    this.roleActif,
    this.roles = const [],
    this.raw = const {},
  });

  final int id;
  final String email;
  final String? name;
  final String? nom;
  final String? prenom;
  final String? telephone;
  final String? photoProfil;
  final String? roleActif;
  final List<String> roles;
  final Map<String, dynamic> raw;

  String get fullName {
    final parts = [prenom, nom].where((e) => e != null && e!.trim().isNotEmpty);
    final joined = parts.join(' ').trim();
    if (joined.isNotEmpty) return joined;
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    return email;
  }

  String get displayFirstName {
    if (prenom != null && prenom!.trim().isNotEmpty) return prenom!.trim();
    final fn = fullName;
    return fn.contains('@') ? '' : fn.split(' ').first;
  }

  bool get hasCandidatProfile {
    final r = (roleActif ?? '').toLowerCase();
    if (r.contains('candidat')) return true;
    return raw['particulier'] != null;
  }

  /// Un utilisateur est considere recruteur si et seulement si il a un
  /// enregistrement `professionnel` en base. Meme regle que le backend
  /// (User::isRecruteur = professionnel()->exists()) et que la policy
  /// can:isRecruteur. On ne se base PAS sur les libelles de roles (qui
  /// peuvent etre attaches sans record) ni sur d'autres heuristiques :
  /// c'est l'existence de l'enregistrement pro qui fait autorite.
  bool get hasRecruteurProfile => raw['professionnel'] != null;

  Map<String, dynamic>? get particulierRaw {
    final p = raw['particulier'];
    return p is Map ? Map<String, dynamic>.from(p) : null;
  }

  Map<String, dynamic>? get professionnelRaw {
    final p = raw['professionnel'];
    return p is Map ? Map<String, dynamic>.from(p) : null;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final roles = <String>[];
    final rawRoles = json['roles'] ?? json['role'];
    if (rawRoles is List) {
      for (final r in rawRoles) {
        if (r is String) {
          roles.add(r);
        } else if (r is Map && r['name'] != null) {
          roles.add(r['name'].toString());
        }
      }
    } else if (rawRoles is String) {
      roles.add(rawRoles);
    }
    return User(
      id: _asInt(json['id']),
      email: (json['email'] ?? '').toString(),
      name: json['name']?.toString(),
      nom: json['nom']?.toString(),
      prenom: json['prenom']?.toString(),
      telephone: (json['telephone'] ?? json['phone'])?.toString(),
      photoProfil: (json['photo_profil'] ?? json['photoProfil'])?.toString(),
      roleActif: (json['role_actif'] ?? json['roleActif'])?.toString(),
      roles: roles,
      raw: json,
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
