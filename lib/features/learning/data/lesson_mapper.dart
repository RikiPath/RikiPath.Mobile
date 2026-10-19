import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/data/lesson_fixture_dto.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';

abstract final class LessonMapper {
  static Lesson fromFixture(LessonFixtureDto dto) {
    return Lesson(
      routeId: dto.routeId,
      remoteLessonId: null,
      title: dto.title,
      focus: dto.focus,
      level: _level(dto.level),
      category: dto.category,
      curriculum: dto.curriculum,
      chapterNumber: dto.chapterNumber,
      lessonNumber: dto.lessonNumber,
      durationSeconds: dto.durationSeconds,
      objective: dto.objective,
      parts: dto.parts.map(_part).toList(growable: false),
      vocabulary: dto.vocabulary.map(_vocabulary).toList(growable: false),
      detailVocabularyCount: dto.detailVocabularyCount,
      videoVocabularyCount: dto.videoVocabularyCount,
      relatedGrammar: dto.relatedGrammar
          .map(_relatedGrammar)
          .toList(growable: false),
      article: _article(dto.article),
      progress: _progress(dto.progress),
      availability: _availability(dto.availability),
      noteCount: dto.noteCount,
      streakDays: dto.streakDays,
      detailXp: dto.detailXp,
      completionXp: dto.completionXp,
      masteryItems: dto.masteryItems.map(_mastery).toList(growable: false),
      mediaSource: const LessonMediaSource.fixture(),
      lockedReason: dto.lockedReason,
      prerequisite: dto.prerequisite == null
          ? null
          : _prerequisite(dto.prerequisite!),
      nextLesson: dto.nextLesson == null ? null : _link(dto.nextLesson!),
    );
  }

  static LessonProgress _progress(LessonProgressFixtureDto dto) {
    return LessonProgress(
      progressPercent: dto.progressPercent,
      resumePositionSeconds: dto.resumePositionSeconds,
      isCompleted: dto.isCompleted,
    );
  }

  static LessonPart _part(LessonPartFixtureDto dto) {
    return LessonPart(
      number: dto.number,
      title: dto.title,
      subtitle: dto.subtitle,
      durationMinutes: dto.durationMinutes,
      status: switch (dto.status) {
        'completed' => LessonPartStatus.completed,
        'current' => LessonPartStatus.current,
        'locked' => LessonPartStatus.locked,
        _ => throw FormatException(
          'Unknown fixture part status: ${dto.status}',
        ),
      },
    );
  }

  static LessonVocabularyItem _vocabulary(LessonVocabularyFixtureDto dto) {
    return LessonVocabularyItem(
      word: dto.word,
      reading: dto.reading,
      meaning: dto.meaning,
      isSaved: dto.isSaved,
    );
  }

  static LessonRelatedGrammar _relatedGrammar(
    LessonRelatedGrammarFixtureDto dto,
  ) {
    return LessonRelatedGrammar(
      number: dto.number,
      title: dto.title,
      description: dto.description,
    );
  }

  static LessonArticle _article(LessonArticleFixtureDto dto) {
    return LessonArticle(
      formulas: List<String>.unmodifiable(dto.formulas),
      meaning: dto.meaning,
      usageSteps: List<String>.unmodifiable(dto.usageSteps),
      examples: dto.examples
          .map(
            (example) => LessonExample(
              japanese: example.japanese,
              reading: example.reading,
              translation: example.translation,
            ),
          )
          .toList(growable: false),
      importantNotes: List<String>.unmodifiable(dto.importantNotes),
    );
  }

  static LessonPrerequisite _prerequisite(LessonPrerequisiteFixtureDto dto) {
    return LessonPrerequisite(
      routeId: dto.routeId,
      lessonNumber: dto.lessonNumber,
      title: dto.title,
      focus: dto.focus,
      progressPercent: dto.progressPercent,
      completedParts: dto.completedParts,
      totalParts: dto.totalParts,
      remainingMinutes: dto.remainingMinutes,
    );
  }

  static LessonLink _link(LessonLinkFixtureDto dto) {
    return LessonLink(
      routeId: dto.routeId,
      lessonNumber: dto.lessonNumber,
      title: dto.title,
      subtitle: dto.subtitle,
      durationMinutes: dto.durationMinutes,
      level: _level(dto.level),
    );
  }

  static LessonMasteryItem _mastery(LessonMasteryFixtureDto dto) {
    return LessonMasteryItem(title: dto.title, description: dto.description);
  }

  static JlptLevel _level(String value) =>
      JlptLevel.tryParse(value) ??
      (throw FormatException('Unsupported learner JLPT level: $value'));

  static LessonAvailability _availability(String value) => switch (value) {
    'available' => LessonAvailability.available,
    'locked' => LessonAvailability.locked,
    _ => throw FormatException('Unknown fixture availability: $value'),
  };
}
