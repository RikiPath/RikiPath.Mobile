import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_repository.dart';
import 'package:rikipath_mobile/features/practice/presentation/mock_test_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  group('Mock Exam Timer Precision & Monotonic Invariance', () {
    test(
      'monotonic stopwatch logic decrements precisely across 3s, 30s, and 2m intervals',
      () {
        final baseStartedAt = DateTime.utc(2026, 11, 6, 8, 0, 0);
        const timeLimitMinutes = 30; // 1800 seconds total
        final attempt = LiveMockTestAttempt(
          id: 101,
          mockTestId: 731,
          startedAt: baseStartedAt,
          timeLimitMinutes: timeLimitMinutes,
          previouslyWrongQuestionIds: const <int>[],
          questions: const <LiveMockTestQuestion>[
            LiveMockTestQuestion(
              id: 1,
              mockTestSectionId: 1,
              sectionTitle: 'Từ vựng',
              sectionOrder: 1,
              order: 1,
              content: 'Q1',
              audioUrl: null,
              imageUrl: null,
              options: <LiveMockTestOption>[
                LiveMockTestOption(id: 1, content: 'A', order: 1),
                LiveMockTestOption(id: 2, content: 'B', order: 2),
              ],
            ),
          ],
        );

        // Baseline: remaining at start is exactly 30 minutes (1800s)
        expect(attempt.remainingAt(baseStartedAt), const Duration(minutes: 30));

        // Interval 1: 3 seconds elapsed
        final at3s = baseStartedAt.add(const Duration(seconds: 3));
        final rem3s = attempt.remainingAt(at3s);
        expect(rem3s.inSeconds, 1800 - 3);
        expect(attempt.deadline.difference(at3s), rem3s);

        // Interval 2: 30 seconds elapsed
        final at30s = baseStartedAt.add(const Duration(seconds: 30));
        final rem30s = attempt.remainingAt(at30s);
        expect(rem30s.inSeconds, 1800 - 30);
        expect(attempt.deadline.difference(at30s), rem30s);

        // Interval 3: 2 minutes (120 seconds) elapsed
        final at2m = baseStartedAt.add(const Duration(minutes: 2));
        final rem2m = attempt.remainingAt(at2m);
        expect(rem2m.inSeconds, 1800 - 120);
        expect(attempt.deadline.difference(at2m), rem2m);

        // Interval 4: Background suspension spanning past the deadline (e.g. 35 minutes)
        final pastDeadline = baseStartedAt.add(const Duration(minutes: 35));
        final remExpired = attempt.remainingAt(pastDeadline);
        expect(remExpired, Duration.zero);
      },
    );

    testWidgets('timer finalizes on expiry without late submit', (
      tester,
    ) async {
      final startTime = DateTime.utc(2026, 11, 6, 8, 0, 0);
      var currentTime = startTime;

      final testAttempt = LiveMockTestAttempt(
        id: 999,
        mockTestId: 731,
        startedAt: startTime,
        timeLimitMinutes: 1, // 60 seconds limit
        previouslyWrongQuestionIds: const <int>[],
        questions: const <LiveMockTestQuestion>[
          LiveMockTestQuestion(
            id: 1,
            mockTestSectionId: 1,
            sectionTitle: 'Từ vựng',
            sectionOrder: 1,
            order: 1,
            content: 'Chọn từ đúng',
            audioUrl: null,
            imageUrl: null,
            options: <LiveMockTestOption>[
              LiveMockTestOption(id: 1, content: 'Đáp án A', order: 1),
              LiveMockTestOption(id: 2, content: 'Đáp án B', order: 2),
            ],
          ),
        ],
      );

      final repo = _ExpiringMockRepository(attempt: testAttempt);
      final container = ProviderContainer(
        overrides: [
          mockTestRepositoryProvider.overrideWithValue(repo),
          userProfileRepositoryProvider.overrideWithValue(
            const _MockProfileRepo(
              UserProfile(
                userId: 1,
                email: 'learner@example.com',
                firstName: 'Test',
                lastName: 'Learner',
                avatarUrl: null,
                role: 'Learner',
                isEmailVerified: true,
                targetJlptLevelId: 3,
                targetJlptLevelName: 'N3',
                dailyStudyMinutes: 30,
                emailNotificationsEnabled: true,
                systemNotificationsEnabled: true,
              ),
            ),
          ),
          mockTestNowProvider.overrideWithValue(() => currentTime),
        ],
      );
      addTearDown(container.dispose);

      await container.read(mockTestControllerProvider.future);
      final controller = container.read(mockTestControllerProvider.notifier);
      expect(controller.selectTest(731), isTrue);
      expect(await controller.startSelectedTest(), isTrue);

      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) => const MockTestScreen(testId: '731'),
          ),
          GoRoute(
            path: '/practice/mock-tests/:testId/result',
            builder: (context, state) =>
                const Scaffold(body: Text('MOCK_RESULT_SCREEN')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exam is in progress, timer is showing 01:00
      expect(find.text('01:00'), findsOneWidget);
      expect(repo.submitCalls, 0);

      // Advance time past 60s deadline
      currentTime = startTime.add(const Duration(seconds: 61));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Server finalization, not a late submit with client answers.
      expect(repo.finalizeCalls, 1);
      expect(repo.submitCalls, 0);
    });
  });
}

