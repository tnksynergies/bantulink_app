import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/services/invoice_pdf.dart';
import '../../../core/subscriptions/subscriptions_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/media_url.dart';
import '../../auth/application/auth_controller.dart';
import '../../freelancers/presentation/subscription_screen.dart'
    show SubscribeSheet;

/// Abonnement recruteur — PLAN TARIFAIRE BANTUHIRE :
///   A. Plan Gratuit : 2 mois d'essai apres la creation du profil pro.
///   B. Plan Pro Recruteur : 50 000 XAF/an (offres illimitees, matching,
///      dashboard, profils candidats, badge verifie).
///   C. Plan Entreprise / Institution : sur devis.
class RecruiterSubscriptionScreen extends ConsumerWidget {
  const RecruiterSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(recruiterAccessProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('rsub.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.tr('rsub.subtitle'),
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textMuted)),
          const SizedBox(height: 16),

          // ---- Statut courant ----
          if (access.hasPro && access.subscription != null) ...[
            _statusBanner(
              color: AppColors.success,
              icon: Icons.verified,
              text:
                  '${context.tr('sub.current_plan')} : ${context.tr('rsub.pro_plan')} — '
                  '${context.tr('sub.active_until')} ${access.subscription!.endDateCourt}',
            ),
            const SizedBox(height: 8),
            // Facture d'abonnement : logo BantuHire + logo de l'entreprise.
            OutlinedButton.icon(
              onPressed: () =>
                  _printInvoice(context, ref, access.subscription!),
              icon: const Icon(Icons.print_outlined,
                  size: 18, color: AppColors.royalBlue),
              label: Text(context.tr('invoice.download'),
                  style: const TextStyle(color: AppColors.royalBlue)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.royalBlue),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ]
          else if (access.inTrial)
            _statusBanner(
              color: AppColors.royalBlue,
              icon: Icons.timer_outlined,
              text: access.trialDaysLeft != null
                  ? context
                      .tr('rsub.trial_left')
                      .replaceAll('{days}', '${access.trialDaysLeft}')
                  : context.tr('rsub.free_desc'),
            )
          else
            _statusBanner(
              color: AppColors.error,
              icon: Icons.lock_clock,
              text: context.tr('rsub.trial_over'),
            ),
          const SizedBox(height: 12),

          // ---- A. Plan Gratuit ----
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
                Text(context.tr('rsub.free_plan'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(context.tr('rsub.free_desc'),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- B. Plan Pro Recruteur ----
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.royalBlue, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(context.tr('rsub.pro_plan'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
                Text(context.tr('rsub.pro_tagline'),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '50 000 XAF',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      TextSpan(
                        text: ' ${context.tr('rsub.per_year')}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _b(context.tr('rsub.pro_b1')),
                _b(context.tr('rsub.pro_b2')),
                _b(context.tr('rsub.pro_b3')),
                _b(context.tr('rsub.pro_b4')),
                _b(context.tr('rsub.pro_b5')),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: access.hasPro
                        ? null
                        : () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const SubscribeSheet(
                                  amount: 50000,
                                  period: 'yearly',
                                  type: 'recruteur',
                                  plan: 'pro'),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(access.hasPro
                        ? context.tr('fsub.active_badge')
                        : context.tr('csub.subscribe')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- C. Plan Entreprise / Institution ----
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
                Text(context.tr('rsub.enterprise_plan'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(context.tr('rsub.enterprise_desc'),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                            title:
                                Text(context.tr('rsub.enterprise_plan'))),
                        body: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.mail_outline,
                                    size: 48, color: AppColors.royalBlue),
                                const SizedBox(height: 12),
                                Text(context.tr('rsub.enterprise_desc'),
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                const SelectableText(
                                    'contact@bantulink.tech',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )),
                    icon: const Icon(Icons.mail_outline, size: 18),
                    label: Text(context.tr('rsub.contact_us')),
                  ),
                ),
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

  Future<void> _printInvoice(
      BuildContext context, WidgetRef ref, ActiveSubscription sub) async {
    final labels = invoiceLabels(context);
    final planLabel = context.tr('rsub.pro_plan');
    final periodLabel = context.tr('subscription.annual');
    final messenger = ScaffoldMessenger.of(context);
    final pro = ref.read(authControllerProvider).valueOrNull?.professionnelRaw;
    try {
      final brand = await InvoiceBrand.recruiter(
        companyName: pro?['nom_entreprise']?.toString(),
        companyLogoUrl: mediaUrl(pro?['logo']?.toString()),
      );
      await InvoicePdf.printSubscription(
        brand: brand,
        planLabel: planLabel,
        amount: 50000,
        periodLabel: periodLabel,
        activeUntil: sub.endDateCourt,
        date: DateTime.now().toIso8601String().substring(0, 10),
        tr: (k) => labels[k] ?? k,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Widget _statusBanner(
      {required Color color, required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
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
