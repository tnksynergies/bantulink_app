import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';

/// Passe a true une fois l'animation de demarrage terminee.
/// (Volontairement NON autoDispose : l'etat doit persister tant que l'app vit,
/// pour ne jamais re-afficher le splash apres connexion.)
final splashAnimationDoneProvider = StateProvider<bool>((_) => false);

/// Duree totale du splash anime.
const Duration kSplashDuration = Duration(milliseconds: 3500);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logo =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  late final AnimationController _text =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  Timer? _done;

  late final Animation<double> _logoFade =
      CurvedAnimation(parent: _logo, curve: Curves.easeOut);
  late final Animation<double> _logoScale =
      Tween<double>(begin: 0.72, end: 1.0).animate(
          CurvedAnimation(parent: _logo, curve: Curves.easeOutBack));
  late final Animation<double> _textFade =
      CurvedAnimation(parent: _text, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _logo.forward();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _text.forward();
    });
    _done = Timer(kSplashDuration, () {
      if (mounted) {
        ref.read(splashAnimationDoneProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    _done?.cancel();
    _logo.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brandGreen, AppColors.navy],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset('assets/logos/logobantulink.png',
                        height: 46, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FadeTransition(
                opacity: _textFade,
                child: Text(
                  context.tr('splash.tagline'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(flex: 4),
              FadeTransition(
                opacity: _textFade,
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
