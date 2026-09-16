class CommunityTopic {
  CommunityTopic({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.slug,
    this.icon,
    this.postsCount = 0,
  });

  final int id;
  final String nameFr;
  final String nameEn;
  final String slug;
  final String? icon;
  final int postsCount;

  factory CommunityTopic.fromJson(Map<String, dynamic> json) {
    return CommunityTopic(
      id: json['id'] as int,
      nameFr: json['name_fr'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String?,
      postsCount: json['posts_count'] as int? ?? 0,
    );
  }
}
