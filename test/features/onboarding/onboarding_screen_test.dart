import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/core/widgets/riki_buttons.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/learning/presentation/learning_roadmap_screen.dart';
import 'package:rikipath_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jlpt_catalog.dart';

void main() {
  test('learner JLPT choices support N5 through N1', () {
    expect(JlptLevel.values, <JlptLevel>[
      JlptLevel.n5,
      JlptLevel.n4,
      JlptLevel.n3,
      JlptLevel.n2,
      JlptLevel.n1,
    ]);
    expect(JlptLevel.values.map((level) => level.label), <String>[
      'N5',
      'N4',
      'N3',
      'N2',
      'N1',
    ]);
  });

  test('daily study choices match the Web 15 through 90 minute set', () {
    expect(DailyStudyTime.values.map((choice) => choice.minutes), <int>[
      15,
      30,
      45,
      60,
      90,
    ]);
  });

  testWidgets('target step follows the live N5 through N1 catalog', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _skipPlacement(tester);

    expect(
      find.byKey(const ValueKey<String>('current_level_n5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('current_level_n4')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('current_level_n3')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('jlpt_n5')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('jlpt_n4')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('jlpt_n3')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('jlpt_n2')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('jlpt_n1')), findsOneWidget);
  });

  testWidgets('Placement Test call to action is localized in Japanese', (
    tester,
  ) async {
    await _pumpOnboarding(tester, locale: const Locale('ja'));

    expect(find.text('現在のレベルがまだ分かりませんか？'), findsOneWidget);
    expect(
      find.text('レベル診断テストを受けて、あなたに合ったJLPT目標レベルの提案を受け取りましょう。'),
      findsOneWidget,
    );
    expect(find.text('入門レベル診断を受ける'), findsOneWidget);
  });

  testWidgets('Placement Test call to action is localized in Vietnamese', (
    tester,
  ) async {
    await _pumpOnboarding(tester, locale: const Locale('vi'));

    expect(find.text('Chưa rõ trình độ hiện tại?'), findsOneWidget);
    expect(
      find.text(
        'Làm bài kiểm tra đánh giá năng lực đầu vào để nhận đề xuất cấp độ JLPT phù hợp.',
      ),
      findsOneWidget,
    );
    expect(find.text('Kiểm tra trình độ đầu vào'), findsOneWidget);
  });

  testWidgets('continue is disabled before a JLPT target is selected', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _skipPlacement(tester);

    final button = tester.widget<RikiPrimaryButton>(
      find.byKey(const ValueKey<String>('onboarding_continue_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('selecting a JLPT target stores the typed level', (tester) async {
    final harness = await _pumpOnboarding(tester);

    await _skipPlacement(tester);
    await _selectCurrentAndTarget(tester, JlptLevel.n5, JlptLevel.n4);

    expect(
      harness.container
          .read(onboardingControllerProvider)
          .selectedJlptLevel
          ?.level,
      JlptLevel.n4,
    );
  });

  testWidgets('Skip records SKIPPED and makes no profile or AI request', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _skipPlacement(tester);

    expect(harness.placementRepository.skipCalls, 1);
    expect(harness.profileRepository.goalCalls, 0);
    expect(harness.profileRepository.studyLevelCalls, 0);
    expect(
      harness.container.read(onboardingControllerProvider).currentStep,
      OnboardingStep.studyLevels,
    );
  });

  testWidgets('continue advances from target to study-time selection', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n5);

    final state = harness.container.read(onboardingControllerProvider);
    expect(state.currentStep, OnboardingStep.studyTime);
    expect(find.text('Bạn muốn học bao lâu mỗi ngày?'), findsOneWidget);
  });

  testWidgets('study-time step displays all five supported choices', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n3);

    for (final minutes in <int>[15, 30, 45, 60, 90]) {
      expect(find.text('$minutes phút/ngày'), findsOneWidget);
    }
  });

  testWidgets('completion is disabled until study time is selected', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n3);

    final button = tester.widget<RikiPrimaryButton>(
      find.byKey(const ValueKey<String>('onboarding_complete_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('back from study time preserves both selections', (tester) async {
    final harness = await _pumpOnboarding(tester);
    await _reachStudyTime(tester, JlptLevel.n4);
    await tester.tap(find.byKey(const ValueKey<String>('study_time_45')));
    await tester.pump();

    await tester.tap(find.byTooltip('Quay lại bước chọn mục tiêu'));
    await tester.pump();

    final state = harness.container.read(onboardingControllerProvider);
    expect(state.currentStep, OnboardingStep.studyLevels);
    expect(state.selectedCurrentStudyLevel?.level, JlptLevel.n5);
    expect(state.selectedJlptLevel?.level, JlptLevel.n4);
    expect(state.selectedStudyTime, DailyStudyTime.fortyFive);
  });

  testWidgets('completion summary uses the selected JLPT target', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachCompletion(
      tester,
      level: JlptLevel.n5,
      studyTime: DailyStudyTime.thirty,
    );

    expect(find.text('Mục tiêu JLPT N5'), findsOneWidget);
    expect(find.text('Mục tiêu JLPT N3'), findsNothing);
  });

  testWidgets('completion summary uses the selected daily study time', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachCompletion(
      tester,
      level: JlptLevel.n4,
      studyTime: DailyStudyTime.sixty,
    );

    expect(find.text('60 phút/ngày · Chuyên sâu'), findsOneWidget);
    expect(find.text('30 phút/ngày · Cân bằng'), findsNothing);
  });

  testWidgets(
    'saving onboarding persists current level, separate target, date and minutes',
    (tester) async {
      final harness = await _pumpOnboarding(tester);
      await _reachCompletion(
        tester,
        level: JlptLevel.n4,
        studyTime: DailyStudyTime.fortyFive,
      );

      expect(harness.profileRepository.savedCurrentStudyLevelId, 101);
      expect(harness.profileRepository.savedTargetLevelId, 204);
      expect(harness.profileRepository.savedDailyMinutes, 45);
      expect(harness.profileRepository.savedExamDate, DateTime(2030, 12, 1));
    },
  );

  testWidgets('back from completion keeps choices and returns to study time', (
    tester,
  ) async {
    final harness = await _pumpOnboarding(tester);
    await _reachCompletion(
      tester,
      level: JlptLevel.n3,
      studyTime: DailyStudyTime.fifteen,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    final state = harness.container.read(onboardingControllerProvider);
    expect(state.currentStep, OnboardingStep.studyTime);
    expect(state.selectedJlptLevel?.level, JlptLevel.n3);
    expect(state.selectedStudyTime, DailyStudyTime.fifteen);
  });

  testWidgets('start action opens the persisted Standard Roadmap', (
    tester,
  ) async {
    await _pumpOnboarding(tester);
    await _reachCompletion(
      tester,
      level: JlptLevel.n4,
      studyTime: DailyStudyTime.fortyFive,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('onboarding_start_button')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_start_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LearningRoadmapScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsOneWidget);
  });

  testWidgets('onboarding route stays outside the learner tab shell', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
  });
}

