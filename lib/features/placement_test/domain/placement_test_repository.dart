import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';

abstract interface class PlacementTestRepository {
  Future<PlacementTestStatus> loadStatus();

  Future<PlacementTestAttempt?> loadActiveAttempt();

  Future<PlacementTestAttempt> start();

  Future<PlacementTestResult> submit(
    int attemptId,
    List<PlacementTestAnswerSubmission> answers,
  );

  Future<PlacementTestResult> loadResult(int attemptId);
}

abstract interface class PlacementSkipRepository {
  Future<PlacementTestStatus> skip();
}
