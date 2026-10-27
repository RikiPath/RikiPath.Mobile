import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';
import 'package:rikipath_mobile/features/placement_test/data/api_placement_test_repository.dart';
import 'package:rikipath_mobile/features/placement_test/data/placement_test_draft_store.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

final placementTestRepositoryProvider = Provider<PlacementTestRepository>((
  ref,
) {
  return ApiPlacementTestRepository(ref.watch(apiClientProvider));
});

final placementTestStatusProvider = FutureProvider.autoDispose<PlacementTestStatus>(
  (ref) => ref.watch(placementTestRepositoryProvider).loadStatus(),
);

final placementTestElapsedProvider = Provider<Duration Function()>((ref) {
  final stopwatch = Stopwatch()..start();
  ref.onDispose(stopwatch.stop);
  return () => stopwatch.elapsed;
});

final placementTestDraftNowProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

final placementTestControllerProvider =
    AsyncNotifierProvider<PlacementTestController, PlacementTestFlowState>(
      PlacementTestController.new,
      retry: (_, _) => null,
    );

enum PlacementTestActionIssue {
  validation,
  expired,
  bankNotReady,
  invalidAnswer,
  notCompleted,
  alreadyCompleted,
  conflict,
  notFound,
  networkUncertain,
  localPersistence,
  unknown,
}

enum PlacementTestSubmitOutcome { success, recoveredCompleted, failed }

enum PlacementRecommendationPhase {
  idle,
  applyingGoal,
  generatingLearningPath,
  refreshingLearningPath,
}

class PlacementTestController extends AsyncNotifier<PlacementTestFlowState> {
  PlacementTestRepository get _repository =>
      ref.read(placementTestRepositoryProvider);
  PlacementTestDraftStore get _draftStore =>
      ref.read(placementTestDraftStoreProvider);
  Duration Function() get _elapsed => ref.read(placementTestElapsedProvider);

  int? _userId;
  Future<void> _draftWrites = Future<void>.value();
  bool _goalApplied = false;
  bool _pathGenerated = false;
  bool _transitionAttempted = false;

  @override
  Future<PlacementTestFlowState> build() async {
    final session = ref.watch(authSessionControllerProvider);
    _userId = session.currentUserId;
    void handleIdentityChange() {
      if (session.currentUserId != _userId ||
          session.value != AuthSessionState.authenticated) {
        ref.invalidateSelf();
      }
    }

    session.addListener(handleIdentityChange);
    ref.onDispose(() => session.removeListener(handleIdentityChange));
    return _loadInitial();
  }

  Future<PlacementTestFlowState> _loadInitial() async {
    final status = await _repository.loadStatus();
    if (status.hasActiveAttempt) {
      PlacementTestAttempt? active;
      try {
        active = await _repository.loadActiveAttempt();
      } catch (error) {
        if (_classify(error) != PlacementTestActionIssue.notFound) rethrow;
        await _clearDraftForAttempt(status.activeAttemptId);
        return PlacementTestFlowState(
          status: status.copyWith(
            hasActiveAttempt: false,
            clearActiveAttempt: true,
          ),
          actionIssue: PlacementTestActionIssue.notFound,
          actionRetryable: _retryable(error),
        );
      }
      if (active == null) {
        await _clearDraftForAttempt(status.activeAttemptId);
        return PlacementTestFlowState(
          status: status.copyWith(
            hasActiveAttempt: false,
            clearActiveAttempt: true,
          ),
          actionIssue: PlacementTestActionIssue.expired,
        );
      }
      if (status.activeAttemptId != null &&
          status.activeAttemptId != active.id) {
        throw const FormatException(
          'Placement Test status and active snapshot do not match.',
        );
      }
      final synchronized = _synchronizeClock(active);
      if (_isExpired(synchronized)) {
        await _clearDraftForAttempt(synchronized.id);
        return PlacementTestFlowState(
          status: status.copyWith(
            hasActiveAttempt: false,
            clearActiveAttempt: true,
          ),
          actionIssue: PlacementTestActionIssue.expired,
          actionRetryable: true,
        );
      }
      final restored = await _restoreDraft(synchronized);
      return PlacementTestFlowState(status: status, attempt: restored);
    }

    final completedId = status.latestCompletedAttemptId;
    if (status.hasCompletedPlacementTest && completedId != null) {
      try {
        final userId = _userId;
        if (userId != null &&
            await _draftStore.isResultDismissed(
              userId: userId,
              attemptId: completedId,
            )) {
          await _clearDraftForAttempt(completedId);
          return PlacementTestFlowState(status: status);
        }
        final alreadyApplied = await _hasAppliedCompletedResult(status);
        if (alreadyApplied) {
          return PlacementTestFlowState(
            status: status,
            hasAppliedCompletedResult: true,
          );
        }
        final result = await _repository.loadResult(completedId);
        _validateRecoveredResult(result, completedId);
        _goalApplied =
            status.targetJlptLevelId == result.recommendedTargetJlptLevelId;
        return PlacementTestFlowState(status: status, result: result);
      } catch (error) {
        final issue = _classify(error);
        if (issue == PlacementTestActionIssue.notFound) {
          await _clearDraftForAttempt(completedId);
        }
        return PlacementTestFlowState(
          status: status,
          actionIssue: issue,
          actionRetryable: _retryable(error),
        );
      }
    }
    return PlacementTestFlowState(
      status: status,
      hasAppliedCompletedResult:
          status.hasCompletedPlacementTest &&
          status.isReadyForLearningPath &&
          status.targetJlptLevelId != null,
    );
  }

