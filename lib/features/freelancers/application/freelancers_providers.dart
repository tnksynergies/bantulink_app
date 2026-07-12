import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_providers.dart';
import '../data/freelancers_remote_data_source.dart';
import '../data/models/freelancer.dart';
import '../data/models/freelancer_note.dart';
import '../data/models/realisation.dart';

final freelancersDataSourceProvider = Provider<FreelancersRemoteDataSource>(
    (ref) => FreelancersRemoteDataSource(ref.watch(dioProvider)));

final freelancersListProvider =
    FutureProvider.autoDispose<List<Freelancer>>((ref) async {
  final list = await ref.watch(freelancersDataSourceProvider).list();
  // Du plus recent au plus ancien (tri defensif : le back trie aussi,
  // mais on garantit l'ordre quel que soit le serveur).
  list.sort((a, b) {
    final da = a.createdAt ?? '';
    final db = b.createdAt ?? '';
    final cmp = db.compareTo(da);
    return cmp != 0 ? cmp : b.id.compareTo(a.id);
  });
  return list;
});

final freelancerDetailProvider =
    FutureProvider.autoDispose.family<Freelancer, int>((ref, id) async {
  return ref.watch(freelancersDataSourceProvider).get(id);
});

final freelancerNotesProvider =
    FutureProvider.autoDispose.family<List<FreelancerNote>, int>((ref, id) async {
  return ref.watch(freelancersDataSourceProvider).notesOf(id);
});

/// Profil du freelancer connecte (null si l'utilisateur n'est pas encore prestataire).
final myFreelancerProfileProvider =
    FutureProvider.autoDispose<Freelancer?>((ref) async {
  return ref.watch(freelancersDataSourceProvider).myProfileOrNull();
});

final myRealisationsProvider =
    FutureProvider.autoDispose<List<Realisation>>((ref) async {
  return ref.watch(freelancersDataSourceProvider).myRealisations();
});

final walletProvider = FutureProvider.autoDispose<WalletData>((ref) async {
  return ref.watch(freelancersDataSourceProvider).getWallet();
});
