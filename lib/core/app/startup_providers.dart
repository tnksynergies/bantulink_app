import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injecte SharedPreferences (override dans main()).
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPrefsProvider doit etre override dans main()');
});

/// Vrai quand l'animation du splash est terminee (en memoire -> rejoue a chaque lancement).
final splashCompletedProvider = StateProvider<bool>((ref) => false);

/// Onboarding deja vu ? Persiste au premier passage.
class OnboardingController extends Notifier<bool> {
  static const _key = 'onboarding_seen';

  @override
  bool build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(_key, true);
    state = true;
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
