import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';

@immutable
class LearnerJourneyState {
  const LearnerJourneyState({
    this.selectedLevel = JlptLevel.n4,
    this.hasSelectedLevel = false,
    this.dailyStudyMinutes = 30,
    this.lessonProgress = const <String, LessonProgress>{},
    this.persistenceStatus = LocalPersistenceStatus.available,
  });

  final JlptLevel selectedLevel;
  final bool hasSelectedLevel;
  final int dailyStudyMinutes;
  final Map<String, LessonProgress> lessonProgress;
  final LocalPersistenceStatus persistenceStatus;

  LessonProgress? progressFor(String routeId) => lessonProgress[routeId];

  bool isLessonCompleted(String routeId) =>
      lessonProgress[routeId]?.isCompleted ?? false;

  LearnerJourneyState copyWith({
    JlptLevel? selectedLevel,
    bool? hasSelectedLevel,
    int? dailyStudyMinutes,
    Map<String, LessonProgress>? lessonProgress,
    LocalPersistenceStatus? persistenceStatus,
  }) {
    return LearnerJourneyState(
      selectedLevel: selectedLevel ?? this.selectedLevel,
      hasSelectedLevel:
          hasSelectedLevel ??
          (selectedLevel != null ? true : this.hasSelectedLevel),
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      lessonProgress: lessonProgress ?? this.lessonProgress,
      persistenceStatus: persistenceStatus ?? this.persistenceStatus,
    );
  }
}
