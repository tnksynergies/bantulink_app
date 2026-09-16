import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../data/directory_remote_data_source.dart';
import '../data/models/business_listing.dart';

final directoryDataSourceProvider = Provider<DirectoryRemoteDataSource>(
    (ref) => DirectoryRemoteDataSource(ref.watch(dioProvider)));

final directoryListProvider =
    FutureProvider.autoDispose<List<BusinessListing>>((ref) async {
  return ref.watch(directoryDataSourceProvider).list();
});

final businessDetailProvider =
    FutureProvider.autoDispose.family<BusinessListing, String>((ref, slug) async {
  return ref.watch(directoryDataSourceProvider).show(slug);
});