  Future<bool> _hasAppliedCompletedResult(PlacementTestStatus status) async {
    final targetLevelId = status.targetJlptLevelId;
    if (targetLevelId == null) {
      return false;
    }
    if (status.recommendedTargetJlptLevelId != null &&
        targetLevelId != status.recommendedTargetJlptLevelId) {
      await _clearDraftForAttempt(status.latestCompletedAttemptId);
      return true;
    }
    if (status.isReadyForLearningPath) {
      final latest = await _loadLatestOrNull();
      if (latest != null) {
        final submittedAt = status.latestSubmittedAt;
        final applied =
            submittedAt == null || !latest.generatedAt.isBefore(submittedAt);
        if (applied) {
          await _clearDraftForAttempt(status.latestCompletedAttemptId);
          return true;
        }
      }
    }
    if (status.targetExamDate != null) {
      await _clearDraftForAttempt(status.latestCompletedAttemptId);
      return true;
    }
    return false;
  }

  Future<void> refreshStatus() async {
    _goalApplied = false;
    _pathGenerated = false;
    _transitionAttempted = false;
    state = const AsyncLoading<PlacementTestFlowState>();
    state = await AsyncValue.guard(_loadInitial);
  }

  Future<bool> startTest() async {
    final current = state.value;
    if (current == null || current.isStarting || current.isSubmitting) {
      return false;
    }

    state = AsyncData(
      current.copyWith(
        isStarting: true,
        clearAttempt: true,
        clearResult: true,
        clearActionIssue: true,
      ),
    );
    try {
      final started = await _repository.start();
      if (started.questions.isEmpty) {
        throw const FormatException('Invalid Placement Test start response.');
      }
      final synchronized = _synchronizeClock(started);
      if (_isExpired(synchronized)) {
        await _clearDraftForAttempt(synchronized.id);
        throw const ConflictError(
          errorCode: 'PLACEMENT_ATTEMPT_EXPIRED',
          retryable: true,
        );
      }
      final userId = _userId;
      if (userId != null) {
        await _draftStore.clearDismissedAttemptId(userId: userId);
      }
      final attempt = await _restoreDraft(synchronized);
      final activeStatus = current.status.copyWith(
        hasActiveAttempt: true,
        activeAttemptId: attempt.id,
        activeAttemptExpiresAt: attempt.expiresAt,
      );
      state = AsyncData(
        state.requireValue.copyWith(
          status: activeStatus,
          attempt: attempt,
          isStarting: false,
          clearResult: true,
          clearActionIssue: true,
        ),
      );
      return true;
    } catch (error) {
      state = AsyncData(
        state.requireValue.copyWith(
          isStarting: false,
          actionIssue: _classify(error),
          actionRetryable: _retryable(error),
        ),
      );
      return false;
    }
  }

