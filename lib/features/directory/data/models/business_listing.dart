class BusinessListing {
  BusinessListing({
    required this.id,
    required this.name,
    required this.slug,
    this.category,
    this.logo,
    this.cover,
    this.phone,
    this.email,
    this.website,
    this.description,
    this.address,
    this.city,
    this.country,
    this.isVerified = false,
    this.reviewsAvg,
    this.reviewsCount = 0,
  });

  final int id;
  final String name;
  final String slug;
  final String? category;
  final String? logo;
  final String? cover;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final String? address;
  final String? city;
  final String? country;
  final bool isVerified;
  final double? reviewsAvg;
  final int reviewsCount;

  factory BusinessListing.fromJson(Map<String, dynamic> json) {
    return BusinessListing(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      category: json['category'] as String?,
      logo: json['logo'] as String?,
      cover: json['cover'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      reviewsAvg: (json['reviews_avg_rating'] as num?)?.toDouble(),
      reviewsCount: json['reviews_count'] as int? ?? 0,
    );
  }
}