class _ExpiringMockRepository implements MockTestRepository {
  _ExpiringMockRepository({required this.attempt});

  final LiveMockTestAttempt attempt;

  @override
  Future<LiveMockTestAttempt?> loadActive(int mockTestId) async => null;
  int submitCalls = 0;
  int finalizeCalls = 0;

  @override
  Future<List<LiveMockTestSummary>> loadTestsByLevel(int jlptLevelId) async {
    return [
      const LiveMockTestSummary(
        id: 731,
        title: 'Đề thi thử JLPT N3',
        description: 'Đề chuẩn QA',
        jlptLevelName: 'N3',
        timeLimitMinutes: 1,
      ),
    ];
  }

  @override
  Future<LiveMockTestAttempt> start(int mockTestId) async => attempt;

  @override
  Future<LiveMockTestResult> submit(
    int attemptId,
    List<MockTestAnswerSubmission> answers,
  ) async {
    submitCalls += 1;
    return LiveMockTestResult(
      attemptId: attemptId,
      mockTestId: 731,
      status: MockTestAttemptStatus.completed,
      startedAt: attempt.startedAt,
      submittedAt: DateTime.utc(2026, 11, 6, 8, 1, 0),
      totalScore: 100,
      wrongQuestionIds: const <int>[],
      sections: const <LiveMockTestSectionResult>[],
    );
  }

  @override
  Future<void> saveAnswer(
    int attemptId,
    MockTestAnswerSubmission answer,
  ) async {}

  @override
  Future<LiveMockTestResult> finalizeExpired(int attemptId) async {
    finalizeCalls += 1;
    return _result(attemptId);
  }

  @override
  Future<LiveMockTestResult> loadResult(int attemptId) async {
    return _result(attemptId);
  }

  LiveMockTestResult _result(int attemptId) => LiveMockTestResult(
    attemptId: attemptId,
    mockTestId: 731,
    status: MockTestAttemptStatus.completed,
    startedAt: attempt.startedAt,
    submittedAt: DateTime.utc(2026, 11, 6, 8, 1, 0),
    totalScore: 100,
    wrongQuestionIds: const <int>[],
    sections: const <LiveMockTestSectionResult>[],
  );

  @override
  Future<LiveMockTestDetailedResult> loadDetailedResult(int attemptId) async {
    throw UnimplementedError();
  }
}

class _MockProfileRepo implements UserProfileRepository {
  const _MockProfileRepo(this.profile);

  final UserProfile profile;

  @override
  Future<UserProfile> loadProfile() async => profile;

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) => throw UnimplementedError();

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) => throw UnimplementedError();

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) => throw UnimplementedError();

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) =>
      throw UnimplementedError();
}
