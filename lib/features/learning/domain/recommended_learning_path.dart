import 'package:flutter/foundation.dart';

@immutable
class RecommendedLearningPath {
  const RecommendedLearningPath({
    required this.userId,
    required this.generatedAt,
    required this.summary,
    required this.strengths,
    required this.weaknesses,
    required this.feasibility,
    required this.isExamDateRealistic,
    required this.recommendedStudyDays,
    required this.focusTopics,
    required this.dailySchedules,
    this.suggestedExamDate,
    this.pathId,
    this.version,
    this.status,
    this.startingJlptLevelId,
    this.targetJlptLevelId,
    this.baseActivePathId,
    this.previewExpiresAt,
    this.confirmedAt,
    this.horizon,
    this.planDurationDays,
    this.targetExamDate,
    this.daysUntilExam,
    this.hasTargetExamDate,
  });

  final int userId;
  final DateTime generatedAt;
  final String summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final String feasibility;
  final bool? isExamDateRealistic;
  final int recommendedStudyDays;
  final DateTime? suggestedExamDate;
  final int? pathId;
  final int? version;
  final LearningPathStatus? status;
  final int? startingJlptLevelId;
  final int? targetJlptLevelId;
  final int? baseActivePathId;
  final DateTime? previewExpiresAt;
  final DateTime? confirmedAt;
  final String? horizon;
  final int? planDurationDays;
  final DateTime? targetExamDate;
  final int? daysUntilExam;
  final bool? hasTargetExamDate;
  final List<String> focusTopics;
  final List<RecommendedLearningDay> dailySchedules;

  List<RecommendedLesson> get orderedLessons => dailySchedules
      .expand((schedule) => schedule.lessons)
      .toList(growable: false);

  RecommendedLesson? recommendationAfter(int lessonId) {
    final lessons = orderedLessons;
    final currentIndex = lessons.indexWhere(
      (item) => item.lessonId == lessonId,
    );
    if (currentIndex >= 0 && currentIndex + 1 < lessons.length) {
      final next = lessons[currentIndex + 1];
      final nextDay = dailySchedules
          .where(
            (day) => day.lessons.any((item) => item.lessonId == next.lessonId),
          )
          .firstOrNull;
      if (nextDay?.canStart == false &&
          nextDay?.isStarted != true &&
          nextDay?.isCompleted != true) {
        return null;
      }
      return next;
    }
    return null;
  }
}

enum LearningPathStatus { draft, active, superseded, cancelled }

@immutable
class RecommendedLearningDay {
  const RecommendedLearningDay({
    required this.day,
    required this.title,
    required this.focus,
    required this.lessons,
    this.canStart,
    this.isStarted,
    this.isCompleted,
    this.startedAt,
    this.completedAt,
  });

  final int day;
  final String title;
  final String focus;
  final List<RecommendedLesson> lessons;
  final bool? canStart;
  final bool? isStarted;
  final bool? isCompleted;
  final DateTime? startedAt;
  final DateTime? completedAt;
}

@immutable
class RecommendedLesson {
  const RecommendedLesson({required this.lessonId, required this.title});

  final int lessonId;
  final String title;
  String get routeId => '$lessonId';
}
