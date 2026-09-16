import 'package:dio/dio.dart';
import 'models/loyalty_level.dart';
import 'models/loyalty_account.dart';

class LoyaltyRemoteDataSource {
  final Dio _dio;
  LoyaltyRemoteDataSource(this._dio);

  Future<List<LoyaltyLevel>> levels() async {
    final res = await _dio.get('/loyalty/levels');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => LoyaltyLevel.fromJson(e)).toList();
  }

  Future<LoyaltyAccount> myAccount() async {
    final res = await _dio.get('/loyalty/my-account');
    return LoyaltyAccount.fromJson(res.data['data'] ?? {});
  }

  Future<List<Map<String, dynamic>>> history({int page = 1}) async {
    final res = await _dio.get('/loyalty/history', queryParameters: {'page': page});
    final list = res.data['data']?['data'] as List? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> redeem(int points) async {
    await _dio.post('/loyalty/redeem', data: {'points': points});
  }
}
