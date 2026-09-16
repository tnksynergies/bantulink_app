import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../data/promotions_remote_data_source.dart';
import '../data/models/promotion.dart';

final promotionsDataSourceProvider = Provider<PromotionsRemoteDataSource>(
    (ref) => PromotionsRemoteDataSource(ref.watch(dioProvider)));

final activePromosProvider =
    FutureProvider.autoDispose<List<Promotion>>((ref) async {
  return ref.watch(promotionsDataSourceProvider).activePromos();
});

final flashSalesProvider =
    FutureProvider.autoDispose<List<Promotion>>((ref) async {
  return ref.watch(promotionsDataSourceProvider).flashSales();
});
