import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/app/startup_providers.dart';

/// Passe a true quand l'onboarding vient d'etre termine (declenche la redirection).
/// La persistance reelle ("deja vu") est ecrite dans SharedPreferences.
final onboardingDoneProvider = StateProvider<bool>((_) => false);

/// Cle de persistance de l'onboarding.
const String kOnboardingSeenKey = 'onboarding_seen';

class _Slide {
  const _Slide(this.image, this.titleKey, this.textKey, this.accent);
  final String image;
  final String titleKey;
  final String textKey;
  final Color accent;
}

const List<_Slide> _slides = [
  _Slide('assets/onboarding/job.png', 'onboarding.s1_title', 'onboarding.s1_text',
      AppColors.brandGreen),
  _Slide('assets/onboarding/market.png', 'onboarding.s2_title', 'onboarding.s2_text',
      AppColors.brandRed),
  _Slide('assets/onboarding/com.png', 'onboarding.s3_title', 'onboarding.s3_text',
      AppColors.royalBlue),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      await ref.read(sharedPrefsProvider).setBool(kOnboardingSeenKey, true);
    } catch (_) {}
    ref.read(onboardingDoneProvider.notifier).state = true;
  }

  void _next() {
    if (_index >= _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(context.tr('onboarding.skip'),
                    style: const TextStyle(color: AppColors.textMuted)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast
                      ? context.tr('onboarding.start')
                      : context.tr('onboarding.next')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: slide.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Image.asset(slide.image,
                height: 240, fit: BoxFit.contain),
          ),
          const SizedBox(height: 40),
          Text(
            context.tr(slide.titleKey),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.navy),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(slide.textKey),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
