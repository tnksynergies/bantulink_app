import '../../../../core/utils/media_url.dart';

class RealisationMedia {
  const RealisationMedia({required this.id, required this.type, required this.path});

  final int id;
  /// 'image' | 'document' | 'video'
  final String type;
  final String path;

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isDocument => type == 'document';

  factory RealisationMedia.fromJson(Map<String, dynamic> j) {
    final raw = (j['media_path'] ?? j['path'] ?? j['url'] ?? '').toString();
    return RealisationMedia(
      id: _i(j['id']),
      type: (j['media_type'] ?? j['type'] ?? 'image').toString(),
      path: mediaUrl(raw) ?? raw,
    );
  }
}

int _i(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
