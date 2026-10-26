import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/mock_test/data/api_mock_test_repository.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';

final mockTestRepositoryProvider = Provider<MockTestRepository>((ref) {
  return ApiMockTestRepository(ref.watch(apiClientProvider));
});

final mockTestNowProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

final mockTestControllerProvider =
    AsyncNotifierProvider<MockTestController, MockTestFlowState>(
      MockTestController.new,
      retry: (_, _) => null,
    );

enum MockTestCatalogStatus { ready, noTargetLevel, empty }

enum MockTestActionIssue {
  validation,
  expired,
  alreadyCompleted,
  conflict,
  notFound,
  networkUncertain,
  unknown,
}

enum MockTestSubmitOutcome { success, recoveredCompleted, failed }

class MockTestController extends AsyncNotifier<MockTestFlowState> {
  MockTestRepository get _repository => ref.read(mockTestRepositoryProvider);

  @override
  Future<MockTestFlowState> build() => _loadCatalog();

  Future<MockTestFlowState> _loadCatalog() async {
    final profile = await ref.read(userProfileRepositoryProvider).loadProfile();
    final levelId = profile.targetJlptLevelId;
    if (levelId == null) {
      return const MockTestFlowState(
        catalogStatus: MockTestCatalogStatus.noTargetLevel,
        tests: <LiveMockTestSummary>[],
      );
    }

    final tests = await _repository.loadTestsByLevel(levelId);
    return MockTestFlowState(
      catalogStatus: tests.isEmpty
          ? MockTestCatalogStatus.empty
          : MockTestCatalogStatus.ready,
      tests: tests,
      targetJlptLevelId: levelId,
      targetJlptLevelName: profile.targetJlptLevelName,
    );
  }

  Future<void> retryCatalog() async {
    state = const AsyncLoading<MockTestFlowState>();
    state = await AsyncValue.guard(_loadCatalog);
  }

  bool selectTest(int testId) {
    final current = state.value;
    if (current == null || current.isStarting || current.isSubmitting) {
      return false;
    }
    final selected = current.tests
        .where((test) => test.id == testId)
        .firstOrNull;
    if (selected == null) return false;

    if (current.selectedTest?.id == testId) return true;
    state = AsyncData(
      current.copyWith(
        selectedTest: selected,
        clearAttempt: true,
        clearResult: true,
        clearDetailedResult: true,
        clearActionIssue: true,
      ),
    );
    return true;
  }

  Future<bool> startSelectedTest() async {
    final current = state.value;
    final selected = current?.selectedTest;
    if (current == null ||
        selected == null ||
        current.isStarting ||
        current.isSubmitting ||
        current.hasActiveAttempt) {
      return false;
    }

    state = AsyncData(
      current.copyWith(isStarting: true, clearActionIssue: true),
    );
    try {
      final attempt = await _repository.start(selected.id);
      if (attempt.mockTestId != selected.id || attempt.questions.isEmpty) {
        throw const FormatException('Invalid Mock Test start response.');
      }
      state = AsyncData(
        state.requireValue.copyWith(
          attempt: attempt,
          isStarting: false,
          clearResult: true,
          clearDetailedResult: true,
        ),
      );
      return true;
    } catch (error) {
      state = AsyncData(
        state.requireValue.copyWith(
          isStarting: false,
          actionIssue: _classify(error),
        ),
      );
      return false;
    }
  }

  bool showQuestion(int index) {
    final current = state.value;
    final attempt = current?.attempt;
    if (current == null || attempt == null || current.isSubmitting) {
      return false;
    }
    final bounded = index.clamp(0, attempt.questions.length - 1);
    state = AsyncData(
      current.copyWith(
        attempt: attempt.copyWith(currentQuestionIndex: bounded),
      ),
    );
    return true;
  }

  bool selectAnswer(int questionId, int optionId) {
    final current = state.value;
    final attempt = current?.attempt;
    if (current == null ||
        attempt == null ||
        current.isSubmitting ||
        current.result != null) {
      return false;
    }
    final question = attempt.questions
        .where((candidate) => candidate.id == questionId)
        .firstOrNull;
    if (question == null ||
        !question.options.any((option) => option.id == optionId)) {
      return false;
    }

    state = AsyncData(
      current.copyWith(
        attempt: attempt.copyWith(
          answers: <int, int>{...attempt.answers, questionId: optionId},
        ),
        clearActionIssue: true,
      ),
    );
    return true;
  }

