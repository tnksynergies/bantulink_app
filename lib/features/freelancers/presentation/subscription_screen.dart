import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/theme/app_colors.dart';

/// Ecran d'abonnement freelancer. L'appel /paiements/initiate-payment
/// est encapsule ici via un sheet type mission_payment_sheet.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('subscription.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(context.tr('subscription.no_active'),
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(context.tr('subscription.choose_plan'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _PlanCard(
            label: context.tr('subscription.monthly'),
            price: 2000,
            period: 'mois',
            popular: false,
            features: [
              context.tr('subscription.feature_visibility'),
              context.tr('subscription.feature_unlimited'),
            ],
            onSubscribe: () => _initiate(2000, 'monthly'),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            label: context.tr('subscription.annual'),
            price: 10000,
            period: 'an',
            popular: true,
            features: [
              context.tr('subscription.feature_visibility'),
              context.tr('subscription.feature_badge'),
              context.tr('subscription.feature_priority'),
              context.tr('subscription.feature_unlimited'),
            ],
            onSubscribe: () => _initiate(10000, 'annual'),
          ),
        ],
      ),
    );
  }

  Future<void> _initiate(num amount, String period) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubscribeSheet(amount: amount, period: period),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.label,
    required this.price,
    required this.period,
    required this.popular,
    required this.features,
    required this.onSubscribe,
  });
  final String label;
  final num price;
  final String period;
  final bool popular;
  final List<String> features;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: popular ? AppColors.royalBlue : AppColors.border,
            width: popular ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (popular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.royalBlue,
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(context.tr('subscription.popular'),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${price.toStringAsFixed(0)} XAF',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text('/ $period', style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: popular ? AppColors.royalBlue : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(context.tr('subscription.subscribe')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscribeSheet extends ConsumerStatefulWidget {
  const _SubscribeSheet({required this.amount, required this.period});
  final num amount;
  final String period;

  @override
  ConsumerState<_SubscribeSheet> createState() => _SubscribeSheetState();
}

class _SubscribeSheetState extends ConsumerState<_SubscribeSheet> {
  String _provider = 'OM';
  final _phoneCtrl = TextEditingController();
  bool _busy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.amount.toStringAsFixed(0)} XAF · ${widget.period}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _PayBtn(
                      label: 'Orange Money',
                      color: Colors.orange,
                      selected: _provider == 'OM',
                      onTap: () => setState(() => _provider = 'OM'))),
              const SizedBox(width: 8),
              Expanded(
                  child: _PayBtn(
                      label: 'MTN MoMo',
                      color: Colors.amber,
                      selected: _provider == 'MOMO',
                      onTap: () => setState(() => _provider = 'MOMO'))),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  labelText: context.tr('mission.pay.phone_hint'), prefixText: '+237 '),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(context.tr('mission.pay.confirm')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!RegExp(r'^6\d{8}$').hasMatch(_phoneCtrl.text.trim())) {
      setState(() => _errorMessage = context.tr('mission.pay.invalid_phone'));
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    // Capture le messenger AVANT le pop pour que la SnackBar de succes
    // s'affiche bien sur le Scaffold parent.
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/paiements/initiate-payment', data: {
        'amount': widget.amount,
        'phone': '237${_phoneCtrl.text.trim()}',
        'plan': widget.period,
        'period': widget.period,
        'provider': _provider,
        'type': 'freelancer',
      });
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('mission.pay.validation_required'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _PayBtn extends StatelessWidget {
  const _PayBtn(
      {required this.label,
      required this.color,
      required this.selected,
      required this.onTap});
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
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

