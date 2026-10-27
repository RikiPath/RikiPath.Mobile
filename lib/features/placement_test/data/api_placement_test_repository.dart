import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/placement_test/data/placement_test_api_paths.dart';
import 'package:rikipath_mobile/features/placement_test/data/placement_test_dtos.dart';
import 'package:rikipath_mobile/features/placement_test/data/placement_test_mapper.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';

class ApiPlacementTestRepository
    implements PlacementTestRepository, PlacementSkipRepository {
  const ApiPlacementTestRepository(this._client);

  final ApiClient _client;

  @override
  Future<PlacementTestStatus> loadStatus() async {
    final response = await _client.get<Object?>(PlacementTestApiPaths.status);
    return PlacementTestMapper.status(readPlacementTestStatus(response.data));
  }

  @override
  Future<PlacementTestStatus> skip() async {
    final response = await _client.post<Object?>(PlacementTestApiPaths.skip);
    return PlacementTestMapper.status(readPlacementTestStatus(response.data));
  }

  @override
  Future<PlacementTestAttempt?> loadActiveAttempt() async {
    final response = await _client.get<Object?>(
      PlacementTestApiPaths.activeAttempt,
    );
    final dto = readActivePlacementTest(response.data);
    return dto == null ? null : PlacementTestMapper.attempt(dto);
  }

  @override
  Future<PlacementTestAttempt> start() async {
    final response = await _client.post<Object?>(PlacementTestApiPaths.start);
    return PlacementTestMapper.attempt(readStartPlacementTest(response.data));
  }

  @override
  Future<PlacementTestResult> submit(
    int attemptId,
    List<PlacementTestAnswerSubmission> answers,
  ) async {
    final response = await _client.post<Object?>(
      PlacementTestApiPaths.submit(attemptId),
      data: <String, Object?>{
        'answers': answers
            .map(
              (answer) => <String, Object?>{
                'questionId': answer.questionId,
                'selectedOptionId': answer.selectedOptionId,
              },
            )
            .toList(growable: false),
      },
    );
    return PlacementTestMapper.result(readPlacementTestResult(response.data));
  }

  @override
  Future<PlacementTestResult> loadResult(int attemptId) async {
    final response = await _client.get<Object?>(
      PlacementTestApiPaths.result(attemptId),
    );
    return PlacementTestMapper.result(readPlacementTestResult(response.data));
  }
}
