import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

@immutable
class LearningSnapshot {
  const LearningSnapshot({
    required this.initials,
    required this.jlptTarget,
    required this.streakDays,
    required this.hasUnreadNotifications,
    required this.examDateLabel,
    required this.overallProgress,
    required this.completedLessons,
    required this.totalLessons,
    required this.completedChapters,
    required this.totalChapters,
    required this.metrics,
    required this.currentLesson,
    required this.sections,
    required this.chapters,
    required this.skillProgress,
  });

  final String initials;
  final JlptLevel jlptTarget;
  final int streakDays;
  final bool hasUnreadNotifications;
  final String examDateLabel;
  final double overallProgress;
  final int completedLessons;
  final int totalLessons;
  final int completedChapters;
  final int totalChapters;
  final List<LearningMetric> metrics;
  final CurrentLessonSummary currentLesson;
  final List<LearningSectionSummary> sections;
  final List<RoadmapChapter> chapters;
  final List<LearningSkillProgress> skillProgress;

  int get overallPercent => (overallProgress * 100).round();
}

@immutable
class LearningMetric {
  const LearningMetric({
    required this.label,
    required this.current,
    required this.total,
  });

  final String label;
  final int current;
  final int total;
}

@immutable
class CurrentLessonSummary {
  const CurrentLessonSummary({
    required this.routeId,
    required this.chapterNumber,
    required this.lessonNumber,
    required this.title,
    required this.category,
    required this.pattern,
    required this.durationMinutes,
    required this.progress,
  });

  /// Frontend route key; it is not assumed to be the backend numeric lesson ID.
  final String routeId;
  final int chapterNumber;
  final int lessonNumber;
  final String title;
  final String category;
  final String pattern;
  final int durationMinutes;
  final double progress;

  int get progressPercent => (progress * 100).round();
}

enum LearningSectionKind { roadmap, lessons, library }

@immutable
class LearningSectionSummary {
  const LearningSectionSummary({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final LearningSectionKind kind;
  final String title;
  final String subtitle;
  final String status;
}

enum RoadmapChapterStatus { completed, current, available, locked }

@immutable
class RoadmapChapter {
  const RoadmapChapter({
    required this.number,
    required this.firstLesson,
    required this.lastLesson,
    required this.title,
    required this.description,
    required this.status,
    required this.completedLessons,
    required this.totalLessons,
    required this.skills,
    this.lockedReason,
  });

  final int number;
  final int firstLesson;
  final int lastLesson;
  final String title;
  final String description;
  final RoadmapChapterStatus status;
  final int completedLessons;
  final int totalLessons;
  final List<ChapterSkillSummary> skills;
  final String? lockedReason;
}

enum ChapterSkillStatus { completed, inProgress, notStarted, locked }

@immutable
class ChapterSkillSummary {
  const ChapterSkillSummary({
    required this.category,
    required this.detail,
    required this.status,
    this.progress,
  });

  final LearningSkillCategory category;
  final String detail;
  final ChapterSkillStatus status;
  final double? progress;
}

enum LearningSkillCategory { vocabulary, kanji, grammar, reading, listening }

extension LearningSkillCategoryLabel on LearningSkillCategory {
  String get label => switch (this) {
    LearningSkillCategory.vocabulary => 'Từ vựng',
    LearningSkillCategory.kanji => 'Kanji',
    LearningSkillCategory.grammar => 'Ngữ pháp',
    LearningSkillCategory.reading => 'Đọc hiểu',
    LearningSkillCategory.listening => 'Nghe hiểu',
  };
}

@immutable
class LearningSkillProgress {
  const LearningSkillProgress({
    required this.category,
    required this.current,
    required this.total,
    required this.unit,
  });

  final LearningSkillCategory category;
  final int current;
  final int total;
  final String unit;

  double get progress => total == 0 ? 0 : current / total;
  int get progressPercent => (progress * 100).round();
}
