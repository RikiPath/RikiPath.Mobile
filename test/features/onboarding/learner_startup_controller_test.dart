import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey_repository.dart';
import 'package:rikipath_mobile/features/onboarding/application/learner_startup_controller.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

import '../../support/test_jlpt_catalog.dart';
import '../../support/test_auth_session.dart';

void main() {
  test('returning learner restores Backend goal into local journey', () async {
    final journey = _MemoryJourneyRepository();
    final session = createTestAuthSession();
    final container = ProviderContainer(
      overrides: [
        authSessionControllerProvider.overrideWithValue(session),
        userProfileRepositoryProvider.overrideWithValue(
          _StartupProfileRepository(
            targetJlptLevelId: 309,
            currentStudyLevelId: 204,
            targetExamDate: _futureExamDate,
          ),
        ),
        jlptCatalogRepositoryProvider.overrideWithValue(
          TestJlptCatalogRepository(),
        ),
        learnerJourneyRepositoryProvider.overrideWithValue(journey),
        placementTestRepositoryProvider.overrideWithValue(
          const _NoPlacementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(session.dispose);

    final destination = await container.read(
      learnerStartupDestinationProvider.future,
    );

    expect(destination, LearnerStartupDestination.home);
    expect(journey.saved?.selectedLevelId, 204);
    expect(journey.saved?.dailyStudyMinutes, 45);
    expect(journey.saved?.hasSelectedLevel, isTrue);
  });

  test(
    'first-time learner remains onboarding without local goal writes',
    () async {
      final journey = _MemoryJourneyRepository();
      final catalog = TestJlptCatalogRepository();
      final session = createTestAuthSession();
      final container = ProviderContainer(
        overrides: [
          authSessionControllerProvider.overrideWithValue(session),
          userProfileRepositoryProvider.overrideWithValue(
            const _StartupProfileRepository(
              targetJlptLevelId: null,
              targetExamDate: null,
            ),
          ),
          jlptCatalogRepositoryProvider.overrideWithValue(catalog),
          learnerJourneyRepositoryProvider.overrideWithValue(journey),
          placementTestRepositoryProvider.overrideWithValue(
            const _NoPlacementRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(session.dispose);

      final destination = await container.read(
        learnerStartupDestinationProvider.future,
      );

      expect(destination, LearnerStartupDestination.onboarding);
      expect(catalog.calls, 0);
      expect(journey.saved, isNull);
    },
  );

  test('returning Standard learner without exam date restores home', () async {
    final journey = _MemoryJourneyRepository();
    final catalog = TestJlptCatalogRepository();
    final session = createTestAuthSession();
    final container = ProviderContainer(
      overrides: [
        authSessionControllerProvider.overrideWithValue(session),
        userProfileRepositoryProvider.overrideWithValue(
          const _StartupProfileRepository(
            targetJlptLevelId: 309,
            currentStudyLevelId: 204,
            targetExamDate: null,
          ),
        ),
        jlptCatalogRepositoryProvider.overrideWithValue(catalog),
        learnerJourneyRepositoryProvider.overrideWithValue(journey),
        placementTestRepositoryProvider.overrideWithValue(
          const _NoPlacementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(session.dispose);

    final destination = await container.read(
      learnerStartupDestinationProvider.future,
    );

    expect(destination, LearnerStartupDestination.home);
    expect(catalog.calls, 1);
    expect(journey.saved?.selectedLevelId, 204);
  });

  test('completed placement learner without exam date returns home', () async {
    final journey = _MemoryJourneyRepository();
    final session = createTestAuthSession();
    final container = ProviderContainer(
      overrides: [
        authSessionControllerProvider.overrideWithValue(session),
        userProfileRepositoryProvider.overrideWithValue(
          const _StartupProfileRepository(
            targetJlptLevelId: 309,
            currentStudyLevelId: 204,
            targetExamDate: null,
          ),
        ),
        jlptCatalogRepositoryProvider.overrideWithValue(
          TestJlptCatalogRepository(),
        ),
        learnerJourneyRepositoryProvider.overrideWithValue(journey),
        placementTestRepositoryProvider.overrideWithValue(
          const _NoPlacementRepository(
            status: PlacementTestStatus(
              hasCompletedPlacementTest: true,
              targetJlptLevelId: 309,
              isReadyForLearningPath: true,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(session.dispose);

    final destination = await container.read(
      learnerStartupDestinationProvider.future,
    );

    expect(destination, LearnerStartupDestination.home);
    expect(journey.saved?.selectedLevelId, 204);
  });
}

class _NoPlacementRepository implements PlacementTestRepository {
  const _NoPlacementRepository({
    this.status = const PlacementTestStatus(hasCompletedPlacementTest: false),
  });

  final PlacementTestStatus status;

  @override
  Future<PlacementTestStatus> loadStatus() async => status;

  @override
  Future<PlacementTestAttempt?> loadActiveAttempt() async => null;

  @override
  Future<PlacementTestResult> loadResult(int attemptId) =>
      throw UnimplementedError();

  @override
  Future<PlacementTestAttempt> start() => throw UnimplementedError();

  @override
  Future<PlacementTestResult> submit(
    int attemptId,
    List<PlacementTestAnswerSubmission> answers,
  ) => throw UnimplementedError();
}

final _futureExamDate = DateTime.utc(2030, 12, 7);

class _MemoryJourneyRepository implements LearnerJourneyRepository {
  LearnerJourneyState? saved;

  @override
  Future<LearnerJourneyState> load() async => const LearnerJourneyState();

  @override
  Future<void> reset() async => saved = null;

  @override
  Future<void> save(LearnerJourneyState state) async => saved = state;
}

class _StartupProfileRepository implements UserProfileRepository {
  const _StartupProfileRepository({
    required this.targetJlptLevelId,
    required this.targetExamDate,
    this.currentStudyLevelId,
  });

  final int? targetJlptLevelId;
  final int? currentStudyLevelId;
  final DateTime? targetExamDate;

  UserProfile get profile => UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Minh',
    lastName: 'Nguyễn',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: targetJlptLevelId,
    targetJlptLevelName: targetJlptLevelId == null ? null : 'N3',
    currentStudyLevelId: currentStudyLevelId,
    currentStudyLevelName: currentStudyLevelId == null ? null : 'N4',
    dailyStudyMinutes: 45,
    targetExamDate: targetExamDate,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );

  @override
  Future<UserProfile> loadProfile() async => profile;

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async => profile;

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) async => profile;

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) async => profile;

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async => profile;
}
