import 'package:flutter/material.dart';
import 'app_strings.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      AppLocalizations(const Locale('fr'));

  String t(String key) {
    final lang = kStrings.containsKey(locale.languageCode)
        ? locale.languageCode
        : 'fr';
    return kStrings[lang]?[key] ?? kStrings['fr']?[key] ?? key;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['fr', 'en'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Utilisation : context.tr('auth.login')
extension AppLocalizationsX on BuildContext {
  String tr(String key) => AppLocalizations.of(this).t(key);
}