  Future<bool> showQuestion(int index) async {
    final current = state.value;
    final attempt = current?.attempt;
    if (current == null || attempt == null || current.isSubmitting) {
      return false;
    }
    if (_isExpired(attempt)) {
      _publishExpired(current);
      return false;
    }
    final bounded = index.clamp(0, attempt.questions.length - 1);
    final updated = attempt.copyWith(currentQuestionIndex: bounded);
    state = AsyncData(current.copyWith(attempt: updated));
    return _persistDraft(updated);
  }

  Future<bool> selectAnswer(int questionId, int optionId) async {
    final current = state.value;
    final attempt = current?.attempt;
    if (current == null ||
        attempt == null ||
        current.isSubmitting ||
        current.result != null) {
      return false;
    }
    if (_isExpired(attempt)) {
      _publishExpired(current);
      return false;
    }
    final question = attempt.questions
        .where((candidate) => candidate.id == questionId)
        .firstOrNull;
    if (question == null ||
        !question.options.any((option) => option.id == optionId)) {
      return false;
    }

    final updated = attempt.copyWith(
      answers: <int, int>{...attempt.answers, questionId: optionId},
    );
    state = AsyncData(
      current.copyWith(attempt: updated, clearActionIssue: true),
    );
    return _persistDraft(updated);
  }

  void expireIfNeeded() {
    final current = state.value;
    final attempt = current?.attempt;
    if (current != null && attempt != null && _isExpired(attempt)) {
      _publishExpired(current);
    }
  }

  List<PlacementTestAnswerSubmission> buildSubmission() {
    final attempt = state.value?.attempt;
    if (attempt == null) return const <PlacementTestAnswerSubmission>[];
    return attempt.questions
        .map(
          (question) => PlacementTestAnswerSubmission(
            questionId: question.id,
            selectedOptionId: attempt.answers[question.id],
          ),
        )
        .toList(growable: false);
  }

  Future<PlacementTestSubmitOutcome> submit() async {
    final current = state.value;
    final attempt = current?.attempt;
    if (current == null ||
        attempt == null ||
        current.isSubmitting ||
        current.result != null) {
      return PlacementTestSubmitOutcome.failed;
    }
    if (_isExpired(attempt)) {
      _publishExpired(current);
      return PlacementTestSubmitOutcome.failed;
    }

    final answers = buildSubmission();
    state = AsyncData(
      current.copyWith(isSubmitting: true, clearActionIssue: true),
    );
    try {
      final result = await _repository.submit(attempt.id, answers);
      _publishResult(result);
      return PlacementTestSubmitOutcome.success;
    } catch (error) {
      final issue = _classify(error);
      if (issue == PlacementTestActionIssue.alreadyCompleted ||
          issue == PlacementTestActionIssue.conflict ||
          issue == PlacementTestActionIssue.networkUncertain) {
        final recovered = await _recoverCompletedResult(attempt.id);
        if (recovered) return PlacementTestSubmitOutcome.recoveredCompleted;
      }
      if (issue == PlacementTestActionIssue.expired) {
        _publishExpired(current);
        return PlacementTestSubmitOutcome.failed;
      }
      if (issue == PlacementTestActionIssue.notFound) {
        await _clearDraftForAttempt(attempt.id);
        state = AsyncData(
          current.copyWith(
            status: current.status.copyWith(
              hasActiveAttempt: false,
              clearActiveAttempt: true,
            ),
            clearAttempt: true,
            isSubmitting: false,
            actionIssue: issue,
            actionRetryable: _retryable(error),
          ),
        );
        return PlacementTestSubmitOutcome.failed;
      }
      state = AsyncData(
        state.requireValue.copyWith(
          isSubmitting: false,
          actionIssue: issue,
          actionRetryable: _retryable(error),
        ),
      );
      return PlacementTestSubmitOutcome.failed;
    }
  }

