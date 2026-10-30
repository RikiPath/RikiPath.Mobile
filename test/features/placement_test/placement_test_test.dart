import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/data/placement_test_api_paths.dart';
import 'package:rikipath_mobile/features/placement_test/data/placement_test_dtos.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/placement_test/presentation/placement_test_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jlpt_catalog.dart';
import '../../support/test_json_preference_store.dart';

void main() {
  test(
    'PlacementTestApiPaths match Backend PlacementTestController routes',
    () {
      expect(PlacementTestApiPaths.status, '/api/PlacementTest/status');
      expect(PlacementTestApiPaths.start, '/api/PlacementTest/start');
      expect(
        PlacementTestApiPaths.activeAttempt,
        '/api/PlacementTest/attempts/active',
      );
      expect(
        PlacementTestApiPaths.submit(42),
        '/api/PlacementTest/attempts/42/submit',
      );
      expect(
        PlacementTestApiPaths.result(42),
        '/api/PlacementTest/attempts/42',
      );
    },
  );

  test('PlacementTest DTO readers parse ApiResponse<T> envelopes', () {
    final statusDto = readPlacementTestStatus(<String, Object?>{
      'statusCode': 200,
      'isSuccess': true,
      'result': <String, Object?>{
        'attemptType': 'placement',
        'hasActiveAttempt': false,
        'activeAttemptId': null,
        'activeAttemptExpiresAt': null,
        'hasCompletedPlacementTest': true,
        'latestCompletedAttemptId': 91,
        'latestSubmittedAt': '2026-10-26T15:00:00Z',
        'latestScorePercent': 66.67,
        'assessedJlptLevelId': 102,
        'assessedJlptLevelName': 'N4',
        'recommendedTargetJlptLevelId': 103,
        'recommendedTargetJlptLevelName': 'N3',
        'targetJlptLevelId': 103,
        'targetJlptLevelName': 'N3',
        'dailyStudyMinutes': 45,
        'targetExamDate': '2027-07-04T00:00:00Z',
        'isReadyForLearningPath': true,
      },
    });
    expect(statusDto.hasCompletedPlacementTest, isTrue);
    expect(statusDto.assessedJlptLevelName, 'N4');
    expect(statusDto.recommendedTargetJlptLevelName, 'N3');
    expect(statusDto.isReadyForLearningPath, isTrue);

    final startDto = readStartPlacementTest(<String, Object?>{
      'statusCode': 201,
      'isSuccess': true,
      'result': <String, Object?>{
        'attemptId': 91,
        'attemptType': 'placement',
        'status': 'inProgress',
        'isResumed': false,
        'startedAt': '2026-10-26T15:00:00Z',
        'expiresAt': '2026-10-26T15:15:00Z',
        'serverNow': '2026-10-26T15:01:00Z',
        'timeLimitMinutes': 15,
        'totalQuestions': 1,
        'questions': <Object?>[
          <String, Object?>{
            'questionId': 501,
            'mockTestId': 105,
            'mockTestSectionId': 50,
            'sectionTitle': 'N5 Tổng hợp',
            'sectionOrder': 1,
            'jlptLevelId': 101,
            'jlptLevelName': 'N5',
            'order': 1,
            'content': '「先生」の読み方は何ですか。',
            'audioUrl': null,
            'imageUrl': null,
            'options': <Object?>[
              <String, Object?>{
                'optionId': 5011,
                'content': 'せんせい',
                'order': 1,
              },
              <String, Object?>{
                'optionId': 5012,
                'content': 'がくせい',
                'order': 2,
              },
            ],
          },
        ],
      },
    });
    expect(startDto.attemptId, 91);
    expect(startDto.questions.single.jlptLevelName, 'N5');
    expect(startDto.questions.single.options.length, 2);

    final resultDto = readPlacementTestResult(<String, Object?>{
      'statusCode': 200,
      'isSuccess': true,
      'result': <String, Object?>{
        'attemptId': 91,
        'attemptType': 'placement',
        'status': 'completed',
        'startedAt': '2026-10-26T15:00:00Z',
        'submittedAt': '2026-10-26T15:05:00Z',
        'totalScore': 75.0,
        'correctCount': 3,
        'totalQuestions': 4,
        'assessedJlptLevelId': 102,
        'assessedJlptLevelName': 'N4',
        'recommendedTargetJlptLevelId': 103,
        'recommendedTargetJlptLevelName': 'N3',
        'wrongQuestionIds': <Object?>[301],
        'levelBreakdowns': <Object?>[
          <String, Object?>{
            'jlptLevelId': 102,
            'jlptLevelName': 'N4',
            'correctCount': 2,
            'totalCount': 2,
            'scorePercent': 100.0,
          },
        ],
        'sections': <Object?>[
          <String, Object?>{
            'mockTestSectionId': 50,
            'sectionTitle': 'N4 Tổng hợp',
            'languageSkillName': 'Từ vựng & Ngữ pháp',
            'correctCount': 3,
            'totalCount': 4,
            'score': 75.0,
          },
        ],
      },
    });
    expect(resultDto.assessedJlptLevelName, 'N4');
    expect(resultDto.recommendedTargetJlptLevelName, 'N3');
    expect(resultDto.levelBreakdowns.single.scorePercent, 100.0);
  });

  testWidgets(
    'PlacementTestScreen applies recommendation and navigates to Roadmap after refresh',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepository = _FakePlacementTestRepository();
      final session = createTestAuthSession();
      final container = ProviderContainer(
        overrides: [
          jlptCatalogRepositoryProvider.overrideWithValue(
            TestJlptCatalogRepository(),
          ),
          userProfileRepositoryProvider.overrideWithValue(
            _StubProfileRepository(),
          ),
          placementTestRepositoryProvider.overrideWithValue(fakeRepository),
          authSessionControllerProvider.overrideWithValue(session),
          jsonPreferenceStoreProvider.overrideWithValue(
            TestJsonPreferenceStore(),
          ),
          learningPathRepositoryProvider.overrideWithValue(
            _FakeLearningPathRepository(),
          ),
        ],
      );
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
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);

      final placementButton = find.byKey(
        const ValueKey<String>('onboarding_placement_test_button'),
      );
      await tester.ensureVisible(placementButton);
      await tester.tap(placementButton);
      await tester.pumpAndSettle();

      expect(find.byType(PlacementTestScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('placement_test_intro_view')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('placement_test_start_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('placement_test_active_view')),
        findsOneWidget,
      );

      // Select answer for Question 1 (501 -> 5011)
      await tester.tap(
        find.byKey(const ValueKey<String>('placement_option_501_5011')),
      );
      await tester.pump();

      // Advance to Question 2
      await tester.tap(
        find.byKey(const ValueKey<String>('placement_next_button')),
      );
      await tester.pumpAndSettle();

      // Select answer for Question 2 (401 -> 4011)
      await tester.tap(
        find.byKey(const ValueKey<String>('placement_option_401_4011')),
      );
      await tester.pump();

      // Submit Placement Test
      await tester.tap(
        find.byKey(const ValueKey<String>('placement_submit_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('placement_test_result_view')),
        findsOneWidget,
      );
      expect(find.text('JLPT N4'), findsWidgets);
      expect(find.text('JLPT N3'), findsWidgets);
      expect(find.text('Kết quả theo phần'), findsOneWidget);
      expect(find.text('N4 Tổng hợp'), findsOneWidget);
      expect(find.text('Đọc hiểu'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('placement_result_section_40')),
          matching: find.text('0/1 (0%)'),
        ),
        findsOneWidget,
      );
      expect(find.text('Câu cần ôn lại (1): 401'), findsOneWidget);

      // Apply the recommended goal, generate, refresh, then open Roadmap.
      await tester.tap(
        find.byKey(
          const ValueKey<String>('placement_apply_recommendation_button'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.learnRoadmap,
      );
    },
  );

  testWidgets(
    'completed Placement without exam date can open Standard Roadmap',
    (tester) async {
      final session = createTestAuthSession();
      final container = ProviderContainer(
        overrides: [
          jlptCatalogRepositoryProvider.overrideWithValue(
            TestJlptCatalogRepository(),
          ),
          userProfileRepositoryProvider.overrideWithValue(
            _StubProfileRepository(),
          ),
          placementTestRepositoryProvider.overrideWithValue(
            _FakePlacementTestRepository(completedWithoutExamDate: true),
          ),
          authSessionControllerProvider.overrideWithValue(session),
          jsonPreferenceStoreProvider.overrideWithValue(
            TestJsonPreferenceStore(),
          ),
          learningPathRepositoryProvider.overrideWithValue(
            _FakeLearningPathRepository(),
          ),
        ],
      );
      final router = createAppRouter(
        authSession: session,
        initialLocation: AppRoutes.placementTest,
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
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('placement_test_result_view')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('placement_apply_recommendation_button'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('placement_set_exam_date_button')),
        findsOneWidget,
      );
      final standard = find.byKey(
        const ValueKey<String>('placement_open_standard_roadmap_button'),
      );
      await tester.ensureVisible(standard);
      await tester.drag(
        find.byKey(const ValueKey<String>('placement_test_result_view')),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      await tester.tap(standard);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.learnRoadmap,
      );
      router.go(AppRoutes.placementTest);
      await tester.pumpAndSettle();
      final examDate = find.byKey(
        const ValueKey<String>('placement_set_exam_date_button'),
      );
      await tester.ensureVisible(examDate);
      await tester.drag(
        find.byKey(const ValueKey<String>('placement_test_result_view')),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      await tester.tap(examDate);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.profileJlptGoal,
      );
    },
  );
}

class _FakePlacementTestRepository implements PlacementTestRepository {
  _FakePlacementTestRepository({this.completedWithoutExamDate = false});

  final bool completedWithoutExamDate;

  @override
  Future<PlacementTestStatus> loadStatus() async {
    if (completedWithoutExamDate) {
      return const PlacementTestStatus(
        hasCompletedPlacementTest: true,
        latestCompletedAttemptId: 77,
        recommendedTargetJlptLevelId: 103,
        recommendedTargetJlptLevelName: 'N3',
        dailyStudyMinutes: 30,
      );
    }
    return PlacementTestStatus(
      hasCompletedPlacementTest: false,
      targetExamDate: DateTime.utc(2027, 7, 4),
    );
  }

  @override
  Future<PlacementTestAttempt?> loadActiveAttempt() async => null;

  @override
  Future<PlacementTestAttempt> start() async {
    return PlacementTestAttempt(
      id: 77,
      startedAt: DateTime.now().toUtc(),
      timeLimitMinutes: 15,
      totalQuestions: 2,
      questions: const <PlacementTestQuestion>[
        PlacementTestQuestion(
          id: 501,
          mockTestId: 105,
          mockTestSectionId: 50,
          sectionTitle: 'N5 Tổng hợp',
          sectionOrder: 1,
          jlptLevelId: 101,
          jlptLevelName: 'N5',
          order: 1,
          content: 'Câu hỏi N5 số 1',
          options: <PlacementTestOption>[
            PlacementTestOption(id: 5011, content: 'Đáp án A', order: 1),
            PlacementTestOption(id: 5012, content: 'Đáp án B', order: 2),
          ],
        ),
        PlacementTestQuestion(
          id: 401,
          mockTestId: 104,
          mockTestSectionId: 40,
          sectionTitle: 'N4 Tổng hợp',
          sectionOrder: 1,
          jlptLevelId: 102,
          jlptLevelName: 'N4',
          order: 2,
          content: 'Câu hỏi N4 số 2',
          options: <PlacementTestOption>[
            PlacementTestOption(id: 4011, content: 'Đáp án A', order: 1),
            PlacementTestOption(id: 4012, content: 'Đáp án B', order: 2),
          ],
        ),
      ],
    );
  }

  @override
  Future<PlacementTestResult> submit(
    int attemptId,
    List<PlacementTestAnswerSubmission> answers,
  ) async {
    return PlacementTestResult(
      attemptId: attemptId,
      status: MockTestAttemptStatus.completed,
      startedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 3)),
      submittedAt: DateTime.now().toUtc(),
      totalScore: 50.0,
      correctCount: 1,
      totalQuestions: 2,
      assessedJlptLevelId: 102,
      assessedJlptLevelName: 'N4',
      recommendedTargetJlptLevelId: 103,
      recommendedTargetJlptLevelName: 'N3',
      wrongQuestionIds: const <int>[401],
      levelBreakdowns: const <PlacementLevelBreakdown>[
        PlacementLevelBreakdown(
          jlptLevelId: 101,
          jlptLevelName: 'N5',
          correctCount: 1,
          totalCount: 1,
          scorePercent: 100.0,
        ),
        PlacementLevelBreakdown(
          jlptLevelId: 102,
          jlptLevelName: 'N4',
          correctCount: 0,
          totalCount: 1,
          scorePercent: 0.0,
        ),
      ],
      sections: const <PlacementSectionResult>[
        PlacementSectionResult(
          mockTestSectionId: 40,
          sectionTitle: 'N4 Tổng hợp',
          languageSkillName: 'Đọc hiểu',
          correctCount: 0,
          totalCount: 1,
          score: 0.0,
        ),
      ],
    );
  }

  @override
  Future<PlacementTestResult> loadResult(int attemptId) =>
      submit(attemptId, const <PlacementTestAnswerSubmission>[]);
}

class _StubProfileRepository implements UserProfileRepository {
  UserProfile get _profile => const UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Learner',
    lastName: 'QA',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: null,
    targetJlptLevelName: null,
    dailyStudyMinutes: 30,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );

  @override
  Future<UserProfile> loadProfile() async => _profile;

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async => UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Learner',
    lastName: 'QA',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: targetJlptLevelId,
    targetJlptLevelName: 'N3',
    dailyStudyMinutes: dailyStudyMinutes,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) async => _profile;

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) async => _profile;

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async =>
      _profile;
}

class _FakeLearningPathRepository implements LearningPathRepository {
  final RecommendedLearningPath path = RecommendedLearningPath(
    userId: 42,
    generatedAt: DateTime.utc(2030),
    summary: 'Lộ trình kiểm thử',
    strengths: const <String>[],
    weaknesses: const <String>[],
    feasibility: 'Khả thi',
    isExamDateRealistic: true,
    recommendedStudyDays: 1,
    focusTopics: const <String>[],
    dailySchedules: const <RecommendedLearningDay>[],
  );

  @override
  Future<RecommendedLearningPath> generate() async => path;

  @override
  Future<RecommendedLearningPath?> loadLatest() async => path;
}
