import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../data/boost_remote_data_source.dart';
import '../data/models/boost_pack.dart';
import '../data/models/boost.dart';

final boostDataSourceProvider = Provider<BoostRemoteDataSource>(
    (ref) => BoostRemoteDataSource(ref.watch(dioProvider)));

final boostPacksProvider =
    FutureProvider.autoDispose<List<BoostPack>>((ref) async {
  return ref.watch(boostDataSourceProvider).packs();
});

final myBoostsProvider =
    FutureProvider.autoDispose<List<Boost>>((ref) async {
  return ref.watch(boostDataSourceProvider).myBoosts();
});
