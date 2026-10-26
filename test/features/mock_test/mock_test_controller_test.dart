import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

void main() {
  test('discovers tests from the learner target level', () async {
    final repository = _FakeMockTestRepository();
    final container = _container(repository: repository);
    addTearDown(container.dispose);

    final state = await container.read(mockTestControllerProvider.future);

    expect(repository.requestedLevelIds, <int>[3]);
    expect(state.catalogStatus, MockTestCatalogStatus.ready);
    expect(state.tests.single.id, 731);
    expect(state.targetJlptLevelName, 'N3');
  });

  test('target level absence is controlled and skips discovery', () async {
    final repository = _FakeMockTestRepository();
    final container = _container(
      repository: repository,
      profile: _profile(targetLevelId: null, targetLevelName: null),
    );
    addTearDown(container.dispose);

    final state = await container.read(mockTestControllerProvider.future);

    expect(state.catalogStatus, MockTestCatalogStatus.noTargetLevel);
    expect(state.tests, isEmpty);
    expect(repository.requestedLevelIds, isEmpty);
  });

  test('published catalog may be empty without becoming an error', () async {
    final repository = _FakeMockTestRepository(tests: const []);
    final container = _container(repository: repository);
    addTearDown(container.dispose);

    final state = await container.read(mockTestControllerProvider.future);

    expect(state.catalogStatus, MockTestCatalogStatus.empty);
    expect(state.tests, isEmpty);
  });

  test('catalog transport error remains an AsyncError for retry UI', () async {
    final repository = _FakeMockTestRepository(
      catalogError: const NetworkError(),
    );
    final container = _container(repository: repository);
    addTearDown(container.dispose);

    await expectLater(
      container.read(mockTestControllerProvider.future),
      throwsA(isA<NetworkError>()),
    );
    expect(container.read(mockTestControllerProvider).hasError, isTrue);
  });

  test('start and answer preserve backend IDs and server time', () async {
    final repository = _FakeMockTestRepository();
    final container = _container(repository: repository);
    addTearDown(container.dispose);
    await container.read(mockTestControllerProvider.future);
    final controller = container.read(mockTestControllerProvider.notifier);

    expect(controller.selectTest(731), isTrue);
    expect(await controller.startSelectedTest(), isTrue);
    expect(repository.startedTestIds, <int>[731]);
    expect(controller.selectAnswer(1201, 4402), isTrue);
    expect(controller.selectAnswer(1201, 999999), isFalse);

    final state = container.read(mockTestControllerProvider).requireValue;
    expect(state.attempt?.id, 9001);
    expect(state.attempt?.startedAt, DateTime.utc(2026, 10, 19, 8, 30));
    expect(state.attempt?.answers, <int, int>{1201: 4402});
  });

  test(
    'submission includes every question once and null for unanswered',
    () async {
      final repository = _FakeMockTestRepository();
      final container = _container(repository: repository);
      addTearDown(container.dispose);
      final controller = await _start(container);

      controller.selectAnswer(1201, 4401);
      final answers = controller.buildSubmission();

      expect(answers.map((answer) => answer.questionId), <int>[1201, 1202]);
      expect(answers[0].selectedOptionId, 4401);
      expect(answers[1].selectedOptionId, isNull);
      expect(answers.map((answer) => answer.questionId).toSet(), hasLength(2));
    },
  );

  test('duplicate submit taps issue only one backend request', () async {
    final completer = Completer<LiveMockTestResult>();
    final repository = _FakeMockTestRepository(submitCompleter: completer);
    final container = _container(repository: repository);
    addTearDown(container.dispose);
    final controller = await _start(container);

    final first = controller.submit();
    await Future<void>.delayed(Duration.zero);
    final duplicate = await controller.submit();

    expect(duplicate, MockTestSubmitOutcome.failed);
    expect(repository.submitCalls, 1);
    expect(
      container.read(mockTestControllerProvider).requireValue.isSubmitting,
      isTrue,
    );

    completer.complete(_result());
    expect(await first, MockTestSubmitOutcome.success);
    expect(repository.submitCalls, 1);
  });

  test('successful submit publishes only backend result values', () async {
    final repository = _FakeMockTestRepository();
    final container = _container(repository: repository);
    addTearDown(container.dispose);
    final controller = await _start(container);

    expect(await controller.submit(), MockTestSubmitOutcome.success);

    final result = container
        .read(mockTestControllerProvider)
        .requireValue
        .result!;
    expect(result.totalScore, 72.5);
    expect(result.correctCount, 1);
    expect(result.wrongQuestionIds, <int>[1202]);
    expect(repository.lastSubmittedAttemptId, 9001);
    expect(repository.lastAnswers, hasLength(2));
  });

  test('already-completed submit recovers with result GET once', () async {
    final repository = _FakeMockTestRepository(
      submitError: const ValidationError(
        message: 'Lượt làm bài này đã được nộp trước đó.',
      ),
    );
    final container = _container(repository: repository);
    addTearDown(container.dispose);
    final controller = await _start(container);

    final outcome = await controller.submit();

    expect(outcome, MockTestSubmitOutcome.recoveredCompleted);
    expect(repository.loadResultCalls, 1);
    expect(
      container
          .read(mockTestControllerProvider)
          .requireValue
          .result
          ?.totalScore,
      72.5,
    );
  });

  test('expired submit is controlled and does not query result', () async {
    final repository = _FakeMockTestRepository(
      submitError: const ValidationError(
        message: 'Lượt làm bài đã hết thời gian.',
      ),
    );
    final container = _container(repository: repository);
    addTearDown(container.dispose);
    final controller = await _start(container);

    expect(await controller.submit(), MockTestSubmitOutcome.failed);

    final state = container.read(mockTestControllerProvider).requireValue;
    expect(state.actionIssue, MockTestActionIssue.expired);
    expect(state.isSubmitting, isFalse);
    expect(repository.loadResultCalls, 0);
  });

  test('uncertain network submit attempts safe result recovery', () async {
    final repository = _FakeMockTestRepository(
      submitError: const NetworkError(),
    );
    final container = _container(repository: repository);
    addTearDown(container.dispose);
    final controller = await _start(container);

    expect(await controller.submit(), MockTestSubmitOutcome.recoveredCompleted);
    expect(repository.submitCalls, 1);
    expect(repository.loadResultCalls, 1);
  });

  test(
    'failed network recovery keeps attempt and exposes uncertainty',
    () async {
      final repository = _FakeMockTestRepository(
        submitError: const NetworkError(),
        loadResultError: const NetworkError(),
      );
      final container = _container(repository: repository);
      addTearDown(container.dispose);
      final controller = await _start(container);

      expect(await controller.submit(), MockTestSubmitOutcome.failed);

      final state = container.read(mockTestControllerProvider).requireValue;
      expect(state.actionIssue, MockTestActionIssue.networkUncertain);
      expect(state.hasActiveAttempt, isTrue);
      expect(state.isSubmitting, isFalse);
    },
  );

  test(
    'detailed result is loaded with the active backend attempt ID',
    () async {
      final repository = _FakeMockTestRepository();
      final container = _container(repository: repository);
      addTearDown(container.dispose);
      final controller = await _start(container);
      await controller.submit();

      expect(await controller.loadDetailedResult(), isTrue);

      expect(repository.detailedAttemptIds, <int>[9001]);
      final detailed = container
          .read(mockTestControllerProvider)
          .requireValue
          .detailedResult!;
      expect(detailed.questions.single.selectedOptionId, 4402);
      expect(detailed.questions.single.options.single.isCorrect, isTrue);
    },
  );
}

