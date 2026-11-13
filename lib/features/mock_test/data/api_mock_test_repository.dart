import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mock_test/data/mock_test_api_paths.dart';
import 'package:rikipath_mobile/features/mock_test/data/mock_test_dtos.dart';
import 'package:rikipath_mobile/features/mock_test/data/mock_test_mapper.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_repository.dart';

class ApiMockTestRepository implements MockTestRepository {
  const ApiMockTestRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<LiveMockTestSummary>> loadTestsByLevel(int jlptLevelId) async {
    final response = await _client.get<Object?>(
      MockTestApiPaths.testsByLevel(jlptLevelId),
    );
    return readMockTestSummaries(
      response.data,
    ).map(MockTestMapper.summary).toList(growable: false);
  }

  @override
  Future<LiveMockTestAttempt> start(int mockTestId) async {
    final response = await _client.post<Object?>(
      MockTestApiPaths.start(mockTestId),
    );
    return MockTestMapper.attempt(readStartAttempt(response.data));
  }

  @override
  Future<LiveMockTestAttempt?> loadActive(int mockTestId) async {
    final response = await _client.get<Object?>(
      MockTestApiPaths.active(mockTestId),
    );
    final attempt = readActiveAttempt(response.data);
    return attempt == null ? null : MockTestMapper.attempt(attempt);
  }

  @override
  Future<LiveMockTestResult> submit(
    int attemptId,
    List<MockTestAnswerSubmission> answers,
  ) async {
    final response = await _client.post<Object?>(
      MockTestApiPaths.submit(attemptId),
      data: <String, Object?>{
        'answers': answers
            .map((answer) => answer.toJson())
            .toList(growable: false),
      },
    );
    return MockTestMapper.result(readAttemptResult(response.data));
  }

  @override
  Future<void> saveAnswer(
    int attemptId,
    MockTestAnswerSubmission answer,
  ) async {
    await _client.put<Object?>(
      MockTestApiPaths.saveAnswer(attemptId),
      data: answer.toJson(),
    );
  }

  @override
  Future<LiveMockTestResult> finalizeExpired(int attemptId) async {
    final response = await _client.post<Object?>(
      MockTestApiPaths.finalizeExpired(attemptId),
    );
    return MockTestMapper.result(readAttemptResult(response.data));
  }

  @override
  Future<LiveMockTestResult> loadResult(int attemptId) async {
    final response = await _client.get<Object?>(
      MockTestApiPaths.result(attemptId),
    );
    return MockTestMapper.result(readAttemptResult(response.data));
  }

  @override
  Future<LiveMockTestDetailedResult> loadDetailedResult(int attemptId) async {
    final response = await _client.get<Object?>(
      MockTestApiPaths.detailedResult(attemptId),
    );
    return MockTestMapper.detailed(readDetailedAttemptResult(response.data));
  }
}
