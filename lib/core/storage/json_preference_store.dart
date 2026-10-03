import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final jsonPreferenceStoreProvider = Provider<JsonPreferenceStore>((ref) {
  return SharedPreferencesJsonPreferenceStore(SharedPreferencesAsync());
});

enum LocalPersistenceStatus { available, unavailable }

abstract interface class JsonPreferenceStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}

class SharedPreferencesJsonPreferenceStore implements JsonPreferenceStore {
  SharedPreferencesJsonPreferenceStore(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}