Future<MockTestController> _start(ProviderContainer container) async {
  await container.read(mockTestControllerProvider.future);
  final controller = container.read(mockTestControllerProvider.notifier);
  expect(controller.selectTest(731), isTrue);
  expect(await controller.startSelectedTest(), isTrue);
  return controller;
}

ProviderContainer _container({
  required _FakeMockTestRepository repository,
  UserProfile? profile,
}) {
  return ProviderContainer(
    overrides: [
      mockTestRepositoryProvider.overrideWithValue(repository),
      userProfileRepositoryProvider.overrideWithValue(
        _FakeProfileRepository(profile ?? _profile()),
      ),
    ],
  );
}

UserProfile _profile({int? targetLevelId = 3, String? targetLevelName = 'N3'}) {
  return UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Learner',
    lastName: 'QA',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: targetLevelId,
    targetJlptLevelName: targetLevelName,
    dailyStudyMinutes: 30,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );
}

const _summary = LiveMockTestSummary(
  id: 731,
  title: 'N3 Live Test',
  description: 'Published test',
  jlptLevelName: 'N3',
  timeLimitMinutes: 45,
);

LiveMockTestAttempt _attempt() {
  return LiveMockTestAttempt(
    id: 9001,
    mockTestId: 731,
    startedAt: DateTime.utc(2026, 10, 19, 8, 30),
    timeLimitMinutes: 45,
    previouslyWrongQuestionIds: const <int>[1202],
    questions: const <LiveMockTestQuestion>[
      LiveMockTestQuestion(
        id: 1201,
        mockTestSectionId: 82,
        sectionTitle: 'Grammar',
        sectionOrder: 1,
        order: 1,
        content: 'Question one',
        audioUrl: null,
        imageUrl: null,
        options: <LiveMockTestOption>[
          LiveMockTestOption(id: 4401, content: 'A', order: 1),
          LiveMockTestOption(id: 4402, content: 'B', order: 2),
        ],
      ),
      LiveMockTestQuestion(
        id: 1202,
        mockTestSectionId: 82,
        sectionTitle: 'Grammar',
        sectionOrder: 1,
        order: 2,
        content: 'Question two',
        audioUrl: null,
        imageUrl: null,
        options: <LiveMockTestOption>[
          LiveMockTestOption(id: 4403, content: 'C', order: 1),
          LiveMockTestOption(id: 4404, content: 'D', order: 2),
        ],
      ),
    ],
  );
}