class _OnboardingHarness {
  const _OnboardingHarness({
    required this.container,
    required this.profileRepository,
    required this.placementRepository,
  });

  final ProviderContainer container;
  final _OnboardingProfileRepository profileRepository;
  final _OnboardingPlacementRepository placementRepository;
}

Future<_OnboardingHarness> _pumpOnboarding(
  WidgetTester tester, {
  Locale? locale,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final profileRepository = _OnboardingProfileRepository();
  final placementRepository = _OnboardingPlacementRepository();
  final container = ProviderContainer(
    overrides: [
      jlptCatalogRepositoryProvider.overrideWithValue(
        TestJlptCatalogRepository(),
      ),
      userProfileRepositoryProvider.overrideWithValue(profileRepository),
      placementTestRepositoryProvider.overrideWithValue(placementRepository),
    ],
  );
  final session = createTestAuthSession();
  final router = createAppRouter(
    authSession: session,
    initialLocation: AppRoutes.onboarding,
  );
  addTearDown(container.dispose);
  addTearDown(session.dispose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        locale: locale ?? const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _OnboardingHarness(
    container: container,
    profileRepository: profileRepository,
    placementRepository: placementRepository,
  );
}

class _OnboardingProfileRepository
    implements
        UserProfileRepository,
        StudyLevelProfileRepository,
        TargetExamDateProfileRepository {
  int goalCalls = 0;
  int studyLevelCalls = 0;
  int? savedCurrentStudyLevelId;
  int? savedTargetLevelId;
  int? savedDailyMinutes;
  DateTime? savedExamDate;

  @override
  Future<UserProfile> switchStudyLevel({
    required int currentStudyLevelId,
  }) async {
    studyLevelCalls++;
    savedCurrentStudyLevelId = currentStudyLevelId;
    return _profile(targetLevelId: savedTargetLevelId);
  }

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async {
    goalCalls++;
    savedTargetLevelId = targetJlptLevelId;
    savedDailyMinutes = dailyStudyMinutes;
    return _profile(
      targetLevelId: targetJlptLevelId,
      dailyStudyMinutes: dailyStudyMinutes,
    );
  }

  @override
  Future<UserProfile> setJlptGoalWithExamDate({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
    required DateTime targetExamDate,
  }) async {
    goalCalls++;
    savedTargetLevelId = targetJlptLevelId;
    savedDailyMinutes = dailyStudyMinutes;
    savedExamDate = targetExamDate;
    return _profile(
      targetLevelId: targetJlptLevelId,
      dailyStudyMinutes: dailyStudyMinutes,
      targetExamDate: targetExamDate,
    );
  }

  @override
  Future<UserProfile> loadProfile() async => _profile();

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) async => _profile();

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) async => _profile();

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async =>
      _profile();

  UserProfile _profile({
    int? targetLevelId,
    int dailyStudyMinutes = 30,
    DateTime? targetExamDate,
  }) => UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Learner',
    lastName: 'QA',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: targetLevelId,
    targetJlptLevelName: targetLevelId == null ? null : 'N4',
    currentStudyLevelId: savedCurrentStudyLevelId,
    currentStudyLevelName: savedCurrentStudyLevelId == null ? null : 'N5',
    dailyStudyMinutes: dailyStudyMinutes,
    targetExamDate: targetExamDate,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );
}

