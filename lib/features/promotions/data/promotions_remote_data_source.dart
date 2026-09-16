import 'package:dio/dio.dart';
import 'models/promotion.dart';

class PromotionsRemoteDataSource {
  final Dio _dio;
  PromotionsRemoteDataSource(this._dio);

  Future<List<Promotion>> activePromos() async {
    final res = await _dio.get('/promotions');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => Promotion.fromJson(e)).toList();
  }

  Future<List<Promotion>> flashSales() async {
    final res = await _dio.get('/promotions/flash-sales');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => Promotion.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> applyCode(String code, int amount) async {
    final res = await _dio.post('/promotions/apply', data: {
      'code': code,
      'amount': amount,
    });
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }
}
