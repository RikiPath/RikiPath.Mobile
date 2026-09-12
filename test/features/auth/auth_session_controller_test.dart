import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';

import '../../support/test_auth_session.dart';

void main() {
  test(
    'provider restores a persisted token when session first starts',
    () async {
      final secureStore = TestSecureKeyValueStore(
        accessToken: 'persisted-token',
      );
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(TokenStorage(secureStore)),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(authSessionControllerProvider);

      expect(controller.value, AuthSessionState.unknown);

      await pumpEventQueue();

      expect(controller.value, AuthSessionState.authenticated);
    },
  );

  test('restores an empty secure store as unauthenticated', () async {
    final controller = createTestAuthSession(
      initialState: AuthSessionState.unknown,
    );
    addTearDown(controller.dispose);

    await controller.restore();

    expect(controller.value, AuthSessionState.unauthenticated);
  });

  test('sign out removes the token and ends the local session', () async {
    final secureStore = TestSecureKeyValueStore(accessToken: 'persisted-token');
    final tokenStorage = TokenStorage(secureStore);
    final controller = AuthSessionController(
      tokenStorage,
      initialState: AuthSessionState.authenticated,
    );
    addTearDown(controller.dispose);

    await controller.signOut();

    expect(controller.value, AuthSessionState.unauthenticated);
    expect(await tokenStorage.readAccessToken(), isNull);
    expect(secureStore.values, isEmpty);
  });
}
