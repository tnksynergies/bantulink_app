import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/freelancers_providers.dart';
import '../data/models/freelancer.dart';
import 'widgets/provider_card.dart';

class FreelancersSearchScreen extends ConsumerStatefulWidget {
  const FreelancersSearchScreen({super.key});

  @override
  ConsumerState<FreelancersSearchScreen> createState() =>
      _FreelancersSearchScreenState();
}

class _FreelancersSearchScreenState
    extends ConsumerState<FreelancersSearchScreen> {
  final _serviceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  List<Freelancer> _filter(List<Freelancer> all) {
    final service = _serviceCtrl.text.trim().toLowerCase();
    final location = _locationCtrl.text.trim().toLowerCase();
    return all.where((f) {
      if (service.isNotEmpty) {
        final inTitle = (f.titrePro ?? '').toLowerCase().contains(service);
        final inSkills = f.competences.any((c) => c.nom.toLowerCase().contains(service));
        if (!inTitle && !inSkills) return false;
      }
      if (location.isNotEmpty) {
        if (!f.localisation.toLowerCase().contains(location)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(freelancersListProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('provider.search_title')),
        actions: [
          IconButton(
            tooltip: context.tr('mission.my_missions'),
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push('/mes-missions'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(freelancersListProvider),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _serviceCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: context.tr('provider.search_hint'),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: context.tr('provider.location_hint'),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            asyncList.when(
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                  child: Center(
                      child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('$e', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(freelancersListProvider),
                      child: Text(context.tr('common.retry')),
                    ),
                  ],
                ),
              ))),
              data: (all) {
                final filtered = _filter(all);
                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(context.tr('provider.no_results'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 320,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ProviderCard(freelancer: filtered[i]),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