LiveMockTestResult _result() {
  return LiveMockTestResult(
    attemptId: 9001,
    mockTestId: 731,
    status: MockTestAttemptStatus.completed,
    startedAt: DateTime.utc(2026, 10, 19, 8, 30),
    submittedAt: DateTime.utc(2026, 10, 19, 8, 50),
    totalScore: 72.5,
    wrongQuestionIds: const <int>[1202],
    sections: const <LiveMockTestSectionResult>[
      LiveMockTestSectionResult(
        mockTestSectionId: 82,
        sectionTitle: 'Grammar',
        languageSkillName: 'Language Knowledge',
        correctCount: 1,
        totalCount: 2,
        score: 50,
      ),
    ],
  );
}

LiveMockTestDetailedResult _detailed() {
  return const LiveMockTestDetailedResult(
    attemptId: 9001,
    mockTestId: 731,
    totalScore: 72.5,
    questions: <LiveMockTestQuestionReview>[
      LiveMockTestQuestionReview(
        questionId: 1201,
        questionText: 'Question one',
        options: <LiveMockTestReviewOption>[
          LiveMockTestReviewOption(id: 4401, text: 'A', isCorrect: true),
        ],
        selectedOptionId: 4402,
        isCorrect: false,
        explanation: 'A is correct.',
      ),
    ],
  );
}

class _FakeMockTestRepository implements MockTestRepository {
  _FakeMockTestRepository({
    List<LiveMockTestSummary>? tests,
    this.catalogError,
    this.submitError,
    this.loadResultError,
    this.submitCompleter,
  }) : tests = tests ?? const <LiveMockTestSummary>[_summary];

  final List<LiveMockTestSummary> tests;
  final Object? catalogError;
  final Object? submitError;
  final Object? loadResultError;
  final Completer<LiveMockTestResult>? submitCompleter;

  final List<int> requestedLevelIds = <int>[];
  final List<int> startedTestIds = <int>[];
  final List<int> detailedAttemptIds = <int>[];
  int submitCalls = 0;
  int loadResultCalls = 0;
  int? lastSubmittedAttemptId;
  List<MockTestAnswerSubmission>? lastAnswers;

  @override
  Future<List<LiveMockTestSummary>> loadTestsByLevel(int jlptLevelId) async {
    requestedLevelIds.add(jlptLevelId);
    if (catalogError != null) throw catalogError!;
    return tests;
  }

  @override
  Future<LiveMockTestAttempt> start(int mockTestId) async {
    startedTestIds.add(mockTestId);
    return _attempt();
  }

  @override
  Future<LiveMockTestResult> submit(
    int attemptId,
    List<MockTestAnswerSubmission> answers,
  ) async {
    submitCalls += 1;
    lastSubmittedAttemptId = attemptId;
    lastAnswers = answers;
    if (submitError != null) throw submitError!;
    return submitCompleter?.future ?? _result();
  }

  @override
  Future<LiveMockTestResult> loadResult(int attemptId) async {
    loadResultCalls += 1;
    if (loadResultError != null) throw loadResultError!;
    return _result();
  }

  @override
  Future<LiveMockTestDetailedResult> loadDetailedResult(int attemptId) async {
    detailedAttemptIds.add(attemptId);
    return _detailed();
  }
}

class _FakeProfileRepository implements UserProfileRepository {
  const _FakeProfileRepository(this.profile);

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
