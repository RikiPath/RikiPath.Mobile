import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';

AuthSessionController createTestAuthSession({
  AuthSessionState initialState = AuthSessionState.authenticated,
  TestSecureKeyValueStore? secureStore,
}) {
  return AuthSessionController(
    TokenStorage(secureStore ?? TestSecureKeyValueStore()),
    initialState: initialState,
  );
}

class TestSecureKeyValueStore implements SecureKeyValueStore {
  TestSecureKeyValueStore({String? accessToken}) {
    if (accessToken != null) {
      values['access_token'] = accessToken;
    }
  }

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