  Future<bool> applyRecommendation() async {
    final current = state.value;
    final result = current?.result;
    if (current == null || result == null || current.isApplyingRecommendation) {
      return false;
    }

    final wasAttempted = _transitionAttempted;
    _transitionAttempted = true;
    RecommendedLearningPath? refreshedPath;
    try {
      var workingStatus = current.status;
      final goalWasAlreadyApplied =
          workingStatus.targetJlptLevelId ==
          result.recommendedTargetJlptLevelId;
      if (!_goalApplied) {
        state = AsyncData(
          state.requireValue.copyWith(
            recommendationPhase: PlacementRecommendationPhase.applyingGoal,
            clearActionIssue: true,
          ),
        );
        if (!goalWasAlreadyApplied) {
          final profile = await _applyGoal(workingStatus, result);
          workingStatus = workingStatus.copyWith(
            targetJlptLevelId: profile.targetJlptLevelId,
            targetJlptLevelName: profile.targetJlptLevelName,
            dailyStudyMinutes: profile.dailyStudyMinutes,
            targetExamDate: profile.targetExamDate,
            isReadyForLearningPath:
                profile.targetJlptLevelId != null &&
                profile.dailyStudyMinutes > 0,
          );
          state = AsyncData(state.requireValue.copyWith(status: workingStatus));
        }
        _goalApplied = true;
      }

      state = AsyncData(
        state.requireValue.copyWith(
          recommendationPhase:
              PlacementRecommendationPhase.generatingLearningPath,
        ),
      );
      if (!_pathGenerated && (wasAttempted || goalWasAlreadyApplied)) {
        refreshedPath = await _loadLatestOrNull();
        if (_isPathForResult(refreshedPath, result)) {
          _pathGenerated = true;
        } else {
          refreshedPath = null;
        }
      }
      if (!_pathGenerated) {
        await ref.read(learningPathRepositoryProvider).generate();
        _pathGenerated = true;
      }

      state = AsyncData(
        state.requireValue.copyWith(
          recommendationPhase:
              PlacementRecommendationPhase.refreshingLearningPath,
        ),
      );
      refreshedPath ??= await ref
          .read(learningPathRepositoryProvider)
          .loadLatest();
      if (refreshedPath == null) {
        throw const UnknownError(
          message: 'The generated learning path could not be refreshed.',
        );
      }

      await _draftWrites;
      await _clearDraftForAttempt(result.attemptId);
      final userId = _userId;
      if (userId != null) {
        await _draftStore.clearDismissedAttemptId(userId: userId);
      }

      final appliedLevelId =
          workingStatus.targetJlptLevelId ??
          result.recommendedTargetJlptLevelId;
      final appliedLevelName =
          workingStatus.targetJlptLevelName ??
          result.recommendedTargetJlptLevelName;
      final appliedDailyMinutes = workingStatus.dailyStudyMinutes > 0
          ? workingStatus.dailyStudyMinutes
          : 30;
      final targetItem = await _resolveCatalogItem(
        levelId: appliedLevelId,
        levelName: appliedLevelName,
      );
      if (targetItem != null) {
        await ref
            .read(learnerJourneyControllerProvider.notifier)
            .setCatalogPreferences(
              item: targetItem,
              dailyStudyMinutes: appliedDailyMinutes,
            );
      }
      ref.invalidate(learningControllerProvider);
      ref.invalidate(userProfileControllerProvider);
      ref.invalidate(learningPathControllerProvider);
      state = AsyncData(
        state.requireValue.copyWith(
          recommendationPhase: PlacementRecommendationPhase.idle,
          recommendationApplied: true,
          hasAppliedCompletedResult: true,
          clearActionIssue: true,
        ),
      );
      return true;
    } catch (error) {
      state = AsyncData(
        state.requireValue.copyWith(
          recommendationPhase: PlacementRecommendationPhase.idle,
          actionIssue: _classify(error),
          actionRetryable: _retryable(error),
        ),
      );
      return false;
    }
  }

