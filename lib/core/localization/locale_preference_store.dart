import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localePreferenceStoreProvider = Provider<LocalePreferenceStore>((ref) {
  return SharedPreferencesLocalePreferenceStore(SharedPreferencesAsync());
});

abstract interface class LocalePreferenceStore {
  Future<String?> readLanguageCode();

  Future<void> writeLanguageCode(String languageCode);
}

class SharedPreferencesLocalePreferenceStore implements LocalePreferenceStore {
  SharedPreferencesLocalePreferenceStore(this._preferences);

  static const _languageCodeKey = 'preferred_language_code';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readLanguageCode() {
    return _preferences.getString(_languageCodeKey);
  }

  @override
  Future<void> writeLanguageCode(String languageCode) {
    return _preferences.setString(_languageCodeKey, languageCode);
  }
}
