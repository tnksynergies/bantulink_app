import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../data/loyalty_remote_data_source.dart';
import '../data/models/loyalty_level.dart';
import '../data/models/loyalty_account.dart';

final loyaltyDataSourceProvider = Provider<LoyaltyRemoteDataSource>(
    (ref) => LoyaltyRemoteDataSource(ref.watch(dioProvider)));

final loyaltyLevelsProvider =
    FutureProvider.autoDispose<List<LoyaltyLevel>>((ref) async {
  return ref.watch(loyaltyDataSourceProvider).levels();
});

final loyaltyAccountProvider =
    FutureProvider.autoDispose<LoyaltyAccount>((ref) async {
  return ref.watch(loyaltyDataSourceProvider).myAccount();
});