  Future<JlptLevelCatalogItem?> _resolveCatalogItem({
    required int levelId,
    required String levelName,
  }) async {
    final cached = ref.read(jlptCatalogControllerProvider).value;
    if (cached != null) {
      for (final item in cached) {
        if (item.id == levelId) return item;
      }
    }
    try {
      final catalog = await ref
          .read(jlptCatalogRepositoryProvider)
          .loadLevels();
      for (final item in catalog) {
        if (item.id == levelId) return item;
      }
      final parsedFromName = JlptLevel.tryParse(levelName);
      if (parsedFromName != null) {
        for (final item in catalog) {
          if (item.level == parsedFromName) {
            return JlptLevelCatalogItem(
              id: levelId,
              code: item.code,
              level: item.level,
              sortOrder: item.sortOrder,
            );
          }
        }
      }
    } catch (_) {
      // Fall back to parsed JLPT level below when catalog is unavailable.
    }
    final fallbackLevel = JlptLevel.tryParse(levelName);
    if (fallbackLevel == null) return null;
    return JlptLevelCatalogItem(
      id: levelId,
      code: fallbackLevel.label,
      level: fallbackLevel,
      sortOrder: fallbackLevel.index + 1,
    );
  }

  Future<UserProfile> _applyGoal(
    PlacementTestStatus status,
    PlacementTestResult result,
  ) {
    final repository = ref.read(userProfileRepositoryProvider);
    final dailyMinutes = status.dailyStudyMinutes > 0
        ? status.dailyStudyMinutes
        : 30;
    final examDate = status.targetExamDate;
    if (examDate != null && repository is TargetExamDateProfileRepository) {
      return (repository as TargetExamDateProfileRepository)
          .setJlptGoalWithExamDate(
            targetJlptLevelId: result.recommendedTargetJlptLevelId,
            dailyStudyMinutes: dailyMinutes,
            targetExamDate: examDate,
          );
    }
    return repository.setJlptGoal(
      targetJlptLevelId: result.recommendedTargetJlptLevelId,
      dailyStudyMinutes: dailyMinutes,
    );
  }

  Future<void> dismissResult({int? attemptId}) async {
    final current = state.value;
    final targetAttemptId =
        attemptId ??
        current?.result?.attemptId ??
        current?.status.latestCompletedAttemptId;
    final userId =
        _userId ?? ref.read(authSessionControllerProvider).currentUserId;
    if (userId != null && targetAttemptId != null) {
      await _draftStore.saveDismissedAttemptId(
        userId: userId,
        attemptId: targetAttemptId,
      );
      await _clearDraftForAttempt(targetAttemptId);
    }
    if (current != null &&
        (current.result != null || current.actionIssue != null)) {
      state = AsyncData(
        current.copyWith(clearResult: true, clearActionIssue: true),
      );
    }
  }