class _OnboardingPlacementRepository
    implements PlacementTestRepository, PlacementSkipRepository {
  int skipCalls = 0;

  @override
  Future<PlacementTestStatus> skip() async {
    skipCalls++;
    return const PlacementTestStatus(
      hasCompletedPlacementTest: false,
      placementDecision: PlacementDecision.skipped,
    );
  }

  @override
  Future<PlacementTestStatus> loadStatus() async =>
      const PlacementTestStatus(hasCompletedPlacementTest: false);

  @override
  Future<PlacementTestAttempt?> loadActiveAttempt() async => null;

  @override
  Future<PlacementTestAttempt> start() => throw UnimplementedError();

  @override
  Future<PlacementTestResult> submit(
    int attemptId,
    List<PlacementTestAnswerSubmission> answers,
  ) => throw UnimplementedError();

  @override
  Future<PlacementTestResult> loadResult(int attemptId) =>
      throw UnimplementedError();
}

Future<void> _reachStudyTime(WidgetTester tester, JlptLevel level) async {
  await _skipPlacement(tester);
  await _selectCurrentAndTarget(tester, JlptLevel.n5, level);
  await tester.ensureVisible(
    find.byKey(const ValueKey<String>('onboarding_continue_button')),
  );
  await tester.tap(
    find.byKey(const ValueKey<String>('onboarding_continue_button')),
  );
  await tester.pumpAndSettle();
}

Future<void> _skipPlacement(WidgetTester tester) async {
  final skip = find.byKey(
    const ValueKey<String>('onboarding_skip_placement_button'),
  );
  if (skip.evaluate().isEmpty) return;
  await tester.ensureVisible(skip);
  await tester.tap(skip);
  await tester.pumpAndSettle();
}

Future<void> _selectCurrentAndTarget(
  WidgetTester tester,
  JlptLevel current,
  JlptLevel target,
) async {
  await tester.ensureVisible(
    find.byKey(ValueKey<String>('current_level_${current.name}')),
  );
  await tester.tap(
    find.byKey(ValueKey<String>('current_level_${current.name}')),
  );
  await tester.pump();
  await tester.ensureVisible(
    find.byKey(ValueKey<String>('jlpt_${target.name}')),
  );
  await tester.tap(find.byKey(ValueKey<String>('jlpt_${target.name}')));
  await tester.pump();
}

Future<void> _reachCompletion(
  WidgetTester tester, {
  required JlptLevel level,
  required DailyStudyTime studyTime,
}) async {
  await _reachStudyTime(tester, level);
  await tester.ensureVisible(
    find.byKey(ValueKey<String>('study_time_${studyTime.minutes}')),
  );
  await tester.tap(
    find.byKey(ValueKey<String>('study_time_${studyTime.minutes}')),
  );
  await tester.pump();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(OnboardingScreen)),
  );
  container
      .read(onboardingControllerProvider.notifier)
      .selectTargetExamDate(DateTime(2030, 12, 1));
  await tester.pump();
  await tester.ensureVisible(
    find.byKey(const ValueKey<String>('onboarding_complete_button')),
  );
  await tester.tap(
    find.byKey(const ValueKey<String>('onboarding_complete_button')),
  );
  await tester.pumpAndSettle();
}
