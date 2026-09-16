import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';
import 'models/business_listing.dart';

class DirectoryRemoteDataSource {
  DirectoryRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<BusinessListing>> list({String? category, String? city, String? search}) async {
    try {
      final params = <String, dynamic>{};
      if (category != null) params['category'] = category;
      if (city != null) params['city'] = city;
      if (search != null) params['search'] = search;
      final res = await _dio.get('/business-directory', queryParameters: params);
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => BusinessListing.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<BusinessListing> show(String slug) async {
    try {
      final res = await _dio.get('/business-directory/$slug');
      return BusinessListing.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<BusinessListing> store({
    required String name,
    String? category,
    String? description,
    String? phone,
    String? email,
    String? city,
    String? country,
    String? logoPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (logoPath != null) 'logo': await MultipartFile.fromFile(logoPath),
      });
      final res = await _dio.post('/business-directory', data: formData);
      return BusinessListing.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> addReview(int businessId, int rating, String? comment) async {
    try {
      await _dio.post('/business-directory/$businessId/review', data: {
        'rating': rating,
        if (comment != null) 'comment': comment,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
