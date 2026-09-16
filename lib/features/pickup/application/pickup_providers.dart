import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../data/pickup_remote_data_source.dart';

final pickupDataSourceProvider = Provider<PickupRemoteDataSource>(
    (ref) => PickupRemoteDataSource(ref.watch(dioProvider)));
