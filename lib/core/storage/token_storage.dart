import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final _secureKeyValueStoreProvider = Provider<SecureKeyValueStore>((ref) {
  return FlutterSecureKeyValueStore(ref.watch(secureStorageProvider));
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(_secureKeyValueStoreProvider));
});

abstract interface class SecureKeyValueStore {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String? value});

  Future<void> delete({required String key});
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String? value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

class TokenStorage {
  TokenStorage(this._storage);

  final SecureKeyValueStore _storage;
  String? _sessionAccessToken;
  int? _sessionUserId;

  static const _accessTokenKey = 'access_token';
  static const _userIdKey = 'authenticated_user_id';

  Future<String?> readAccessToken() async {
    final sessionToken = _sessionAccessToken;
    if (sessionToken != null) return sessionToken;
    return _storage.read(key: _accessTokenKey);
  }

  Future<int?> readAuthenticatedUserId() async {
    final sessionUserId = _sessionUserId;
    if (sessionUserId != null) return sessionUserId;

    final storedUserId = await _storage.read(key: _userIdKey);
    return storedUserId == null ? null : int.tryParse(storedUserId);
  }

  Future<void> saveAccessToken(
    String accessToken, {
    bool persist = true,
  }) async {
    if (persist) {
      await _storage.write(key: _accessTokenKey, value: accessToken);
    } else {
      await _storage.delete(key: _accessTokenKey);
    }
    _sessionAccessToken = accessToken;
  }

  Future<void> saveAuthenticatedSession({
    required String accessToken,
    required int userId,
    bool persist = true,
  }) async {
    await saveAccessToken(accessToken, persist: persist);
    if (persist) {
      await _storage.write(key: _userIdKey, value: userId.toString());
    } else {
      await _storage.delete(key: _userIdKey);
    }
    _sessionUserId = userId;
  }

  Future<void> clear() async {
    _sessionAccessToken = null;
    _sessionUserId = null;
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _userIdKey),
    ]);
  }
}
