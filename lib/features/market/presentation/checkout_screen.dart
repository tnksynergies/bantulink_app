import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../application/market_providers.dart';
import 'market_colors.dart';
import 'sheets/order_payment_sheet.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adresseCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _paysCtrl = TextEditingController(text: 'Cameroun');
  final _telCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();
  int? _deliveryOptionId;
  int? _paymentModeId;
  bool _submitting = false;
  bool _prefillDone = false;

  @override
  void dispose() {
    _adresseCtrl.dispose();
    _villeCtrl.dispose();
    _paysCtrl.dispose();
    _telCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  void _prefill() {
    if (_prefillDone) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    if (user.telephone != null) _telCtrl.text = user.telephone!;
    _prefillDone = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deliveryOptionId == null) {
      _toast(context.tr('market.select_delivery'), error: true);
      return;
    }
    if (_paymentModeId == null) {
      _toast(context.tr('market.select_payment'), error: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final order = await ref.read(checkoutControllerProvider.notifier).submit(
            optionLivraisonId: _deliveryOptionId!,
            modePaiementId: _paymentModeId!,
            adresse: _adresseCtrl.text.trim(),
            ville: _villeCtrl.text.trim(),
            pays: _paysCtrl.text.trim(),
            telephone: _telCtrl.text.trim(),
            couponCode: _couponCtrl.text.trim().isEmpty
                ? null
                : _couponCtrl.text.trim(),
          );
      if (!mounted) return;
      // Sheet de paiement Mobile Money (payer maintenant / plus tard),
      // aligne sur le flow web (Moala + polling).
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => OrderPaymentSheet(
          order: order,
          initialPhone: _telCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      context.go('/mes-commandes');
    } catch (e) {
      _toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String m, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: error ? AppColors.error : null,
      ));
  }

  @override
  Widget build(BuildContext context) {
    _prefill();
    final total = ref.watch(cartTotalProvider);
    final asyncDelivery = ref.watch(deliveryOptionsProvider);
    final asyncPayment = ref.watch(paymentModesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('market.checkout_title'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Total panier
            // Bandeau total (gradient vert -> orange, charte web)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: MarketColors.heroGradient,
                borderRadius: BorderRadius.circular(MarketColors.radius),
              ),
              child: Row(
                children: [
                  Text(context.tr('market.total'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const Expanded(child: SizedBox()),
                  Text(
                    '${total.toStringAsFixed(0)} XAF',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(context.tr('market.delivery_info'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adresseCtrl,
              decoration:
                  InputDecoration(labelText: '${context.tr('market.address')} *'),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? context.tr('common.required')
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _villeCtrl,
                    decoration: InputDecoration(
                        labelText: '${context.tr('market.city')} *'),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? context.tr('common.required')
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _paysCtrl,
                    decoration: InputDecoration(
                        labelText: context.tr('market.country')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telCtrl,
              keyboardType: TextInputType.phone,
              decoration:
                  InputDecoration(labelText: '${context.tr('market.phone')} *'),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? context.tr('common.required')
                  : null,
            ),
            const SizedBox(height: 20),

            // Option de livraison
            Text(context.tr('market.delivery_option'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            asyncDelivery.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e',
                  style: const TextStyle(color: AppColors.error)),
              data: (options) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final o in options)
                    RadioListTile<int>(
                      value: o.id,
                      groupValue: _deliveryOptionId,
                      onChanged: (v) =>
                          setState(() => _deliveryOptionId = v),
                      title: Text(o.nom,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: o.description != null
                          ? Text(o.description!,
                              style: const TextStyle(fontSize: 12))
                          : null,
                      secondary: o.prix != null
                          ? Text('${o.prix!.toStringAsFixed(0)} XAF',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))
                          : null,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode de paiement
            Text(context.tr('market.payment_mode'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            asyncPayment.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e',
                  style: const TextStyle(color: AppColors.error)),
              data: (modes) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final m in modes)
                    RadioListTile<int>(
                      value: m.id,
                      groupValue: _paymentModeId,
                      onChanged: (v) => setState(() => _paymentModeId = v),
                      title:
                          Text(m.nom, style: const TextStyle(fontSize: 14)),
                      subtitle: m.description != null
                          ? Text(m.description!,
                              style: const TextStyle(fontSize: 12))
                          : null,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _couponCtrl,
              decoration:
                  InputDecoration(labelText: context.tr('market.coupon')),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitting ? null : _submit,
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
                  : Text(context.tr('market.place_order')),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
