import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';
import 'models/faq_item.dart';
import 'models/support_ticket.dart';

class ChatbotRemoteDataSource {
  ChatbotRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<FaqItem>> faqList({String? search}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _dio.get('/faq', queryParameters: params);
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => FaqItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<SupportTicket>> myTickets() async {
    try {
      final res = await _dio.get('/support-tickets');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
    int? faqItemId,
    String priority = 'medium',
  }) async {
    try {
      final res = await _dio.post('/support-tickets', data: {
        'subject': subject,
        'message': message,
        if (faqItemId != null) 'faq_item_id': faqItemId,
        'priority': priority,
      });
      return SupportTicket.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
