import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/localization/locale_preference_store.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations_ja.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations_vi.dart';

const supportedAppLocales = <Locale>[Locale('vi'), Locale('ja')];

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  return appLocalizationsFor(ref.watch(localeControllerProvider));
});

class LocaleController extends Notifier<Locale> {
  bool _hasUserSelectedLocale = false;
  bool _restoreStarted = false;

  @override
  Locale build() {
    final initialLocale = resolveSupportedLocale(
      PlatformDispatcher.instance.locale,
    );
    if (!_restoreStarted) {
      _restoreStarted = true;
      unawaited(restoreSavedLocale());
    }
    return initialLocale;
  }

  Future<void> restoreSavedLocale() async {
    String? savedCode;
    try {
      savedCode = await ref
          .read(localePreferenceStoreProvider)
          .readLanguageCode();
    } catch (_) {
      return;
    }
    if (_hasUserSelectedLocale || savedCode == null) return;
    final savedLocale = localeFromLanguageCode(savedCode);
    if (savedLocale != null) state = savedLocale;
  }

  Future<void> changeLocale(Locale locale) async {
    final supportedLocale = localeFromLanguageCode(locale.languageCode);
    if (supportedLocale == null) return;

    _hasUserSelectedLocale = true;
    state = supportedLocale;
    try {
      await ref
          .read(localePreferenceStoreProvider)
          .writeLanguageCode(supportedLocale.languageCode);
    } catch (_) {
      // The in-memory locale still changes if preference storage is unavailable.
    }
  }
}

Locale resolveSupportedLocale(Locale deviceLocale) {
  return deviceLocale.languageCode == 'ja'
      ? const Locale('ja')
      : const Locale('vi');
}

Locale? localeFromLanguageCode(String languageCode) {
  return switch (languageCode) {
    'vi' => const Locale('vi'),
    'ja' => const Locale('ja'),
    _ => null,
  };
}

AppLocalizations appLocalizationsFor(Locale locale) {
  return locale.languageCode == 'ja'
      ? AppLocalizationsJa()
      : AppLocalizationsVi();
}
