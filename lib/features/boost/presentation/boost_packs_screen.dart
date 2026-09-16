import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../application/boost_providers.dart';
import '../data/models/boost_pack.dart';

class BoostPacksScreen extends ConsumerStatefulWidget {
  final String boostableType;
  final int boostableId;

  const BoostPacksScreen({
    super.key,
    required this.boostableType,
    required this.boostableId,
  });

  @override
  ConsumerState<BoostPacksScreen> createState() => _BoostPacksScreenState();
}

class _BoostPacksScreenState extends ConsumerState<BoostPacksScreen> {
  bool _submitting = false;

  Future<void> _selectPack(BoostPack pack) async {
    setState(() => _submitting = true);
    try {
      await ref.read(boostDataSourceProvider).store(
            boostPackId: pack.id,
            boostableType: widget.boostableType,
            boostableId: widget.boostableId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('boost.activated'))),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Color _packColor(int index) {
    const colors = [AppColors.primary, Colors.orange, Colors.purple];
    return colors[index % colors.length];
  }

  String _packBadge(int index) {
    const badges = ['Basic', 'Premium', 'VIP'];
    return badges[index % badges.length];
  }

  @override
  Widget build(BuildContext context) {
    final packsAsync = ref.watch(boostPacksProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('boost.choosePack'))),
      body: packsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (packs) {
          if (packs.isEmpty) {
            return Center(child: Text(context.tr('boost.noPacks')));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: packs.length,
            itemBuilder: (_, i) {
              final pack = packs[i];
              final color = _packColor(i);
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _packBadge(i),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${pack.price} FCFA',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        pack.labelFr,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pack.durationDays} ${context.tr('boost.days')}',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMuted),
                      ),
                      if (pack.features.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...pack.features.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 16, color: color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(f,
                                        style: const TextStyle(fontSize: 13)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : () => _selectPack(pack),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(context.tr('boost.select'),
                                  style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
