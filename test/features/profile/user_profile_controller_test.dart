import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

import '../../support/test_auth_session.dart';

void main() {
  test('initial load exposes loading then the API-backed profile', () async {
    final completer = Completer<UserProfile>();
    final repository = _FakeUserProfileRepository(loadCompleter: completer);
    final container = ProviderContainer(
      overrides: [userProfileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      userProfileControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    expect(container.read(userProfileControllerProvider), isA<AsyncLoading>());

    completer.complete(_profile());
    final state = await container.read(userProfileControllerProvider.future);

    expect(state.profile.email, 'learner@example.com');
    expect(repository.loadCalls, 1);
  });

  test('retry recovers after an initial load error', () async {
    final repository = _FakeUserProfileRepository(
      loadErrors: <Object>[const NetworkError()],
    );
    final container = ProviderContainer(
      overrides: [userProfileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      userProfileControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await expectLater(
      container.read(userProfileControllerProvider.future),
      throwsA(isA<NetworkError>()),
    );

    await container.read(userProfileControllerProvider.notifier).retry();

    expect(container.read(userProfileControllerProvider).hasValue, isTrue);
    expect(repository.loadCalls, 2);
  });

  test(
    'profile update prevents duplicates and publishes returned data',
    () async {
      final updateCompleter = Completer<UserProfile>();
      final repository = _FakeUserProfileRepository(
        updateCompleter: updateCompleter,
      );
      final container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        userProfileControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(userProfileControllerProvider.future);
      final controller = container.read(userProfileControllerProvider.notifier);

      final first = controller.updateName(
        firstName: ' Aiko ',
        lastName: ' Sato ',
      );
      final duplicate = await controller.updateName(
        firstName: 'Other',
        lastName: 'Name',
      );

      expect(duplicate, isFalse);
      expect(repository.updateCalls, 1);
      expect(repository.lastFirstName, 'Aiko');
      expect(repository.lastLastName, 'Sato');
      expect(
        container.read(userProfileControllerProvider).value?.activeMutation,
        ProfileMutation.profile,
      );

      updateCompleter.complete(_profile(firstName: 'Aiko', lastName: 'Sato'));
      expect(await first, isTrue);
      expect(
        container.read(userProfileControllerProvider).value?.profile.fullName,
        'Aiko Sato',
      );
    },
  );

  test(
    'failed notification mutation keeps the previous profile values',
    () async {
      final repository = _FakeUserProfileRepository(
        notificationError: const NetworkError(),
      );
      final container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        userProfileControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(userProfileControllerProvider.future);

      final succeeded = await container
          .read(userProfileControllerProvider.notifier)
          .updateNotificationSettings(
            emailNotificationsEnabled: false,
            systemNotificationsEnabled: true,
          );

      final state = container.read(userProfileControllerProvider).requireValue;
      expect(succeeded, isFalse);
      expect(state.profile.emailNotificationsEnabled, isTrue);
      expect(state.profile.systemNotificationsEnabled, isFalse);
      expect(state.mutationError, isA<NetworkError>());
    },
  );

  test(
    'forbidden profile mutation does not sign out an authenticated user',
    () async {
      final session = createTestAuthSession();
      addTearDown(session.dispose);
      final repository = _FakeUserProfileRepository(
        notificationError: const ForbiddenError(),
      );
      final container = ProviderContainer(
        overrides: [
          authSessionControllerProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        userProfileControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(userProfileControllerProvider.future);

      final succeeded = await container
          .read(userProfileControllerProvider.notifier)
          .updateNotificationSettings(
            emailNotificationsEnabled: false,
            systemNotificationsEnabled: true,
          );

      expect(succeeded, isFalse);
      expect(session.value, AuthSessionState.authenticated);
      expect(session.currentUserId, 42);
    },
  );
}

UserProfile _profile({
  String firstName = 'Minh Anh',
  String lastName = 'Nguyễn',
}) {
  return UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: firstName,
    lastName: lastName,
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: 73,
    targetJlptLevelName: 'N3',
    dailyStudyMinutes: 30,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: false,
  );
}

class _FakeUserProfileRepository implements UserProfileRepository {
  _FakeUserProfileRepository({
    this.loadCompleter,
    this.updateCompleter,
    this.notificationError,
    List<Object>? loadErrors,
  }) : _loadErrors = loadErrors ?? <Object>[];

  final Completer<UserProfile>? loadCompleter;
  final Completer<UserProfile>? updateCompleter;
  final Object? notificationError;
  final List<Object> _loadErrors;

  int loadCalls = 0;
  int updateCalls = 0;
  String? lastFirstName;
  String? lastLastName;

  @override
  Future<UserProfile> loadProfile() async {
    loadCalls += 1;
    if (_loadErrors.isNotEmpty) throw _loadErrors.removeAt(0);
    return loadCompleter?.future ?? _profile();
  }

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) {
    updateCalls += 1;
    lastFirstName = firstName;
    lastLastName = lastName;
    return updateCompleter?.future ??
        Future<UserProfile>.value(
          _profile(firstName: firstName, lastName: lastName),
        );
  }

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async =>
      _profile();

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async => _profile();

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) async {
    if (notificationError != null) throw notificationError!;
    return UserProfile(
      userId: 42,
      email: 'learner@example.com',
      firstName: 'Minh Anh',
      lastName: 'Nguyễn',
      avatarUrl: null,
      role: 'Learner',
      isEmailVerified: true,
      targetJlptLevelId: 73,
      targetJlptLevelName: 'N3',
      dailyStudyMinutes: 30,
      emailNotificationsEnabled: emailNotificationsEnabled,
      systemNotificationsEnabled: systemNotificationsEnabled,
    );
  }
}
