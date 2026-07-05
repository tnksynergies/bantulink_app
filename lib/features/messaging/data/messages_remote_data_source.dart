import 'package:dio/dio.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_unwrap.dart';
import 'models/conversation.dart';
import 'models/message.dart';

class MessagesRemoteDataSource {
  MessagesRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<Conversation>> listConversations() async {
    try {
      final res = await _dio.get('/conversations');
      return unwrapList(res.data)
          .whereType<Map>()
          .map((e) => Conversation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Conversation> getConversation(int id) async {
    try {
      final res = await _dio.get('/conversations/$id');
      return Conversation.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Message> sendMessage(int conversationId, String content) async {
    try {
      final res = await _dio.post('/messages/$conversationId',
          data: {'content': content});
      final data = res.data;
      final map = (data is Map && data['data'] is Map)
          ? Map<String, dynamic>.from(data['data'] as Map)
          : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});
      return Message.fromJson(map);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Cree (ou recupere) une conversation privee avec un autre utilisateur.
  Future<Conversation> createConversation(int otherUserId) async {
    try {
      final res = await _dio.post('/conversations', data: {'user_id': otherUserId});
      return Conversation.fromJson(unwrapMap(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
