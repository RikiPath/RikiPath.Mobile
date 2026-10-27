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
  });

  final int userId;
  final DateTime generatedAt;
  final String summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final String feasibility;
  final bool isExamDateRealistic;
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
      return lessons[currentIndex + 1];
    }
    return currentIndex < 0 ? lessons.firstOrNull : null;
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
  });

  final int day;
  final String title;
  final String focus;
  final List<RecommendedLesson> lessons;
}

@immutable
class RecommendedLesson {
  const RecommendedLesson({required this.lessonId, required this.title});

  final int lessonId;
  final String title;
  String get routeId => '$lessonId';
}
