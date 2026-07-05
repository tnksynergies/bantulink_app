import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/startup_providers.dart';

class LocaleController extends Notifier<Locale> {
  static const _key = 'app_locale';

  @override
  Locale build() {
    try {
      final code = ref.read(sharedPrefsProvider).getString(_key);
      if (code == 'en' || code == 'fr') return Locale(code!);
    } catch (_) {}
    return const Locale('fr');
  }

  void set(String code) {
    if (code != 'fr' && code != 'en') return;
    try {
      ref.read(sharedPrefsProvider).setString(_key, code);
    } catch (_) {}
    state = Locale(code);
  }

  void toggle() => set(state.languageCode == 'fr' ? 'en' : 'fr');
}

final localeProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);
