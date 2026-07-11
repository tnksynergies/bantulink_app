import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../application/vendor_providers.dart';
import '../data/models/order.dart';
import '../data/models/product.dart';
import 'market_colors.dart';

/// Dashboard vendeur aligne sur la version web bantu-market-connect :
/// KPI (ventes, stock, commandes, produits) + 4 onglets
/// (Produits, Commandes recues, Portefeuille, Profil boutique).
class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('market.seller_dashboard')),
          actions: [
            IconButton(
              tooltip: context.tr('fees.vendor_pricing_title'),
              icon: const Icon(Icons.percent),
              onPressed: () => context.push('/vendeur/tarifs'),
            ),
            IconButton(
              tooltip: context.tr('market.title'),
              icon: const Icon(Icons.storefront_outlined),
              onPressed: () => context.go('/boutique'),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: MarketColors.primary,
            labelColor: MarketColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: context.tr('market.my_products')),
              Tab(text: context.tr('market.seller_orders')),
              Tab(text: context.tr('market.seller_wallet')),
              Tab(text: context.tr('market.shop_profile')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProductsTab(),
            _OrdersTab(),
            _WalletTab(),
            _ShopProfileTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Stats

class _StatsHeader extends ConsumerWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(myVendorProductsProvider).valueOrNull ?? const [];
    final orders = ref.watch(vendorOrdersProvider).valueOrNull ?? const [];
    final totalSales = orders.fold<num>(0, (acc, o) => acc + (o.total ?? 0));
    final totalStock =
        products.fold<int>(0, (acc, p) => acc + (p.stockQtte ?? 0));

    Widget card(String label, String value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(MarketColors.radius),
            border: Border.all(color: MarketColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 6),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          card(context.tr('market.stats_sales'),
              '${totalSales.toStringAsFixed(0)} XAF',
              Icons.payments_outlined, MarketColors.primary),
          const SizedBox(width: 8),
          card(context.tr('market.stats_stock'), '$totalStock',
              Icons.inventory_2_outlined, MarketColors.accent),
          const SizedBox(width: 8),
          card(context.tr('market.stats_orders'), '${orders.length}',
              Icons.shopping_bag_outlined, AppColors.royalBlue),
          const SizedBox(width: 8),
          card(context.tr('market.stats_products'), '${products.length}',
              Icons.category_outlined, MarketColors.foreground),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Produits

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myVendorProductsProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myVendorProductsProvider);
          ref.invalidate(vendorOrdersProvider);
        },
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
                    onPressed: () =>
                        ref.invalidate(myVendorProductsProvider),
                    child: Text(context.tr('common.retry')),
                  ),
                ],
              ),
            ),
          ),
          data: (products) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const _StatsHeader(),
                if (products.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(context.tr('market.no_seller_products'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textMuted)),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final p in products)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _VendorProductCard(product: p),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vendeur/produit/nouveau'),
        icon: const Icon(Icons.add),
        label: Text(context.tr('market.add_product')),
        backgroundColor: MarketColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _VendorProductCard extends ConsumerWidget {
  const _VendorProductCard({required this.product});
  final Product product;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('market.confirm_delete_product')),
        content: Text(product.nomSafe),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('common.cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: Text(context.tr('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(deleteProductControllerProvider.notifier)
          .submit(product.id);
      messenger.showSnackBar(SnackBar(
          content: Text(
              context.mounted ? context.tr('market.product_deleted') : '')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = product.coverImage;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(MarketColors.radius),
        border: Border.all(color: MarketColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: MarketColors.muted,
                  borderRadius: BorderRadius.circular(10),
                  image: image != null
                      ? DecorationImage(
                          image: NetworkImage(image),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: image == null
                    ? const Icon(Icons.image_outlined,
                        color: MarketColors.mutedForeground)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.nomSafe,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      '${(product.prix ?? 0).toStringAsFixed(0)} XAF · '
                      '${context.tr('market.stock')} : ${product.stockQtte ?? 0}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                    if (product.categorie != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(product.categorie!.nom,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: MarketColors.border),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/produit/${product.id}'),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: Text(context.tr('common.view')),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/vendeur/produit/${product.id}/editer'),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(context.tr('common.edit')),
              ),
              TextButton.icon(
                onPressed: () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.error),
                label: Text(context.tr('common.delete'),
                    style: const TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Commandes

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vendorOrdersProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(vendorOrdersProvider),
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
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                const Icon(Icons.shopping_bag_outlined,
                    size: 64, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Center(
                  child: Text(context.tr('market.no_seller_orders'),
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
            itemBuilder: (_, i) => _SellerOrderCard(order: sorted[i]),
          );
        },
      ),
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  const _SellerOrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(MarketColors.radius),
        border: Border.all(color: MarketColors.border),
      ),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MarketColors.muted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(context.tr(order.status.i18nKey),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: MarketColors.foreground)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(order.dateCourt,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          for (final item in order.produits)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MarketColors.muted,
                      borderRadius: BorderRadius.circular(8),
                      image: item.produit.coverImage != null
                          ? DecorationImage(
                              image: NetworkImage(item.produit.coverImage!),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item.produit.nomSafe} × ${item.quantite}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text('${item.lineTotal.toStringAsFixed(0)} XAF',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const Divider(height: 16, color: MarketColors.border),
          Row(
            children: [
              if (order.villeLivraison != null ||
                  order.telLivraison != null)
                Expanded(
                  child: Text(
                    [order.villeLivraison, order.telLivraison]
                        .whereType<String>()
                        .join(' · '),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              Text(
                '${(order.total ?? 0).toStringAsFixed(0)} XAF',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: MarketColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Wallet

class _WalletTab extends ConsumerWidget {
  const _WalletTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vendorWalletProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(vendorWalletProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 100),
            Center(
                child: Text('$e',
                    style: const TextStyle(color: AppColors.textMuted))),
          ],
        ),
        data: (wallet) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Rappel de la commission plateforme (point 5, strategie 5,5 %)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MarketColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: MarketColors.accent.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: MarketColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(context.tr('fees.vendor_banner'),
                        style: const TextStyle(fontSize: 12, height: 1.4)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: MarketColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('wallet.balance'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text('${wallet.balance.toStringAsFixed(0)} XAF',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _openWithdraw(context, ref, wallet.balance),
                    icon: const Icon(Icons.arrow_upward),
                    label: Text(context.tr('wallet.withdraw')),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: MarketColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWithdraw(
      BuildContext context, WidgetRef ref, num balance) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VendorWithdrawSheet(currentBalance: balance),
    );
  }
}

class _VendorWithdrawSheet extends ConsumerStatefulWidget {
  const _VendorWithdrawSheet({required this.currentBalance});
  final num currentBalance;

  @override
  ConsumerState<_VendorWithdrawSheet> createState() =>
      _VendorWithdrawSheetState();
}

class _VendorWithdrawSheetState extends ConsumerState<_VendorWithdrawSheet> {
  String _method = 'OM';
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _busy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = num.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount < 500) {
      setState(() => _errorMessage = context.tr('wallet.withdraw_min'));
      return;
    }
    if (amount > widget.currentBalance) {
      setState(() => _errorMessage = context.tr('wallet.insufficient'));
      return;
    }
    if (!RegExp(r'^6\d{8}$').hasMatch(_phoneCtrl.text.trim())) {
      setState(() => _errorMessage = context.tr('mission.pay.invalid_phone'));
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(vendorDataSourceProvider).withdraw(
            amount: amount,
            phone: '237${_phoneCtrl.text.trim()}',
            method: _method,
          );
      ref.invalidate(vendorWalletProvider);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
          content: Text(context.tr('wallet.withdraw_requested'))));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('wallet.withdraw'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _payBtn('Orange Money', Colors.orange, 'OM')),
              const SizedBox(width: 8),
              Expanded(child: _payBtn('MTN MoMo', Colors.amber, 'MOMO')),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: context.tr('wallet.amount')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  labelText: context.tr('mission.pay.phone_hint'),
                  prefixText: '+237 '),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.error.withOpacity(0.35))),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: MarketColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(context.tr('wallet.confirm_withdraw')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payBtn(String label, Color color, String value) {
    final selected = _method == value;
    return InkWell(
      onTap: () => setState(() => _method = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
          color: selected ? color.withOpacity(0.08) : Colors.transparent,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? color : AppColors.textPrimary)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Profil

class _ShopProfileTab extends ConsumerStatefulWidget {
  const _ShopProfileTab();

  @override
  ConsumerState<_ShopProfileTab> createState() => _ShopProfileTabState();
}

class _ShopProfileTabState extends ConsumerState<_ShopProfileTab> {
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _paysCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contribuableCtrl = TextEditingController();
  bool _prefillDone = false;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [
      _nomCtrl, _descCtrl, _sloganCtrl, _adresseCtrl, _villeCtrl,
      _paysCtrl, _telCtrl, _emailCtrl, _contribuableCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill() {
    if (_prefillDone) return;
    final vendeur =
        ref.read(authControllerProvider).valueOrNull?.raw['vendeur'];
    if (vendeur is! Map) return;
    String s(String key) => (vendeur[key] ?? '').toString();
    _nomCtrl.text = s('nom');
    _descCtrl.text = s('description');
    _sloganCtrl.text = s('slogan');
    _adresseCtrl.text = s('adresse');
    _villeCtrl.text = s('ville');
    _paysCtrl.text = s('pays');
    _telCtrl.text = s('telephone');
    _emailCtrl.text = s('email');
    _contribuableCtrl.text = s('num_contribuable');
    _prefillDone = true;
  }

  Future<void> _save() async {
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(updateVendorProfileControllerProvider.notifier).submit(
            nom: _nomCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            slogan: _sloganCtrl.text.trim(),
            adresse: _adresseCtrl.text.trim(),
            ville: _villeCtrl.text.trim(),
            pays: _paysCtrl.text.trim(),
            telephone: _telCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            numContribuable: _contribuableCtrl.text.trim(),
          );
      final err = ref.read(updateVendorProfileControllerProvider).error;
      if (err != null) throw err;
      messenger.showSnackBar(SnackBar(
          content: Text(
              context.mounted ? context.tr('market.profile_updated') : ''),
          backgroundColor: MarketColors.primary));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _prefill();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tf(_nomCtrl, context.tr('market.shop_name')),
        _tf(_descCtrl, context.tr('market.shop_description'), maxLines: 3),
        _tf(_sloganCtrl, context.tr('market.shop_slogan')),
        _tf(_emailCtrl, context.tr('market.shop_email'),
            keyboardType: TextInputType.emailAddress),
        _tf(_telCtrl, context.tr('market.phone'),
            keyboardType: TextInputType.phone),
        _tf(_adresseCtrl, context.tr('market.address')),
        Row(
          children: [
            Expanded(child: _tf(_villeCtrl, context.tr('market.city'))),
            const SizedBox(width: 12),
            Expanded(child: _tf(_paysCtrl, context.tr('market.country'))),
          ],
        ),
        _tf(_contribuableCtrl, context.tr('market.tax_number')),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitting ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: MarketColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(context.tr('market.save_profile')),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _tf(TextEditingController c, String label,
      {int? maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: (maxLines ?? 1) > 1,
        ),
      ),
    );
  }
}
