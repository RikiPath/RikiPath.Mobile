import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';

final learningRepositoryProvider = Provider<LearningRepository>(
  (ref) => const FixtureLearningRepository(),
);

final learningControllerProvider =
    AsyncNotifierProvider<LearningController, LearningSnapshot>(
      LearningController.new,
    );

class LearningController extends AsyncNotifier<LearningSnapshot> {
  @override
  Future<LearningSnapshot> build() async {
    final journey = await ref.watch(learnerJourneyControllerProvider.future);
    final fixture = await ref
        .watch(learningRepositoryProvider)
        .loadLearningSnapshot();
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
    final currentLesson = fixture.currentLesson.copyWith(
      routeId: displayRouteId,
      lessonNumber: lesson.lessonNumber,
      title: lesson.title,
      pattern: lesson.focus,
      durationMinutes: lesson.durationMinutes,
      progress: progress.fraction,
    );
    final completedLessons = (fixture.completedLessons + locallyCompleted)
        .clamp(0, fixture.totalLessons);
    final chapters = fixture.chapters
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
    return fixture.copyWith(
      jlptTarget: level,
      hasSelectedLevel: journey.hasSelectedLevel,
      hasCurrentLesson: currentRouteId != null,
      completedLessons: completedLessons,
      overallProgress: completedLessons / fixture.totalLessons,
      currentLesson: currentLesson,
      chapters: chapters,
    );
  }

  Future<void> retry() async {
    state = const AsyncLoading<LearningSnapshot>();
    state = await AsyncValue.guard(build);
  }
}
