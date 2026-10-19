import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/data/learning_dtos.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';

abstract final class LearningMapper {
  static LearningSnapshot discovery(LearningDiscoveryDto dto) {
    final level = JlptLevel.tryParse(dto.levelCode);
    if (dto.certificateLevelId <= 0 ||
        level == null ||
        dto.totalLessons != dto.lessons.length ||
        dto.completedLessons < 0 ||
        dto.completedLessons > dto.totalLessons ||
        dto.overallProgressPercent < 0 ||
        dto.overallProgressPercent > 100) {
      throw const FormatException('Invalid learning discovery payload.');
    }

    final lessons = dto.lessons.map(summary).toList(growable: false);
    for (final lesson in lessons) {
      if (lesson.lessonId <= 0 ||
          lesson.languageSkillId <= 0 ||
          lesson.sortOrder < 0 ||
          lesson.progressPercent < 0 ||
          lesson.progressPercent > 100 ||
          lesson.resumePositionSeconds < 0) {
        throw const FormatException('Invalid lesson summary payload.');
      }
    }
    final current =
        lessons.where((lesson) => !lesson.isCompleted).firstOrNull ??
        lessons.lastOrNull;
    final skillProgress = _skills(lessons);

    return LearningSnapshot(
      initials: '',
      jlptTarget: level,
      streakDays: 0,
      hasUnreadNotifications: false,
      examDateLabel: '',
      overallProgress: dto.overallProgressPercent / 100,
      completedLessons: dto.completedLessons,
      totalLessons: dto.totalLessons,
      completedChapters: 0,
      totalChapters: 0,
      metrics: skillProgress
          .take(3)
          .map(
            (skill) => LearningMetric(
              label: skill.category.label.toUpperCase(),
              current: skill.current,
              total: skill.total,
            ),
          )
          .toList(growable: false),
      currentLesson: current == null
          ? const CurrentLessonSummary(
              routeId: '',
              chapterNumber: 0,
              lessonNumber: 0,
              title: '',
              category: '',
              pattern: '',
              durationMinutes: 0,
              progress: 0,
            )
          : CurrentLessonSummary(
              routeId: current.routeId,
              chapterNumber: 0,
              lessonNumber: current.sortOrder,
              title: current.title,
              category: current.languageSkillName,
              pattern: current.description ?? '',
              durationMinutes: 0,
              progress: current.progress,
            ),
      sections: const <LearningSectionSummary>[],
      chapters: const <RoadmapChapter>[],
      skillProgress: skillProgress,
      certificateLevelId: dto.certificateLevelId,
      lessons: lessons,
      hasSelectedLevel: true,
      hasCurrentLesson: current != null,
    );
  }

  static LearningLessonSummary summary(LearningLessonSummaryDto dto) =>
      LearningLessonSummary(
        lessonId: dto.lessonId,
        title: dto.title,
        description: dto.description,
        sortOrder: dto.sortOrder,
        languageSkillId: dto.languageSkillId,
        languageSkillName: dto.languageSkillName,
        progressPercent: dto.progressPercent,
        resumePositionSeconds: dto.resumePositionSeconds,
        isCompleted: dto.isCompleted,
        completedAt: dto.completedAt,
      );

  static Lesson lesson(LessonDetailDto dto) {
    final level = JlptLevel.tryParse(dto.levelCode);
    if (dto.lessonId <= 0 ||
        dto.certificateLevelId <= 0 ||
        dto.languageSkillId <= 0 ||
        dto.orderIndex < 0 ||
        dto.progressPercent < 0 ||
        dto.progressPercent > 100 ||
        dto.resumePositionSeconds < 0 ||
        level == null) {
      throw const FormatException('Invalid lesson detail payload.');
    }
    final content = dto.content.trim();
    return Lesson(
      routeId: '${dto.lessonId}',
      remoteLessonId: dto.lessonId,
      title: dto.title,
      focus: content,
      level: level,
      category: dto.languageSkillName,
      curriculum: 'JLPT ${level.label}',
      chapterNumber: 0,
      lessonNumber: dto.orderIndex,
      durationSeconds: 0,
      objective: content,
      parts: const <LessonPart>[],
      vocabulary: const <LessonVocabularyItem>[],
      detailVocabularyCount: 0,
      videoVocabularyCount: 0,
      relatedGrammar: const <LessonRelatedGrammar>[],
      article: LessonArticle(
        formulas: const <String>[],
        meaning: content,
        usageSteps: const <String>[],
        examples: const <LessonExample>[],
        importantNotes: const <String>[],
      ),
      progress: progress(dto),
      availability: LessonAvailability.available,
      noteCount: 0,
      streakDays: 0,
      detailXp: 0,
      completionXp: 0,
      masteryItems: const <LessonMasteryItem>[],
      mediaSource: const LessonMediaSource.none(),
    );
  }

  static LessonProgress progress(LessonDetailDto dto) => LessonProgress(
    progressPercent: dto.progressPercent,
    resumePositionSeconds: dto.resumePositionSeconds,
    isCompleted: dto.isCompleted,
    completedAt: dto.completedAt,
  );

  static List<LearningSkillProgress> _skills(
    List<LearningLessonSummary> lessons,
  ) {
    final grouped = <LearningSkillCategory, List<LearningLessonSummary>>{};
    for (final lesson in lessons) {
      final category = _category(lesson.languageSkillName);
      if (category == null) continue;
      grouped
          .putIfAbsent(category, () => <LearningLessonSummary>[])
          .add(lesson);
    }
    return [
      for (final category in LearningSkillCategory.values)
        if (grouped[category] case final items?)
          LearningSkillProgress(
            category: category,
            current: items.where((item) => item.isCompleted).length,
            total: items.length,
            unit: 'bài',
          ),
    ];
  }

  static LearningSkillCategory? _category(String name) =>
      switch (name.trim().toLowerCase()) {
        'vocabulary' => LearningSkillCategory.vocabulary,
        'kanji' => LearningSkillCategory.kanji,
        'grammar' => LearningSkillCategory.grammar,
        'reading' => LearningSkillCategory.reading,
        'listening' => LearningSkillCategory.listening,
        _ => null,
      };
}