  List<MockTestAnswerSubmission> buildSubmission() {
    final attempt = state.value?.attempt;
    if (attempt == null) return const <MockTestAnswerSubmission>[];
    return attempt.questions
        .map(
          (question) => MockTestAnswerSubmission(
            questionId: question.id,
            selectedOptionId: attempt.answers[question.id],
          ),
        )
        .toList(growable: false);
  }

  Future<MockTestSubmitOutcome> submit() async {
    final current = state.value;
    final attempt = current?.attempt;
    if (current == null ||
        attempt == null ||
        current.isSubmitting ||
        current.result != null) {
      return MockTestSubmitOutcome.failed;
    }

    final answers = buildSubmission();
    state = AsyncData(
      current.copyWith(isSubmitting: true, clearActionIssue: true),
    );
    try {
      final result = await _repository.submit(attempt.id, answers);
      _publishResult(result);
      return MockTestSubmitOutcome.success;
    } catch (error) {
      final issue = _classify(error);
      if (issue == MockTestActionIssue.alreadyCompleted ||
          issue == MockTestActionIssue.networkUncertain) {
        final recovered = await _recoverCompletedResult(attempt.id);
        if (recovered) return MockTestSubmitOutcome.recoveredCompleted;
      }
      state = AsyncData(
        state.requireValue.copyWith(isSubmitting: false, actionIssue: issue),
      );
      return MockTestSubmitOutcome.failed;
    }
  }

  Future<bool> loadResult() async {
    final current = state.value;
    final attempt = current?.attempt;
    if (current == null || attempt == null || current.isResultLoading) {
      return false;
    }
    if (current.result != null) return true;

    state = AsyncData(
      current.copyWith(isResultLoading: true, clearActionIssue: true),
    );
    try {
      final result = await _repository.loadResult(attempt.id);
      _publishResult(result);
      return true;
    } catch (error) {
      state = AsyncData(
        state.requireValue.copyWith(
          isResultLoading: false,
          actionIssue: _classify(error),
        ),
      );
      return false;
    }
  }

  Future<bool> loadDetailedResult() async {
    final current = state.value;
    final attempt = current?.attempt;
    if (current == null || attempt == null || current.isDetailedLoading) {
      return false;
    }
    if (current.detailedResult != null) return true;

    state = AsyncData(
      current.copyWith(isDetailedLoading: true, clearActionIssue: true),
    );
    try {
      final detailed = await _repository.loadDetailedResult(attempt.id);
      if (detailed.attemptId != attempt.id ||
          detailed.mockTestId != attempt.mockTestId) {
        throw const FormatException(
          'Detailed Mock Test result does not match the active attempt.',
        );
      }
      state = AsyncData(
        state.requireValue.copyWith(
          detailedResult: detailed,
          isDetailedLoading: false,
        ),
      );
      return true;
    } catch (error) {
      state = AsyncData(
        state.requireValue.copyWith(
          isDetailedLoading: false,
          actionIssue: _classify(error),
        ),
      );
      return false;
    }
  }

  void prepareRetake() {
    final current = state.value;
    if (current == null || current.isSubmitting) return;
    state = AsyncData(
      current.copyWith(
        clearAttempt: true,
        clearResult: true,
        clearDetailedResult: true,
        clearActionIssue: true,
      ),
    );
  }

  void clearActionIssue() {
    final current = state.value;
    if (current?.actionIssue == null) return;
    state = AsyncData(current!.copyWith(clearActionIssue: true));
  }

