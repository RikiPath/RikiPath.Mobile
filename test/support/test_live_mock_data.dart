import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_repository.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

const testLiveMockSummary = LiveMockTestSummary(
  id: 731,
  title: 'N3 Live Test',
  description: 'Published test from Backend',
  jlptLevelName: 'N3',
  timeLimitMinutes: 45,
);

LiveMockTestAttempt testLiveMockAttempt() {
  return LiveMockTestAttempt(
    id: 9001,
    mockTestId: 731,
    startedAt: DateTime.now().toUtc(),
    timeLimitMinutes: 45,
    previouslyWrongQuestionIds: const <int>[],
    questions: const <LiveMockTestQuestion>[
      LiveMockTestQuestion(
        id: 1201,
        mockTestSectionId: 82,
        sectionTitle: 'Grammar',
        sectionOrder: 1,
        order: 1,
        content: 'Choose the correct answer.',
        audioUrl: null,
        imageUrl: null,
        options: <LiveMockTestOption>[
          LiveMockTestOption(id: 4401, content: 'Correct answer', order: 1),
          LiveMockTestOption(id: 4402, content: 'Other answer', order: 2),
        ],
      ),
      LiveMockTestQuestion(
        id: 1202,
        mockTestSectionId: 83,
        sectionTitle: 'Reading',
        sectionOrder: 2,
        order: 1,
        content: 'Read and choose.',
        audioUrl: null,
        imageUrl: null,
        options: <LiveMockTestOption>[
          LiveMockTestOption(id: 4403, content: 'First', order: 1),
          LiveMockTestOption(id: 4404, content: 'Second', order: 2),
        ],
      ),
    ],
  );
}

LiveMockTestResult testLiveMockResult() {
  return LiveMockTestResult(
    attemptId: 9001,
    mockTestId: 731,
    status: MockTestAttemptStatus.completed,
    startedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
    submittedAt: DateTime.now().toUtc(),
    totalScore: 50,
    wrongQuestionIds: const <int>[1202],
    sections: const <LiveMockTestSectionResult>[
      LiveMockTestSectionResult(
        mockTestSectionId: 82,
        sectionTitle: 'Grammar',
        languageSkillName: 'Language Knowledge',
        correctCount: 1,
        totalCount: 1,
        score: 100,
      ),
      LiveMockTestSectionResult(
        mockTestSectionId: 83,
        sectionTitle: 'Reading',
        languageSkillName: 'Reading',
        correctCount: 0,
        totalCount: 1,
        score: 0,
      ),
    ],
  );
}

const testLiveMockDetailedResult = LiveMockTestDetailedResult(
  attemptId: 9001,
  mockTestId: 731,
  totalScore: 50,
  questions: <LiveMockTestQuestionReview>[
    LiveMockTestQuestionReview(
      questionId: 1201,
      questionText: 'Choose the correct answer.',
      options: <LiveMockTestReviewOption>[
        LiveMockTestReviewOption(
          id: 4401,
          text: 'Correct answer',
          isCorrect: true,
        ),
        LiveMockTestReviewOption(
          id: 4402,
          text: 'Other answer',
          isCorrect: false,
        ),
      ],
      selectedOptionId: 4402,
      isCorrect: false,
      explanation: 'The first option is correct.',
    ),
  ],
);

class TestLiveMockTestRepository implements MockTestRepository {
  TestLiveMockTestRepository({
    this.tests = const <LiveMockTestSummary>[testLiveMockSummary],
  });

  final List<LiveMockTestSummary> tests;
  int submitCalls = 0;
  List<MockTestAnswerSubmission>? submittedAnswers;

  @override
  Future<List<LiveMockTestSummary>> loadTestsByLevel(int jlptLevelId) async =>
      tests;

  @override
  Future<LiveMockTestAttempt> start(int mockTestId) async =>
      testLiveMockAttempt();

  @override
  Future<LiveMockTestResult> submit(
    int attemptId,
    List<MockTestAnswerSubmission> answers,
  ) async {
    submitCalls += 1;
    submittedAnswers = answers;
    return testLiveMockResult();
  }

  @override
  Future<LiveMockTestResult> loadResult(int attemptId) async =>
      testLiveMockResult();

  @override
  Future<LiveMockTestDetailedResult> loadDetailedResult(int attemptId) async =>
      testLiveMockDetailedResult;
}

class TestMockProfileRepository implements UserProfileRepository {
  const TestMockProfileRepository({this.targetLevelId = 3});

  final int? targetLevelId;

  @override
  Future<UserProfile> loadProfile() async => UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Learner',
    lastName: 'QA',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: targetLevelId,
    targetJlptLevelName: targetLevelId == null ? null : 'N3',
    dailyStudyMinutes: 30,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );

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
