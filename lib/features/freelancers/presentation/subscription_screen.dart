import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/pricing/bantulink_fees.dart';
import '../../../core/subscriptions/subscriptions_providers.dart';
import '../../../core/theme/app_colors.dart';

/// Abonnement freelance (point 4a) : DEUX formules au choix, avec les MEMES
/// services sur tous les plans.
///  1. Commission par projet (defaut, sans engagement) : paliers 10 / 8,5 /
///     6,75 / 5,5 % preleves uniquement sur les missions payees en ligne.
///  2. Abonnement (mensuel ou annuel) : forfait fixe.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  /// 0 = commission par projet, 1 = abonnement.
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    final activeSub = ref.watch(freelanceSubscriptionProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('subscription.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Regle du plan tarifaire : 1re prestation gratuite, ensuite
          // choix obligatoire d'une formule.
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.royalBlue.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.card_giftcard,
                    color: AppColors.royalBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(context.tr('fsub.first_free'),
                      style: const TextStyle(fontSize: 12.5, height: 1.35)),
                ),
              ],
            ),
          ),
          // Formule active (abonnement en cours, sinon commission par defaut)
          if (activeSub != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${context.tr('fsub.active_badge')} — '
                      '${context.tr('sub.active_until')} ${activeSub.endDateCourt}',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // ---- Selecteur de formule ----
          Text(context.tr('fsub.mode_title'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ModeCard(
                  selected: _mode == 0,
                  icon: Icons.percent,
                  title: context.tr('fsub.mode_commission'),
                  subtitle: context.tr('fsub.no_commitment'),
                  onTap: () => setState(() => _mode = 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeCard(
                  selected: _mode == 1,
                  icon: Icons.workspace_premium_outlined,
                  title: context.tr('fsub.mode_subscription'),
                  subtitle: context.tr('subscription.monthly') +
                      ' / ' +
                      context.tr('subscription.annual'),
                  onTap: () => setState(() => _mode = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ---- Services identiques sur tous les plans ----
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_outlined,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(context.tr('fsub.same_services'),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _svc(context.tr('fsub.svc_visibility')),
                _svc(context.tr('fsub.svc_unlimited')),
                _svc(context.tr('fsub.svc_profile')),
                _svc(context.tr('fsub.svc_badge')),
                _svc(context.tr('fsub.svc_support')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Contenu de la formule choisie ----
          if (_mode == 0)
            const _CommissionMode()
          else
            const _SubscriptionMode(),
          const SizedBox(height: 12),
          Text(context.tr('fees.launch_pricing'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _svc(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 15, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// Formule 1 : commission par paliers, sans abonnement.
class _CommissionMode extends StatelessWidget {
  const _CommissionMode();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('fsub.mode_commission'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(context.tr('fsub.mode_commission_desc'),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted, height: 1.4)),
          const SizedBox(height: 14),
          Text(context.tr('fees.freelance_tiers_title'),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          // Tableau des paliers (strategie de lancement)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(9)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(context.tr('fees.project_value'),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700))),
                      Text(context.tr('fees.rate'),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                for (final t in BantulinkFees.freelanceTiers)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(t.rangeLabel(),
                                style: const TextStyle(fontSize: 13))),
                        Text(
                          '${t.percent.toStringAsFixed(2).replaceAll('.', ',')} %',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Formule 2 : abonnement mensuel / annuel (plans existants).
class _SubscriptionMode extends ConsumerStatefulWidget {
  const _SubscriptionMode();

  @override
  ConsumerState<_SubscriptionMode> createState() => _SubscriptionModeState();
}

class _SubscriptionModeState extends ConsumerState<_SubscriptionMode> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr('fsub.mode_subscription_desc'),
            style: const TextStyle(
                fontSize: 13, color: AppColors.textMuted, height: 1.4)),
        const SizedBox(height: 12),
        _PlanCard(
          label: context.tr('subscription.monthly'),
          price: 2000,
          period: 'monthly',
          popular: false,
          onSubscribe: () => _initiate(2000, 'monthly'),
        ),
        const SizedBox(height: 12),
        _PlanCard(
          label: context.tr('subscription.annual'),
          price: 10000,
          period: 'annual',
          popular: true,
          onSubscribe: () => _initiate(10000, 'annual'),
        ),
      ],
    );
  }

  Future<void> _initiate(num amount, String period) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscribeSheet(
          amount: amount,
          period: period,
          type: 'freelancer',
          plan: 'freelancer'),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.label,
    required this.price,
    required this.period,
    required this.popular,
    required this.onSubscribe,
  });
  final String label;
  final num price;
  final String period;
  final bool popular;
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (popular)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.royalBlue,
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(context.tr('subscription.popular'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${price.toStringAsFixed(0)} XAF',
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    popular ? AppColors.royalBlue : AppColors.primary,
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

/// Sheet de paiement d'abonnement mutualise entre les differents profils.
class SubscribeSheet extends ConsumerStatefulWidget {
  const SubscribeSheet({
    super.key,
    required this.amount,
    required this.period,
    required this.type,
    required this.plan,
  });
  final num amount;
  final String period; // monthly | quarterly | yearly | annual
  final String type; // freelancer | candidat | recruteur | seller
  final String plan; // Identifiant du forfait pour le profil demande

  @override
  ConsumerState<SubscribeSheet> createState() => _SubscribeSheetState();
}

class _SubscribeSheetState extends ConsumerState<SubscribeSheet> {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${widget.amount.toStringAsFixed(0)} XAF · ${widget.period}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _payBtn('Orange Money', Colors.orange, 'OM')),
              const SizedBox(width: 8),
              Expanded(child: _payBtn('MTN MoMo', Colors.amber, 'MOMO')),
            ]),
            const SizedBox(height: 16),
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
                backgroundColor: AppColors.royalBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(context.tr('mission.pay.confirm')),
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/paiements/initiate-payment', data: {
        'amount': widget.amount,
        'phone': '237${_phoneCtrl.text.trim()}',
        'plan': widget.plan,
        'period': widget.period,
        'provider': _provider,
        'type': widget.type,
      });
      // Le statut d'abonnement changera apres validation Mobile Money :
      // on invalide pour que le prochain focus recharge l'etat.
      ref.invalidate(activeSubscriptionsProvider);
      if (!mounted) return;
      final validationMsg = context.tr('mission.pay.validation_required');
      final ussdHint = context.tr('pay.ussd_hint');
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text('$validationMsg\n$ussdHint'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _paymentErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _paymentErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          return errors.entries.map((entry) {
            final messages = entry.value;
            final details =
                messages is List ? messages.join(', ') : messages.toString();
            return '${entry.key}: $details';
          }).join('\n');
        }
        final message = data['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }
      if (data is String && data.isNotEmpty) return data;
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    return error.toString();
  }

  Widget _payBtn(String label, Color color, String value) {
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

/// ============================================================
/// Abonnement Candidat — PLAN TARIFAIRE BANTUHIRE :
/// Basic gratuit / Standard 2 950 XAF/trimestre ou 8 850 XAF/an.
/// ============================================================
class CandidateSubscriptionScreen extends ConsumerStatefulWidget {
  const CandidateSubscriptionScreen({super.key});

  @override
  ConsumerState<CandidateSubscriptionScreen> createState() =>
      _CandidateSubscriptionScreenState();
}

class _CandidateSubscriptionScreenState
    extends ConsumerState<CandidateSubscriptionScreen> {
  /// true = trimestriel (2 950), false = annuel (8 850).
  bool _quarterly = true;

  @override
  Widget build(BuildContext context) {
    final activeSub = ref.watch(candidateSubscriptionProvider);
    final price = _quarterly ? 2950 : 8850;
    final periodLabel =
        _quarterly ? context.tr('csub.quarter') : context.tr('csub.year');

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('csub.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.tr('csub.subtitle'),
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          const SizedBox(height: 16),

          // Abonnement Standard deja actif
          if (activeSub != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${context.tr('sub.current_plan')} : ${context.tr('csub.premium_plan')} — '
                      '${context.tr('sub.active_until')} ${activeSub.endDateCourt}',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ---- Plan Basic (gratuit) ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('csub.free_plan'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(context.tr('csub.free_desc'),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                _b(context.tr('csub.free_b1')),
                _b(context.tr('csub.free_b2')),
                _b(context.tr('csub.free_b3')),
                _b(context.tr('csub.free_b4')),
                _b(context.tr('csub.free_b5')),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Plan Standard ----
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(context.tr('csub.premium_plan'),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(context.tr('subscription.popular'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(context.tr('csub.premium_tagline'),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 12),

                // Choix de la periode : trimestre / an
                Row(
                  children: [
                    Expanded(
                      child: _PeriodChip(
                        label: '2 950 XAF / ${context.tr('csub.quarter')}',
                        selected: _quarterly,
                        onTap: () => setState(() => _quarterly = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PeriodChip(
                        label: '8 850 XAF / ${context.tr('csub.year')}',
                        selected: !_quarterly,
                        onTap: () => setState(() => _quarterly = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} XAF',
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      TextSpan(
                        text: ' / $periodLabel',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _b(context.tr('csub.b1')),
                _b(context.tr('csub.b2')),
                _b(context.tr('csub.b3')),
                _b(context.tr('csub.b4')),
                _b(context.tr('csub.b5')),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => SubscribeSheet(
                          amount: price,
                          period: _quarterly ? 'quarterly' : 'yearly',
                          type: 'candidat',
                          plan: 'standard'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(context.tr('csub.subscribe')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(context.tr('fees.launch_pricing'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _b(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1),
        ),
        child: Center(
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textPrimary)),
        ),
      ),
    );
  }
}
