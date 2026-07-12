import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/invoice_pdf.dart';
import '../application/market_providers.dart';
import '../data/models/order.dart';
import 'market_colors.dart';

/// Espace acheteur aligne sur le BuyerDashboard web :
/// onglets Commandes + Historique des paiements.
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('market.my_orders')),
          bottom: TabBar(
            indicatorColor: MarketColors.primary,
            labelColor: MarketColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: context.tr('market.my_orders')),
              Tab(text: context.tr('market.payments_history')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersTab(),
            _PaymentsTab(),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myOrdersProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myOrdersProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(myOrdersProvider),
                  child: Text(context.tr('common.retry')),
                ),
              ],
            ),
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                const Icon(Icons.receipt_long_outlined,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Center(
                  child: Text(context.tr('market.no_orders'),
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              ],
            );
          }
          final sorted = [...orders]
            ..sort((a, b) =>
                (b.dateCommande ?? '').compareTo(a.dateCommande ?? ''));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _OrderCard(order: sorted[i]),
          );
        },
      ),
    );
  }
}

/// Historique des paiements marketplace (GET /paiements/history?type=marketplace).
class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(marketPaymentsHistoryProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(marketPaymentsHistoryProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 100),
            Center(
                child: Text('$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted))),
          ],
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                const Icon(Icons.credit_card_outlined,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Center(
                  child: Text(context.tr('market.no_payments'),
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _PaymentTile(payment: payments[i]),
          );
        },
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    final status = (payment['status'] ?? '').toString().toLowerCase();
    final isOk = status == 'success' ||
        status == 'succeeded' ||
        status == 'completed' ||
        status == 'active';
    final isPending =
        status == 'pending' || status == 'processing' || status == 'waiting';
    final color = isOk
        ? MarketColors.primary
        : (isPending ? AppColors.warning : AppColors.error);
    final amount = payment['amount']?.toString() ?? '0';
    final currency = payment['currency']?.toString() ?? 'XAF';
    final ref = payment['reference']?.toString() ?? '';
    final date = (payment['created_at'] ?? '').toString();
    final dateCourt = date.length >= 10 ? date.substring(0, 10) : date;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(MarketColors.radius),
        border: Border.all(color: MarketColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
                isOk
                    ? Icons.check_circle_outline
                    : (isPending ? Icons.schedule : Icons.error_outline),
                color: color,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$amount $currency',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(
                  [
                    if (ref.isNotEmpty)
                      '#${ref.length > 10 ? ref.substring(0, 10) : ref}',
                    dateCourt,
                  ].join(' · '),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(status,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${context.tr('market.order_number')} #${order.id}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${order.itemsCount} ${context.tr('market.articles')} · ${order.dateCourt}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Text(
                '${(order.total ?? 0).toStringAsFixed(0)} XAF',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: MarketColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final OrderStatus status;

  ({Color bg, Color fg}) _style() {
    switch (status) {
      case OrderStatus.enAttente:
        return (bg: const Color(0xFFFFF5D6), fg: const Color(0xFFB88700));
      case OrderStatus.confirmee:
        return (bg: const Color(0xFFDBEAFE), fg: const Color(0xFF1E40AF));
      case OrderStatus.payee:
      case OrderStatus.livree:
        return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF15803D));
      case OrderStatus.expediee:
        return (bg: const Color(0xFFEDE9FE), fg: const Color(0xFF6D28D9));
      case OrderStatus.annulee:
        return (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C));
      case OrderStatus.inconnu:
        return (bg: const Color(0xFFF3F4F6), fg: const Color(0xFF4B5563));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        context.tr(status.i18nKey),
        style: TextStyle(
            color: s.fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${context.tr('market.order_number')} #${order.id}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(order.dateCourt,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 16),

          // Produits
          for (final item in order.produits)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      image: item.produit.coverImage != null
                          ? DecorationImage(
                              image: NetworkImage(item.produit.coverImage!),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: item.produit.coverImage == null
                        ? const Icon(Icons.image_outlined,
                            size: 20, color: AppColors.textMuted)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.produit.nomSafe,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('x${item.quantite}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Text('${item.lineTotal.toStringAsFixed(0)} XAF',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

          const Divider(height: 24),

          _row(context.tr('market.subtotal'),
              '${(order.sousTotal ?? 0).toStringAsFixed(0)} XAF'),
          _row(context.tr('market.delivery_fees'),
              '${(order.fraisLivraison ?? 0).toStringAsFixed(0)} XAF'),
          const SizedBox(height: 6),
          _row(context.tr('market.total'),
              '${(order.total ?? 0).toStringAsFixed(0)} XAF',
              bold: true),
          // NB: la couleur "bold" du total est geree dans _row.

          if (order.adresseLivraison != null ||
              order.villeLivraison != null) ...[
            const Divider(height: 24),
            Text(context.tr('market.delivery_info'),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              [
                order.adresseLivraison,
                order.villeLivraison,
                order.paysLivraison,
                order.telLivraison,
              ].whereType<String>().join(' · '),
              style: const TextStyle(fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),

          // Impression / telechargement de la facture (point 7)
          OutlinedButton.icon(
            onPressed: () => _printInvoice(context),
            icon: const Icon(Icons.print_outlined,
                size: 18, color: MarketColors.primary),
            label: Text(context.tr('invoice.download'),
                style: const TextStyle(color: MarketColors.primary)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: MarketColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _printInvoice(BuildContext context) async {
    // Capture des labels et du messenger AVANT l'async gap.
    final labels = <String, String>{
      for (final k in const [
        'invoice.title',
        'invoice.order',
        'invoice.date',
        'invoice.item',
        'invoice.qty',
        'invoice.unit_price',
        'invoice.total',
        'invoice.subtotal',
        'invoice.delivery',
        'invoice.grand_total',
        'invoice.fees_note',
        'invoice.generated_by',
      ])
        k: context.tr(k),
    };
    final messenger = ScaffoldMessenger.of(context);
    try {
      await InvoicePdf.printOrder(order, (k) => labels[k] ?? k);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: bold ? AppColors.textPrimary : AppColors.textMuted)),
          const Expanded(child: SizedBox()),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 16 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: bold ? MarketColors.primary : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
