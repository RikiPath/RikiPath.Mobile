import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';

abstract interface class MockTestRepository {
  Future<List<LiveMockTestSummary>> loadTestsByLevel(int jlptLevelId);

  Future<LiveMockTestAttempt> start(int mockTestId);

  Future<LiveMockTestAttempt?> loadActive(int mockTestId);

  Future<LiveMockTestResult> submit(
    int attemptId,
    List<MockTestAnswerSubmission> answers,
  );

  Future<void> saveAnswer(int attemptId, MockTestAnswerSubmission answer);

  Future<LiveMockTestResult> finalizeExpired(int attemptId);

  Future<LiveMockTestResult> loadResult(int attemptId);

  Future<LiveMockTestDetailedResult> loadDetailedResult(int attemptId);
}
