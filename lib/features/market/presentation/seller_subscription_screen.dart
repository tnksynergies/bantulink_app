import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../freelancers/presentation/subscription_screen.dart'
    show SubscribeSheet;
import 'market_colors.dart';

class SellerSubscriptionScreen extends ConsumerStatefulWidget {
  const SellerSubscriptionScreen({super.key});

  @override
  ConsumerState<SellerSubscriptionScreen> createState() =>
      _SellerSubscriptionScreenState();
}

class _SellerSubscriptionScreenState
    extends ConsumerState<SellerSubscriptionScreen> {
  String _shopPeriod = 'monthly';
  String _visibilityPeriod = '3days';

  static const _shopPrices = {
    'monthly': 2000,
    'quarterly': 5000,
    'annual': 19250,
  };

  static const _visibilityPlans = [
    _VisibilityPlan(
        id: 'starter', prices: {'3days': 500, 'weekly': 1000, 'monthly': 3750}),
    _VisibilityPlan(
        id: 'pro', prices: {'3days': 1000, 'weekly': 2000, 'monthly': 7750}),
    _VisibilityPlan(
        id: 'business',
        prices: {'3days': 2000, 'weekly': 4000, 'monthly': 15500}),
  ];

  static const _shopFeatures = [
    'seller_sub.feature.catalog',
    'seller_sub.feature.cart',
    'seller_sub.feature.orders',
    'seller_sub.feature.customer_space',
    'seller_sub.feature.marketing',
    'seller_sub.feature.support',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('seller_sub.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.tr('seller_sub.subtitle'),
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textMuted, height: 1.4)),
          const SizedBox(height: 18),
          _sectionTitle(context.tr('seller_sub.shop_plan')),
          const SizedBox(height: 10),
          _shopCard(context),
          const SizedBox(height: 28),
          _sectionTitle(context.tr('seller_sub.visibility_title')),
          const SizedBox(height: 4),
          Text(context.tr('seller_sub.visibility_subtitle'),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted, height: 1.4)),
          const SizedBox(height: 12),
          _periodSelector(
            context,
            selected: _visibilityPeriod,
            periods: const ['3days', 'weekly', 'monthly'],
            onChanged: (period) => setState(() => _visibilityPeriod = period),
          ),
          const SizedBox(height: 12),
          for (final plan in _visibilityPlans) ...[
            _visibilityCard(context, plan),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      );

  Widget _shopCard(BuildContext context) {
    final amount = _shopPrices[_shopPeriod]!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MarketColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined,
                  color: MarketColors.primary, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(context.tr('seller_sub.shop_plan'),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              Text(context.tr('subscription.popular'),
                  style: const TextStyle(
                      color: MarketColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(context.tr('seller_sub.shop_desc'),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted, height: 1.4)),
          const SizedBox(height: 14),
          Text(context.tr('seller_sub.shop_features_title'),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          ..._shopFeatures.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: MarketColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr(feature),
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          _periodSelector(
            context,
            selected: _shopPeriod,
            periods: const ['monthly', 'quarterly', 'annual'],
            onChanged: (period) => setState(() => _shopPeriod = period),
          ),
          const SizedBox(height: 14),
          _price(amount, context.tr('seller_sub.period.$_shopPeriod')),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _subscribe(
                context,
                amount: amount,
                period: _shopPeriod,
                plan: 'shop',
              ),
              icon: const Icon(Icons.credit_card),
              label: Text(context.tr('seller_sub.subscribe')),
              style: ElevatedButton.styleFrom(
                backgroundColor: MarketColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visibilityCard(BuildContext context, _VisibilityPlan plan) {
    final amount = plan.prices[_visibilityPeriod]!;
    final color =
        plan.id == 'business' ? AppColors.royalBlue : MarketColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_planIcon(plan.id), color: color, size: 23),
              const SizedBox(width: 9),
              Expanded(
                child: Text(context.tr('seller_sub.plan.${plan.id}'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              _price(
                  amount, context.tr('seller_sub.period.$_visibilityPeriod')),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _subscribe(
                context,
                amount: amount,
                period: _visibilityPeriod,
                plan: plan.id,
              ),
              icon: const Icon(Icons.bolt),
              label: Text(context.tr('seller_sub.boost')),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _price(int amount, String period) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  '${NumberFormat.decimalPattern('fr_FR').format(amount)} XAF',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            TextSpan(
              text: ' / $period',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        textAlign: TextAlign.end,
      );

  Widget _periodSelector(
    BuildContext context, {
    required String selected,
    required List<String> periods,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final period in periods)
          ChoiceChip(
            label: Text(context.tr('seller_sub.period.$period')),
            selected: selected == period,
            onSelected: (_) => onChanged(period),
            selectedColor: MarketColors.primary,
            labelStyle: TextStyle(
              color: selected == period ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  IconData _planIcon(String id) => switch (id) {
        'starter' => Icons.rocket_launch_outlined,
        'pro' => Icons.query_stats,
        _ => Icons.workspace_premium_outlined,
      };

  void _subscribe(
    BuildContext context, {
    required int amount,
    required String period,
    required String plan,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscribeSheet(
        amount: amount,
        period: period,
        type: 'vendeur',
        plan: plan,
      ),
    );
  }
}

class _VisibilityPlan {
  const _VisibilityPlan({required this.id, required this.prices});

  final String id;
  final Map<String, int> prices;
}
