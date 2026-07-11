import 'package:flutter/material.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/pricing/bantulink_fees.dart';
import '../../../core/theme/app_colors.dart';
import 'market_colors.dart';

/// Plan tarifaire vendeur (point 4c) — aligne sur la Strategie de
/// Tarification de lancement : commission forfaitaire 5,5 % tout compris.
class VendorPricingScreen extends StatelessWidget {
  const VendorPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const exampleSale = 100000;
    final fee = BantulinkFees.marketFeeFor(exampleSale);
    final net = BantulinkFees.marketNetFor(exampleSale);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('fees.vendor_pricing_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero 5,5 %
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: MarketColors.heroGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${BantulinkFees.marketCommissionPercent.toStringAsFixed(1).replaceAll('.', ',')} %',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(context.tr('fees.vendor_pricing_headline'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(context.tr('fees.vendor_pricing_body'),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Aucun frais cache
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MarketColors.muted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MarketColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined,
                    color: MarketColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(context.tr('fees.no_hidden'),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Exemple chiffre
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MarketColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('fees.example'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _row(context.tr('fees.sale_of'), '100 000 XAF'),
                _row(
                    '${context.tr('fees.commission')} (5,5 %)',
                    '- ${fee.toStringAsFixed(0)} XAF',
                    color: AppColors.error),
                const Divider(height: 18),
                _row(context.tr('fees.net_received'),
                    '${net.toStringAsFixed(0)} XAF',
                    bold: true, color: MarketColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Avantages wallet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MarketColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('fees.wallet_title'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _benefit(context.tr('fees.wallet_b1')),
                _benefit(context.tr('fees.wallet_b2')),
                _benefit(context.tr('fees.wallet_b3')),
                _benefit(context.tr('fees.wallet_b4')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(context.tr('fees.launch_pricing'),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                      color: AppColors.textPrimary))),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 16 : 13,
                  fontWeight: FontWeight.bold,
                  color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: MarketColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
