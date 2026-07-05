import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../application/jobs_providers.dart';
import '../data/models/offer.dart';
import 'widgets/offer_card.dart';

const _pageSize = 8;

class OffersListView extends ConsumerStatefulWidget {
  const OffersListView({super.key});
  @override
  ConsumerState<OffersListView> createState() => _OffersListViewState();
}

class _OffersListViewState extends ConsumerState<OffersListView> {
  String _query = '';
  int _page = 1;

  List<Offer> _filter(List<Offer> offers) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return offers;
    return offers.where((o) {
      return o.titreSafe.toLowerCase().contains(q) ||
          (o.ville ?? '').toLowerCase().contains(q) ||
          (o.employeur?.nom ?? '').toLowerCase().contains(q) ||
          (o.categorie ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(offersProvider);
    final scores = ref.watch(matchingScoresProvider).valueOrNull ?? const {};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() {
              _query = v;
              _page = 1;
            }),
            decoration: const InputDecoration(
              hintText: 'Rechercher par titre, ville, entreprise...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(offersProvider),
            ),
            data: (offers) {
              final filtered = _filter(offers);
              final totalPages =
                  (filtered.length / _pageSize).ceil().clamp(1, 9999);
              if (_page > totalPages) _page = totalPages;
              final start = (_page - 1) * _pageSize;
              final pageItems = filtered.skip(start).take(_pageSize).toList();

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(offersProvider);
                  ref.invalidate(matchingScoresProvider);
                  await ref.read(offersProvider.future);
                },
                child: filtered.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                              child: Text('Aucune offre trouvee.',
                                  style: TextStyle(color: AppColors.textMuted))),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        children: [
                          ...pageItems.map((o) => OfferCard(
                                offer: o,
                                score: scores[o.id],
                                onTap: () => context.push('/offre/${o.id}'),
                              )),
                          if (totalPages > 1)
                            _Pager(
                              page: _page,
                              totalPages: totalPages,
                              onPrev: _page > 1
                                  ? () => setState(() => _page--)
                                  : null,
                              onNext: _page < totalPages
                                  ? () => setState(() => _page++)
                                  : null,
                            ),
                        ],
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  });
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Page $page sur $totalPages',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton.filledTonal(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reessayer')),
          ],
        ),
      ),
    );
  }
}
