import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';

void main() {
  test('remembered access token is written to secure storage', () async {
    final secureStore = _MemorySecureKeyValueStore();
    final tokenStorage = TokenStorage(secureStore);

    await tokenStorage.saveAccessToken('remembered-token');

    expect(secureStore.values['access_token'], 'remembered-token');
    expect(await tokenStorage.readAccessToken(), 'remembered-token');
  });

  test('session-only token removes an older persisted token', () async {
    final secureStore = _MemorySecureKeyValueStore()
      ..values['access_token'] = 'old-token';
    final tokenStorage = TokenStorage(secureStore);

    await tokenStorage.saveAccessToken('session-token', persist: false);

    expect(secureStore.values.containsKey('access_token'), isFalse);
    expect(await tokenStorage.readAccessToken(), 'session-token');
  });

  test('clearing tokens removes memory and secure values', () async {
    final secureStore = _MemorySecureKeyValueStore();
    final tokenStorage = TokenStorage(secureStore);
    await tokenStorage.saveAccessToken('access-token');

    await tokenStorage.clear();

    expect(await tokenStorage.readAccessToken(), isNull);
    expect(secureStore.values, isEmpty);
  });

  test(
    'authenticated identity follows remembered session persistence',
    () async {
      final secureStore = _MemorySecureKeyValueStore();
      final tokenStorage = TokenStorage(secureStore);

      await tokenStorage.saveAuthenticatedSession(
        accessToken: 'access-token',
        userId: 42,
        role: 'Learner',
      );

      expect(await tokenStorage.readAuthenticatedUserId(), 42);
      expect(secureStore.values['authenticated_user_id'], '42');
      expect(secureStore.values['authenticated_user_role'], 'Learner');
    },
  );

  test('session-only identity is not written to secure storage', () async {
    final secureStore = _MemorySecureKeyValueStore()
      ..values['authenticated_user_id'] = '7';
    final tokenStorage = TokenStorage(secureStore);

    await tokenStorage.saveAuthenticatedSession(
      accessToken: 'session-token',
      userId: 42,
      role: 'Mentor',
      persist: false,
    );

    expect(await tokenStorage.readAuthenticatedUserId(), 42);
    expect(secureStore.values.containsKey('authenticated_user_id'), isFalse);
    expect(secureStore.values.containsKey('authenticated_user_role'), isFalse);
    expect(await tokenStorage.readAuthenticatedRole(), 'Mentor');
  });
}

class _MemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}
