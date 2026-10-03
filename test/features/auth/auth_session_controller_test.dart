import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jwt.dart';

void main() {
  test(
    'provider restores a persisted token when session first starts',
    () async {
      final secureStore = TestSecureKeyValueStore(
        accessToken: createTestJwt(userId: 42, role: 'Learner'),
        userId: 42,
        role: 'Learner',
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
      expect(controller.currentUserId, 42);
      expect(controller.currentRole, BackendUserRole.learner);
    },
  );

  test(
    'restores a persisted Mentor session with the exact backend role',
    () async {
      final controller = AuthSessionController(
        TokenStorage(
          TestSecureKeyValueStore(
            accessToken: createTestJwt(userId: 84, role: 'Mentor'),
            userId: 84,
            role: 'Mentor',
          ),
        ),
      );
      addTearDown(controller.dispose);

      await controller.restore();

      expect(controller.value, AuthSessionState.authenticated);
      expect(controller.currentUserId, 84);
      expect(controller.currentRole, BackendUserRole.mentor);
    },
  );

  test(
    'invalid persisted role is cleared instead of receiving mobile access',
    () async {
      final secureStore = TestSecureKeyValueStore(
        accessToken: createTestJwt(userId: 42, role: 'Consultant'),
        userId: 42,
        role: 'Consultant',
      );
      final controller = AuthSessionController(TokenStorage(secureStore));
      addTearDown(controller.dispose);

      await controller.restore();

      expect(controller.value, AuthSessionState.unauthenticated);
      expect(controller.currentUserId, isNull);
      expect(controller.currentRole, isNull);
      expect(secureStore.values, isEmpty);
    },
  );

  test('restores an empty secure store as unauthenticated', () async {
    final controller = createTestAuthSession(
      initialState: AuthSessionState.unknown,
    );
    addTearDown(controller.dispose);

    await controller.restore();

    expect(controller.value, AuthSessionState.unauthenticated);
    expect(controller.currentUserId, isNull);
    expect(controller.currentRole, isNull);
  });

  test('expired token is cleared instead of restoring a stale role', () async {
    final secureStore = TestSecureKeyValueStore(
      accessToken: createTestJwt(
        userId: 42,
        role: 'Learner',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      ),
      userId: 42,
      role: 'Learner',
    );
    final controller = AuthSessionController(TokenStorage(secureStore));
    addTearDown(controller.dispose);

    await controller.restore();

    expect(controller.value, AuthSessionState.unauthenticated);
    expect(secureStore.values, isEmpty);
  });

  test('stored identity must match the access-token claims', () async {
    final secureStore = TestSecureKeyValueStore(
      accessToken: createTestJwt(userId: 84, role: 'Mentor'),
      userId: 42,
      role: 'Learner',
    );
    final controller = AuthSessionController(TokenStorage(secureStore));
    addTearDown(controller.dispose);

    await controller.restore();

    expect(controller.value, AuthSessionState.unauthenticated);
    expect(controller.currentRole, isNull);
    expect(secureStore.values, isEmpty);
  });

  test('partial secure session is cleared', () async {
    final secureStore = TestSecureKeyValueStore(
      accessToken: createTestJwt(userId: 42, role: 'Learner'),
      userId: 42,
    );
    final controller = AuthSessionController(TokenStorage(secureStore));
    addTearDown(controller.dispose);

    await controller.restore();

    expect(controller.value, AuthSessionState.unauthenticated);
    expect(secureStore.values, isEmpty);
  });

  test('sign out removes the token and ends the local session', () async {
    final secureStore = TestSecureKeyValueStore(
      accessToken: 'persisted-token',
      userId: 42,
      role: 'Learner',
    );
    final tokenStorage = TokenStorage(secureStore);
    final controller = AuthSessionController(
      tokenStorage,
      initialState: AuthSessionState.authenticated,
      initialUserId: 42,
      initialRole: BackendUserRole.learner,
    );
    addTearDown(controller.dispose);

    await controller.signOut();

    expect(controller.value, AuthSessionState.unauthenticated);
    expect(controller.currentUserId, isNull);
    expect(controller.currentRole, isNull);
    expect(await tokenStorage.readAccessToken(), isNull);
    expect(secureStore.values, isEmpty);
  });
}
