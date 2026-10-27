import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

@immutable
class StandardRoadmap {
  const StandardRoadmap({
    required this.currentStudyLevelId,
    required this.currentStudyLevelName,
    required this.targetJlptLevelId,
    required this.targetJlptLevelName,
    required this.learningMode,
    required this.totalLessons,
    required this.completedLessons,
    required this.nextLessonId,
    required this.lessons,
  });

  final int currentStudyLevelId;
  final String currentStudyLevelName;
  final int? targetJlptLevelId;
  final String? targetJlptLevelName;
  final LearningMode learningMode;
  final int totalLessons;
  final int completedLessons;
  final int? nextLessonId;
  final List<StandardRoadmapLesson> lessons;
}

@immutable
class StandardRoadmapLesson {
  const StandardRoadmapLesson({
    required this.lessonId,
    required this.title,
    required this.sortOrder,
    required this.progressPercent,
    required this.isCompleted,
  });

  final int lessonId;
  final String title;
  final int sortOrder;
  final int progressPercent;
  final bool isCompleted;
}