  void prepareRetake() {
    final current = state.value;
    if (current == null || current.isSubmitting) return;
    state = AsyncData(
      current.copyWith(
        clearAttempt: true,
        clearResult: true,
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

  void _publishResult(PlacementTestResult result) {
    final current = state.requireValue;
    final attempt = current.attempt;
    if (attempt == null || result.attemptId != attempt.id) {
      throw const FormatException(
        'Placement Test result does not match the active attempt.',
      );
    }
    _validateRecoveredResult(result, attempt.id);
    final userId = _userId;
    if (userId != null) {
      unawaited(_draftStore.clearDismissedAttemptId(userId: userId));
    }
    final updatedStatus = current.status.copyWith(
      hasActiveAttempt: false,
      clearActiveAttempt: true,
      hasCompletedPlacementTest: true,
      latestCompletedAttemptId: result.attemptId,
      latestSubmittedAt: result.submittedAt,
      latestScorePercent: result.totalScore,
      assessedJlptLevelId: result.assessedJlptLevelId,
      assessedJlptLevelName: result.assessedJlptLevelName,
      recommendedTargetJlptLevelId: result.recommendedTargetJlptLevelId,
      recommendedTargetJlptLevelName: result.recommendedTargetJlptLevelName,
      isReadyForLearningPath: false,
    );
    state = AsyncData(
      current.copyWith(
        status: updatedStatus,
        result: result,
        isSubmitting: false,
        hasAppliedCompletedResult: false,
        clearActionIssue: true,
      ),
    );
  }

  void _validateRecoveredResult(PlacementTestResult result, int attemptId) {
    if (result.attemptId != attemptId ||
        result.attemptType != 'placement' ||
        result.status != MockTestAttemptStatus.completed) {
      throw const FormatException(
        'Placement Test result is not the requested completed placement attempt.',
      );
    }
  }

  PlacementTestAttempt _synchronizeClock(PlacementTestAttempt attempt) {
    return attempt.copyWith(serverElapsedAtSync: _elapsed());
  }

  bool _isExpired(PlacementTestAttempt attempt) =>
      attempt.remainingAtElapsed(_elapsed()) == Duration.zero;

  void _publishExpired(PlacementTestFlowState current) {
    final attemptId = current.attempt?.id ?? current.status.activeAttemptId;
    unawaited(_clearDraftForAttempt(attemptId));
    state = AsyncData(
      current.copyWith(
        status: current.status.copyWith(
          hasActiveAttempt: false,
          clearActiveAttempt: true,
        ),
        clearAttempt: true,
        isSubmitting: false,
        actionIssue: PlacementTestActionIssue.expired,
        actionRetryable: true,
      ),
    );
  }

  Future<void> _clearDraftForAttempt(int? attemptId) {
    final userId = _userId;
    if (userId == null || attemptId == null) {
      return Future<void>.value();
    }
    final immediate = _draftStore.clear(userId: userId, attemptId: attemptId);
    _draftWrites = _draftWrites
        .then((_) => _draftStore.clear(userId: userId, attemptId: attemptId))
        .catchError((_) {});
    return immediate;
  }

  Future<PlacementTestAttempt> _restoreDraft(
    PlacementTestAttempt attempt,
  ) async {
    final userId = _userId;
    if (userId == null) return attempt;
    final draft = await _draftStore.load(userId: userId, attemptId: attempt.id);
    if (draft == null) return attempt;
    final isIndexValid =
        draft.currentQuestionIndex >= 0 &&
        draft.currentQuestionIndex < attempt.questions.length;
    final selectionsAreValid = draft.selectedOptionIdsByQuestionId.entries
        .every((entry) {
          final question = attempt.questions
              .where((candidate) => candidate.id == entry.key)
              .firstOrNull;
          return question != null &&
              question.options.any((option) => option.id == entry.value);
        });
    if (!isIndexValid || !selectionsAreValid) {
      await _draftStore.clear(userId: userId, attemptId: attempt.id);
      return attempt;
    }
    return attempt.copyWith(
      currentQuestionIndex: draft.currentQuestionIndex,
      answers: draft.selectedOptionIdsByQuestionId,
    );
  }

  Future<bool> _persistDraft(PlacementTestAttempt attempt) async {
    final userId = _userId;
    if (userId == null) return true;
    final draft = PlacementTestDraft(
      schemaVersion: PlacementTestDraft.currentSchemaVersion,
      userId: userId,
      attemptId: attempt.id,
      currentQuestionIndex: attempt.currentQuestionIndex,
      selectedOptionIdsByQuestionId: attempt.answers,
      updatedAt: ref.read(placementTestDraftNowProvider)(),
    );
    final pending = _draftWrites.then((_) => _draftStore.save(draft));
    _draftWrites = pending.catchError((_) {});
    try {
      await pending;
      return true;
    } catch (_) {
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            actionIssue: PlacementTestActionIssue.localPersistence,
            actionRetryable: true,
          ),
        );
      }
      return false;
    }
  }

  Future<RecommendedLearningPath?> _loadLatestOrNull() async {
    try {
      return await ref.read(learningPathRepositoryProvider).loadLatest();
    } on NotFoundError {
      return null;
    }
  }

  bool _isPathForResult(
    RecommendedLearningPath? path,
    PlacementTestResult result,
  ) {
    if (path == null) return false;
    final submittedAt = result.submittedAt;
    return submittedAt == null || !path.generatedAt.isBefore(submittedAt);
  }

