import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/branding/brand.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/models/user_model.dart';
import '../../freelancers/application/freelancers_providers.dart';
import '../../market/application/vendor_providers.dart';
import '../../notifications/application/notifications_providers.dart';
import '../../recruiter/application/recruiter_providers.dart';
import '../../recruiter/data/recruiter_remote_data_source.dart';

class _Choice {
  const _Choice(this.id, this.icon, this.label, this.onTap);
  final String id;
  final IconData icon;
  final String label;
  final void Function(BuildContext) onTap;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _recruitLoading = false;
  bool _becomeProviderLoading = false;

  Future<void> _handleBecomeProvider(BuildContext context) async {
    if (_becomeProviderLoading) return;
    setState(() => _becomeProviderLoading = true);
    bool isFreelancer = false;
    try {
      final profile = await ref
          .read(freelancersDataSourceProvider)
          .myProfileOrNull();
      isFreelancer = profile != null;
    } catch (_) {}
    if (!mounted) return;
    setState(() => _becomeProviderLoading = false);
    context.push(isFreelancer ? '/prestataire/dashboard' : '/devenir-prestataire');
  }

  Future<void> _handleRecruit(BuildContext context, User? user) async {
    if (_recruitLoading) return;
    setState(() => _recruitLoading = true);

    bool isRecruiter;
    try {
      final id = user?.id;
      if (id == null) {
        isRecruiter = false;
      } else {
        // Source d'autorite : /user/{id}/roles. On ne se rabat PAS sur
        // hasRecruteurProfile car il retourne true a la presence d'un
        // enregistrement "professionnel" meme sans le role Recruteur.
        final roles =
            await ref.read(recruiterDataSourceProvider).getUserRoles(id);
        isRecruiter = RecruiterRemoteDataSource.isRecruiterRole(roles);
      }
    } catch (_) {
      // Uniquement si /user/{id}/roles echoue : repli prudent sur le cache.
      isRecruiter = user?.hasRecruteurProfile == true;
    }

    if (!mounted) return;
    setState(() => _recruitLoading = false);
    context.push(isRecruiter ? '/recruteur/dashboard' : '/recruteur/inscription');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final prenom = user?.displayFirstName ?? '';

    final choices = <_Choice>[
      _Choice('apply', Icons.person_search_outlined, context.tr('home.apply'),
          (c) => c.go('/emploi')),
      _Choice('recruit', Icons.badge_outlined, context.tr('home.recruit'),
          (c) => _handleRecruit(c, user)),
      _Choice('find_provider', Icons.handshake_outlined,
          context.tr('home.find_provider'),
          (c) => c.push('/prestataires')),
      _Choice('be_provider', Icons.design_services_outlined,
          context.tr('home.be_provider'),
          (c) => _handleBecomeProvider(c)),
      _Choice('buy', Icons.shopping_basket_outlined, context.tr('home.buy'),
          (c) => c.go('/boutique')),
      _Choice('sell', Icons.sell_outlined, context.tr('home.sell'), (c) {
        final isVendor = ref.read(isCurrentUserVendorProvider);
        c.push(isVendor ? '/vendeur/dashboard' : '/devenir-vendeur');
      }),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const BrandLogo(BrandWorld.link, height: 32),
        actions: const [_NotifBell()],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7EC), Color(0xFFEFF4FF)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (prenom.isNotEmpty)
                  Text('${context.tr('home.greeting')} $prenom',
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(context.tr('home.what_to_do'),
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy)),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    itemCount: choices.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (_, i) => _ChoiceCard(
                      choice: choices[i],
                      loading: (choices[i].id == 'recruit' && _recruitLoading) ||
                          (choices[i].id == 'be_provider' && _becomeProviderLoading),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotifBell extends ConsumerWidget {
  const _NotifBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.navy),
            onPressed: () => context.push('/notifications'),
          ),
          if (unread > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(
                    color: AppColors.brandRed, shape: BoxShape.circle),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.choice, this.loading = false});
  final _Choice choice;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: loading ? null : () => choice.onTap(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.primary),
                      )
                    : Icon(choice.icon, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(choice.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy)),
            ],
          ),
        ),
      ),
    );
  }
}
