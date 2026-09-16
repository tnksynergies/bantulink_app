import 'package:dio/dio.dart';

class PickupRemoteDataSource {
  final Dio _dio;
  PickupRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> generate(int commandeId) async {
    final res = await _dio.post('/pickup/generate/$commandeId');
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> validate(String token) async {
    final res = await _dio.post('/pickup/validate', data: {'token': token});
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<Map<String, dynamic>> status(int commandeId) async {
    final res = await _dio.get('/pickup/status/$commandeId');
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }
}
