import 'package:dio/dio.dart';
import 'models/boost_pack.dart';
import 'models/boost.dart';

class BoostRemoteDataSource {
  final Dio _dio;
  BoostRemoteDataSource(this._dio);

  Future<List<BoostPack>> packs() async {
    final res = await _dio.get('/boost-packs');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => BoostPack.fromJson(e)).toList();
  }

  Future<Boost> store({
    required int boostPackId,
    required String boostableType,
    required int boostableId,
  }) async {
    final res = await _dio.post('/boosts', data: {
      'boost_pack_id': boostPackId,
      'boostable_type': boostableType,
      'boostable_id': boostableId,
    });
    return Boost.fromJson(res.data['data']);
  }

  Future<List<Boost>> myBoosts() async {
    final res = await _dio.get('/boosts/my');
    final list = res.data['data'] as List? ?? [];
    return list.map((e) => Boost.fromJson(e)).toList();
  }

  Future<void> cancel(int id) async {
    await _dio.patch('/boosts/$id/cancel');
  }
}