  Future<bool> _recoverCompletedResult(int attemptId) async {
    try {
      final result = await _repository.loadResult(attemptId);
      _publishResult(result);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _publishResult(LiveMockTestResult result) {
    final attempt = state.requireValue.attempt;
    if (attempt == null ||
        result.attemptId != attempt.id ||
        result.mockTestId != attempt.mockTestId ||
        result.status != MockTestAttemptStatus.completed) {
      throw const FormatException(
        'Mock Test result does not match the active attempt.',
      );
    }
    state = AsyncData(
      state.requireValue.copyWith(
        result: result,
        isSubmitting: false,
        isResultLoading: false,
        clearDetailedResult: true,
        clearActionIssue: true,
      ),
    );
  }

  MockTestActionIssue _classify(Object error) {
    if (error is NetworkError) return MockTestActionIssue.networkUncertain;
    if (error is ConflictError) return MockTestActionIssue.conflict;
    if (error is NotFoundError) return MockTestActionIssue.notFound;
    if (error is ValidationError) {
      final message = error.message.toLowerCase();
      if (message.contains('hết thời gian') || message.contains('expired')) {
        return MockTestActionIssue.expired;
      }
      if (message.contains('đã được nộp') ||
          message.contains('already completed') ||
          message.contains('already submitted')) {
        return MockTestActionIssue.alreadyCompleted;
      }
      return MockTestActionIssue.validation;
    }
    return MockTestActionIssue.unknown;
  }
}

class MockTestFlowState {
  const MockTestFlowState({
    required this.catalogStatus,
    required this.tests,
    this.targetJlptLevelId,
    this.targetJlptLevelName,
    this.selectedTest,
    this.attempt,
    this.result,
    this.detailedResult,
    this.isStarting = false,
    this.isSubmitting = false,
    this.isResultLoading = false,
    this.isDetailedLoading = false,
    this.actionIssue,
  });

  final MockTestCatalogStatus catalogStatus;
  final List<LiveMockTestSummary> tests;
  final int? targetJlptLevelId;
  final String? targetJlptLevelName;
  final LiveMockTestSummary? selectedTest;
  final LiveMockTestAttempt? attempt;
  final LiveMockTestResult? result;
  final LiveMockTestDetailedResult? detailedResult;
  final bool isStarting;
  final bool isSubmitting;
  final bool isResultLoading;
  final bool isDetailedLoading;
  final MockTestActionIssue? actionIssue;

  bool get hasActiveAttempt => attempt != null && result == null;

  int get answeredQuestionCount => attempt?.answers.length ?? 0;

  LiveMockTestQuestion? get currentQuestion {
    final active = attempt;
    if (active == null || active.questions.isEmpty) return null;
    return active.questions[active.currentQuestionIndex];
  }

  Duration remainingAt(DateTime now) {
    return attempt?.remainingAt(now) ?? Duration.zero;
  }

  MockTestFlowState copyWith({
    MockTestCatalogStatus? catalogStatus,
    List<LiveMockTestSummary>? tests,
    int? targetJlptLevelId,
    String? targetJlptLevelName,
    LiveMockTestSummary? selectedTest,
    LiveMockTestAttempt? attempt,
    LiveMockTestResult? result,
    LiveMockTestDetailedResult? detailedResult,
    bool? isStarting,
    bool? isSubmitting,
    bool? isResultLoading,
    bool? isDetailedLoading,
    MockTestActionIssue? actionIssue,
    bool clearAttempt = false,
    bool clearResult = false,
    bool clearDetailedResult = false,
    bool clearActionIssue = false,
  }) {
    return MockTestFlowState(
      catalogStatus: catalogStatus ?? this.catalogStatus,
      tests: tests ?? this.tests,
      targetJlptLevelId: targetJlptLevelId ?? this.targetJlptLevelId,
      targetJlptLevelName: targetJlptLevelName ?? this.targetJlptLevelName,
      selectedTest: selectedTest ?? this.selectedTest,
      attempt: clearAttempt ? null : attempt ?? this.attempt,
      result: clearResult ? null : result ?? this.result,
      detailedResult: clearDetailedResult
          ? null
          : detailedResult ?? this.detailedResult,
      isStarting: isStarting ?? this.isStarting,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isResultLoading: isResultLoading ?? this.isResultLoading,
      isDetailedLoading: isDetailedLoading ?? this.isDetailedLoading,
      actionIssue: clearActionIssue ? null : actionIssue ?? this.actionIssue,
    );
  }
}
