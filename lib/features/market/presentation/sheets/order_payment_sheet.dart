import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/market_providers.dart';
import '../../data/models/order.dart';
import '../market_colors.dart';

/// Sheet de paiement Mobile Money d'une commande (aligne sur la version web) :
/// choix payer maintenant / plus tard -> OM ou MoMo + telephone ->
/// initiation Moala -> attente validation USSD -> succes / echec.
class OrderPaymentSheet extends ConsumerStatefulWidget {
  const OrderPaymentSheet({
    super.key,
    required this.order,
    this.initialPhone,
  });

  final Order order;
  final String? initialPhone;

  @override
  ConsumerState<OrderPaymentSheet> createState() => _OrderPaymentSheetState();
}

enum _Step { choice, form, waiting, success, failed }

class _OrderPaymentSheetState extends ConsumerState<OrderPaymentSheet> {
  _Step _step = _Step.choice;
  String _provider = 'OM';
  late final TextEditingController _phoneCtrl;
  String? _errorMessage;

  num get _amount => widget.order.total ?? 0;

  @override
  void initState() {
    super.initState();
    // Pre-rempli avec le tel de livraison (format local 9 chiffres),
    // comme la version web.
    final raw = (widget.initialPhone ?? '')
        .replaceAll(RegExp(r'\D'), '')
        .replaceFirst(RegExp(r'^237'), '');
    _phoneCtrl = TextEditingController(
        text: raw.length >= 9 ? raw.substring(raw.length - 9) : raw);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final phone = _phoneCtrl.text.trim();
    if (!RegExp(r'^6\d{8}$').hasMatch(phone)) {
      setState(() => _errorMessage = context.tr('mission.pay.invalid_phone'));
      return;
    }
    setState(() {
      _errorMessage = null;
      _step = _Step.waiting;
    });
    await ref
        .read(payOrderControllerProvider(widget.order.id).notifier)
        .initiate(amount: _amount, phone: '237$phone', provider: _provider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(payOrderControllerProvider(widget.order.id), (prev, next) {
      if (next.hasError && _step == _Step.waiting) {
        setState(() {
          _step = _Step.form;
          _errorMessage = next.error.toString();
        });
        return;
      }
      final data = next.valueOrNull;
      if (data == null) return;
      if (data.stage == OrderPayStage.success && _step != _Step.success) {
        setState(() => _step = _Step.success);
      } else if (data.stage == OrderPayStage.failed && _step != _Step.failed) {
        setState(() => _step = _Step.failed);
      }
    });

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _buildStep(context),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case _Step.choice:
        return _choice(context);
      case _Step.form:
        return _form(context);
      case _Step.waiting:
        return _waiting(context);
      case _Step.success:
        return _done(context,
            icon: Icons.check_circle,
            color: MarketColors.primary,
            messageKey: 'market.payment_success');
      case _Step.failed:
        return _done(context,
            icon: Icons.cancel_outlined,
            color: AppColors.error,
            messageKey: 'market.payment_failed',
            retry: true);
    }
  }

  Widget _choice(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, color: MarketColors.primary, size: 52),
        const SizedBox(height: 10),
        Text(context.tr('market.order_success'),
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          '${context.tr('market.order_number')} ${widget.order.displayRef} · '
          '${_amount.toStringAsFixed(0)} XAF',
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => setState(() => _step = _Step.form),
          icon: const Icon(Icons.phone_android, size: 18),
          label: Text(context.tr('market.pay_now')),
          style: ElevatedButton.styleFrom(
            backgroundColor: MarketColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.tr('market.pay_later')),
        ),
      ],
    );
  }

  Widget _form(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr('market.payment_title'),
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          '${context.tr('market.total')} : ${_amount.toStringAsFixed(0)} XAF',
          style: const TextStyle(
              color: MarketColors.primary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _providerBtn('Orange Money', Colors.orange, 'OM')),
          const SizedBox(width: 8),
          Expanded(child: _providerBtn('MTN MoMo', Colors.amber, 'MOMO')),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
              labelText: context.tr('mission.pay.phone_hint'),
              prefixText: '+237 '),
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.35))),
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
          onPressed: _pay,
          style: ElevatedButton.styleFrom(
            backgroundColor: MarketColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(context.tr('mission.pay.confirm')),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.tr('market.pay_later')),
        ),
      ],
    );
  }

  Widget _waiting(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        const CircularProgressIndicator(color: MarketColors.primary),
        const SizedBox(height: 20),
        Text(context.tr('market.payment_initiated'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        // Orange Money n'envoie pas toujours le push USSD : indiquer la
        // procedure manuelle de validation.
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MarketColors.accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: MarketColors.accent.withOpacity(0.3)),
          ),
          child: Text(context.tr('pay.ussd_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.35)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _done(BuildContext context,
      {required IconData icon,
      required Color color,
      required String messageKey,
      bool retry = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, color: color, size: 56),
        const SizedBox(height: 14),
        Text(context.tr(messageKey),
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 20),
        if (retry)
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.tr('market.pay_later')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _step = _Step.form),
                style: ElevatedButton.styleFrom(
                    backgroundColor: MarketColors.primary,
                    foregroundColor: Colors.white),
                child: Text(context.tr('common.retry')),
              ),
            ),
          ])
        else
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: MarketColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12)),
            child: const Text('OK'),
          ),
      ],
    );
  }

  Widget _providerBtn(String label, Color color, String value) {
    final selected = _provider == value;
    return InkWell(
      onTap: () => setState(() => _provider = value),
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
