import 'realisation_media.dart';

class Realisation {
  const Realisation({
    required this.id,
    this.titre,
    this.description,
    this.dateRealisation,
    this.localisation,
    this.lien,
    this.medias = const [],
  });

  final int id;
  final String? titre;
  final String? description;
  final String? dateRealisation;
  final String? localisation;
  final String? lien;
  final List<RealisationMedia> medias;

  List<RealisationMedia> get images =>
      medias.where((m) => m.isImage).toList(growable: false);
  List<RealisationMedia> get documents =>
      medias.where((m) => m.isDocument).toList(growable: false);
  List<RealisationMedia> get videos =>
      medias.where((m) => m.isVideo).toList(growable: false);

  RealisationMedia? get cover =>
      images.isNotEmpty ? images.first : (medias.isNotEmpty ? medias.first : null);

  factory Realisation.fromJson(Map<String, dynamic> j) {
    final medias = <RealisationMedia>[];
    // Format 1 : liste plate "medias"
    final rawMedias = j['medias'];
    if (rawMedias is List) {
      for (final m in rawMedias) {
        if (m is Map) medias.add(RealisationMedia.fromJson(Map<String, dynamic>.from(m)));
      }
    } else if (rawMedias is Map) {
      // Format 2 : groupé { images: [...], documents: [...], videos: [...] }
      for (final key in const ['images', 'documents', 'videos']) {
        final v = rawMedias[key];
        if (v is List) {
          for (final m in v) {
            if (m is Map) {
              final map = Map<String, dynamic>.from(m);
              map['media_type'] ??= key.substring(0, key.length - 1); // "images" -> "image"
              medias.add(RealisationMedia.fromJson(map));
            }
          }
        }
      }
    }

    return Realisation(
      id: _i(j['id']),
      titre: _s(j['titre']),
      description: _s(j['description']),
      dateRealisation: _s(j['date_realisation']) ?? _s(j['date']),
      localisation: _s(j['localisation']),
      lien: _s(j['lien']) ?? _s(j['url']),
      medias: medias,
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