  PlacementTestActionIssue _classify(Object error) {
    final code = error is ApiError ? error.errorCode : null;
    switch (code) {
      case 'PLACEMENT_BANK_NOT_READY':
        return PlacementTestActionIssue.bankNotReady;
      case 'PLACEMENT_ATTEMPT_EXPIRED':
        return PlacementTestActionIssue.expired;
      case 'PLACEMENT_ANSWER_INVALID':
        return PlacementTestActionIssue.invalidAnswer;
      case 'PLACEMENT_ATTEMPT_NOT_READY':
      case 'PLACEMENT_ATTEMPT_NOT_COMPLETED':
        return PlacementTestActionIssue.notCompleted;
      case 'PLACEMENT_ATTEMPT_NOT_FOUND':
        return PlacementTestActionIssue.notFound;
    }
    if (error is NetworkError) return PlacementTestActionIssue.networkUncertain;
    if (error is ConflictError) return PlacementTestActionIssue.conflict;
    if (error is NotFoundError) return PlacementTestActionIssue.notFound;
    if (error is ValidationError) {
      final message = error.message.toLowerCase();
      if (message.contains('hết thời gian') || message.contains('expired')) {
        return PlacementTestActionIssue.expired;
      }
      if (message.contains('đã được nộp') ||
          message.contains('already completed') ||
          message.contains('already submitted')) {
        return PlacementTestActionIssue.alreadyCompleted;
      }
      return PlacementTestActionIssue.validation;
    }
    return PlacementTestActionIssue.unknown;
  }

  bool _retryable(Object error) =>
      error is ApiError ? error.retryable ?? error is NetworkError : true;
}

class PlacementTestFlowState {
  const PlacementTestFlowState({
    required this.status,
    this.attempt,
    this.result,
    this.isStarting = false,
    this.isSubmitting = false,
    this.actionIssue,
    this.actionRetryable = false,
    this.recommendationPhase = PlacementRecommendationPhase.idle,
    this.recommendationApplied = false,
    this.hasAppliedCompletedResult = false,
  });

  final PlacementTestStatus status;
  final PlacementTestAttempt? attempt;
  final PlacementTestResult? result;
  final bool isStarting;
  final bool isSubmitting;
  final PlacementTestActionIssue? actionIssue;
  final bool actionRetryable;
  final PlacementRecommendationPhase recommendationPhase;
  final bool recommendationApplied;
  final bool hasAppliedCompletedResult;

  bool get hasActiveAttempt => attempt != null && result == null;
  bool get hasCompletedPlacementPath =>
      recommendationApplied ||
      hasAppliedCompletedResult ||
      (status.hasCompletedPlacementTest &&
          status.isReadyForLearningPath &&
          status.latestCompletedAttemptId == null &&
          !hasActiveAttempt &&
          result == null &&
          !shouldRetryResultRecovery);
  bool get shouldRetryResultRecovery =>
      status.hasCompletedPlacementTest &&
      status.latestCompletedAttemptId != null &&
      result == null &&
      actionIssue != null &&
      actionIssue != PlacementTestActionIssue.notFound;
  bool get isApplyingRecommendation =>
      recommendationPhase != PlacementRecommendationPhase.idle;
  int get answeredQuestionCount => attempt?.answers.length ?? 0;

  PlacementTestQuestion? get currentQuestion {
    final active = attempt;
    if (active == null || active.questions.isEmpty) return null;
    return active.questions[active.currentQuestionIndex];
  }

  Duration remainingAtElapsed(Duration elapsed) {
    return attempt?.remainingAtElapsed(elapsed) ?? Duration.zero;
  }

  PlacementTestFlowState copyWith({
    PlacementTestStatus? status,
    PlacementTestAttempt? attempt,
    PlacementTestResult? result,
    bool? isStarting,
    bool? isSubmitting,
    PlacementTestActionIssue? actionIssue,
    bool? actionRetryable,
    PlacementRecommendationPhase? recommendationPhase,
    bool? recommendationApplied,
    bool? hasAppliedCompletedResult,
    bool clearAttempt = false,
    bool clearResult = false,
    bool clearActionIssue = false,
  }) {
    return PlacementTestFlowState(
      status: status ?? this.status,
      attempt: clearAttempt ? null : attempt ?? this.attempt,
      result: clearResult ? null : result ?? this.result,
      isStarting: isStarting ?? this.isStarting,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      actionIssue: clearActionIssue ? null : actionIssue ?? this.actionIssue,
      actionRetryable: clearActionIssue
          ? false
          : actionRetryable ?? this.actionRetryable,
      recommendationPhase: recommendationPhase ?? this.recommendationPhase,
      recommendationApplied:
          recommendationApplied ?? this.recommendationApplied,
      hasAppliedCompletedResult:
          hasAppliedCompletedResult ?? this.hasAppliedCompletedResult,
    );
  }
}
