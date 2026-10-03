import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/data/persistent_learner_journey_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey.dart';
import 'package:rikipath_mobile/features/learning/domain/learner_journey_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';

final learnerJourneyRepositoryProvider = Provider<LearnerJourneyRepository>(
  (ref) => PersistentLearnerJourneyRepository(
    ref.watch(jsonPreferenceStoreProvider),
  ),
);

final learnerJourneyControllerProvider =
    AsyncNotifierProvider<LearnerJourneyController, LearnerJourneyState>(
      LearnerJourneyController.new,
    );

class LearnerJourneyController extends AsyncNotifier<LearnerJourneyState> {
  LearnerJourneyRepository get _repository =>
      ref.read(learnerJourneyRepositoryProvider);

  @override
  Future<LearnerJourneyState> build() async {
    try {
      return await _repository.load();
    } catch (_) {
      return const LearnerJourneyState(
        persistenceStatus: LocalPersistenceStatus.unavailable,
      );
    }
  }

  Future<void> selectLevel(JlptLevel level) async {
    final current = state.value ?? await future;
    if (current.hasSelectedLevel && current.selectedLevel == level) return;
    await _save(current.copyWith(selectedLevel: level));
  }

  Future<void> setPreferences({
    required JlptLevel level,
    required int dailyStudyMinutes,
  }) async {
    final current = state.value ?? await future;
    return _save(
      current.copyWith(
        selectedLevel: level,
        dailyStudyMinutes: dailyStudyMinutes,
      ),
    );
  }

  Future<void> recordLessonProgress(
    String routeId,
    LessonProgress progress,
  ) async {
    final current = state.value ?? await future;
    final merged = _mergeProgress(current.progressFor(routeId), progress);
    if (_sameProgress(current.progressFor(routeId), merged)) return;
    await _save(
      current.copyWith(
        lessonProgress: <String, LessonProgress>{
          ...current.lessonProgress,
          routeId: merged,
        },
      ),
    );
  }

  Future<void> reset() async {
    try {
      await _repository.reset();
      state = const AsyncData(LearnerJourneyState());
    } catch (_) {
      state = const AsyncData(
        LearnerJourneyState(
          persistenceStatus: LocalPersistenceStatus.unavailable,
        ),
      );
    }
  }

  Future<void> _save(LearnerJourneyState next) async {
    state = AsyncData(next);
    try {
      await _repository.save(next);
    } catch (_) {
      state = AsyncData(
        next.copyWith(persistenceStatus: LocalPersistenceStatus.unavailable),
      );
    }
  }

  LessonProgress _mergeProgress(
    LessonProgress? existing,
    LessonProgress incoming,
  ) {
    if (existing == null) return incoming;
    final completed = existing.isCompleted || incoming.isCompleted;
    return LessonProgress(
      progressPercent: existing.progressPercent > incoming.progressPercent
          ? existing.progressPercent
          : incoming.progressPercent,
      resumePositionSeconds:
          existing.resumePositionSeconds > incoming.resumePositionSeconds
          ? existing.resumePositionSeconds
          : incoming.resumePositionSeconds,
      isCompleted: completed,
      completedAt: completed
          ? existing.completedAt ?? incoming.completedAt
          : null,
    );
  }

  bool _sameProgress(LessonProgress? left, LessonProgress right) {
    return left != null &&
        left.progressPercent == right.progressPercent &&
        left.resumePositionSeconds == right.resumePositionSeconds &&
        left.isCompleted == right.isCompleted &&
        left.completedAt == right.completedAt;
  }
}
