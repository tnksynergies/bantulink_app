import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';

class RefDataSource {
  RefDataSource(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> categories() async {
    try {
      final res = await _dio.get('/offres-categories');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<String>> experienceLevels() async {
    try {
      final res = await _dio.get('/offres/niveaux');
      final data = res.data;
      final out = <String>[];
      if (data is Map) {
        for (final v in data.values) {
          if (v != null) out.add(_decode(v.toString()));
        }
      } else if (data is List) {
        for (final v in data) {
          out.add(_decode(v.toString()));
        }
      }
      return out;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<String>> contractTypes() async {
    try {
      final res = await _dio.get('/types-contrat');
      final data = res.data;
      if (data is Map && data['types_contrat'] is List) {
        return (data['types_contrat'] as List).map((e) => e.toString()).toList();
      }
      return unwrapList(data).map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> skills() async {
    try {
      final res = await _dio.get('/skills');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  String _decode(String s) => s.replaceAll('&lt;', '<').replaceAll('&gt;', '>');
}
