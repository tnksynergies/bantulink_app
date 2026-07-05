import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/realtime/echo_service.dart';
import '../data/messages_remote_data_source.dart';
import '../data/models/conversation.dart';

final messagesDataSourceProvider = Provider<MessagesRemoteDataSource>(
    (ref) => MessagesRemoteDataSource(ref.watch(dioProvider)));

final echoServiceProvider = Provider<EchoService>((ref) {
  final service = createEchoService(ref.watch(dioProvider));
  ref.onDispose(service.dispose);
  return service;
});

final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  return ref.watch(messagesDataSourceProvider).listConversations();
});
