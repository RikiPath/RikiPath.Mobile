import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/data/api_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';

final learningRepositoryProvider = Provider<LearningRepository>(
  (ref) => ApiLearningRepository(ref.watch(apiClientProvider)),
);

final learningControllerProvider =
    AsyncNotifierProvider<LearningController, LearningSnapshot>(
      LearningController.new,
    );

class LearningController extends AsyncNotifier<LearningSnapshot> {
  @override
  Future<LearningSnapshot> build() async {
    final repository = ref.watch(learningRepositoryProvider);
    final journey = await ref.watch(learnerJourneyControllerProvider.future);
    if (repository is ApiLearningRepository) {
      // The Backend owns CurrentStudyLevel. The locally persisted journey may
      // predate a goal change or belong to an earlier session.
      final profile = await ref
          .watch(userProfileRepositoryProvider)
          .loadProfile();
      final serverLevelId = profile.currentStudyLevelId;
      if (serverLevelId == null || serverLevelId <= 0) {
        return _empty(journey.selectedLevel);
      }
      return repository.loadLearningSnapshot(certificateLevelId: serverLevelId);
    }
    final levelId = journey.selectedLevelId;
    final snapshot = await repository.loadLearningSnapshot(
      certificateLevelId: levelId ?? 1,
    );
    if (snapshot.certificateLevelId != null) return snapshot;

    // Repositories injected by visual/widget tests keep their local fixture
    // journey behavior. The production provider above always returns API data.
    final level = journey.selectedLevel;
    final orderedRouteIds = FixtureLessonRepository.orderedRouteIdsFor(level);
    final locallyCompleted = orderedRouteIds
        .where(journey.isLessonCompleted)
        .length;
    final currentRouteId = orderedRouteIds
        .where((routeId) => !journey.isLessonCompleted(routeId))
        .firstOrNull;
    final displayRouteId = currentRouteId ?? orderedRouteIds.last;
    final lesson = await const FixtureLessonRepository().loadLesson(
      displayRouteId,
    );
    final progress = journey.progressFor(displayRouteId) ?? lesson.progress;
    final currentLesson = snapshot.currentLesson.copyWith(
      routeId: displayRouteId,
      lessonNumber: lesson.lessonNumber,
      title: lesson.title,
      pattern: lesson.focus,
      durationMinutes: lesson.durationMinutes,
      progress: progress.fraction,
    );
    final completedLessons = (snapshot.completedLessons + locallyCompleted)
        .clamp(0, snapshot.totalLessons);
    final chapters = snapshot.chapters
        .map(
          (chapter) => chapter.number == lesson.chapterNumber
              ? chapter.copyWith(
                  completedLessons:
                      (chapter.completedLessons + locallyCompleted).clamp(
                        0,
                        chapter.totalLessons,
                      ),
                )
              : chapter,
        )
        .toList(growable: false);
    return snapshot.copyWith(
      jlptTarget: level,
      hasSelectedLevel: journey.hasSelectedLevel,
      hasCurrentLesson: currentRouteId != null,
      completedLessons: completedLessons,
      overallProgress: completedLessons / snapshot.totalLessons,
      currentLesson: currentLesson,
      chapters: chapters,
    );
  }

  Future<void> retry() async {
    state = const AsyncLoading<LearningSnapshot>();
    state = await AsyncValue.guard(build);
  }

  LearningSnapshot _empty(JlptLevel level) => LearningSnapshot(
    initials: '',
    jlptTarget: level,
    streakDays: 0,
    hasUnreadNotifications: false,
    examDateLabel: '',
    overallProgress: 0,
    completedLessons: 0,
    totalLessons: 0,
    completedChapters: 0,
    totalChapters: 0,
    metrics: const <LearningMetric>[],
    currentLesson: const CurrentLessonSummary(
      routeId: '',
      chapterNumber: 0,
      lessonNumber: 0,
      title: '',
      category: '',
      pattern: '',
      durationMinutes: 0,
      progress: 0,
    ),
    sections: const <LearningSectionSummary>[],
    chapters: const <RoadmapChapter>[],
    skillProgress: const <LearningSkillProgress>[],
    hasSelectedLevel: false,
    hasCurrentLesson: false,
  );
}
