import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../data/chatbot_remote_data_source.dart';
import '../data/models/faq_item.dart';
import '../data/models/support_ticket.dart';

final chatbotDataSourceProvider = Provider<ChatbotRemoteDataSource>(
    (ref) => ChatbotRemoteDataSource(ref.watch(dioProvider)));

final faqListProvider =
    FutureProvider.autoDispose<List<FaqItem>>((ref) async {
  return ref.watch(chatbotDataSourceProvider).faqList();
});

final myTicketsProvider =
    FutureProvider.autoDispose<List<SupportTicket>>((ref) async {
  return ref.watch(chatbotDataSourceProvider).myTickets();
});
