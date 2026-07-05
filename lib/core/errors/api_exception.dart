import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      // Erreurs de validation Laravel (422) : { errors: { champ: [msg] } }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return ApiException(first.first.toString(), statusCode: status);
        }
      }
      if (data['message'] is String) {
        return ApiException(data['message'] as String, statusCode: status);
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connexion trop lente. Verifie ton reseau et reessaie.',
          statusCode: status,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'Impossible de joindre le serveur. Verifie ta connexion.',
          statusCode: status,
        );
      default:
        return ApiException('Une erreur est survenue. Reessaie.',
            statusCode: status);
    }
  }
}
