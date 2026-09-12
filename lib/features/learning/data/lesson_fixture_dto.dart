/// Local visual-development transport model.
///
/// These fields are not backend JSON fields. They describe the approved Stitch
/// fixture before it is mapped into the lesson domain model.
class LessonFixtureDto {
  const LessonFixtureDto({
    required this.routeId,
    required this.title,
    required this.focus,
    required this.level,
    required this.category,
    required this.curriculum,
    required this.chapterNumber,
    required this.lessonNumber,
    required this.durationSeconds,
    required this.objective,
    required this.parts,
    required this.vocabulary,
    required this.detailVocabularyCount,
    required this.videoVocabularyCount,
    required this.relatedGrammar,
    required this.article,
    required this.progress,
    required this.availability,
    required this.noteCount,
    required this.streakDays,
    required this.detailXp,
    required this.completionXp,
    required this.masteryItems,
    this.lockedReason,
    this.prerequisite,
    this.nextLesson,
  });

  final String routeId;
  final String title;
  final String focus;
  final String level;
  final String category;
  final String curriculum;
  final int chapterNumber;
  final int lessonNumber;
  final int durationSeconds;
  final String objective;
  final List<LessonPartFixtureDto> parts;
  final List<LessonVocabularyFixtureDto> vocabulary;
  final int detailVocabularyCount;
  final int videoVocabularyCount;
  final List<LessonRelatedGrammarFixtureDto> relatedGrammar;
  final LessonArticleFixtureDto article;
  final LessonProgressFixtureDto progress;
  final String availability;
  final int noteCount;
  final int streakDays;
  final int detailXp;
  final int completionXp;
  final List<LessonMasteryFixtureDto> masteryItems;
  final String? lockedReason;
  final LessonPrerequisiteFixtureDto? prerequisite;
  final LessonLinkFixtureDto? nextLesson;
}

class LessonProgressFixtureDto {
  const LessonProgressFixtureDto({
    required this.progressPercent,
    required this.resumePositionSeconds,
    required this.isCompleted,
  });

  final int progressPercent;
  final int resumePositionSeconds;
  final bool isCompleted;
}

class LessonPartFixtureDto {
  const LessonPartFixtureDto({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.status,
  });

  final int number;
  final String title;
  final String subtitle;
  final int durationMinutes;
  final String status;
}

class LessonVocabularyFixtureDto {
  const LessonVocabularyFixtureDto({
    required this.word,
    required this.reading,
    required this.meaning,
    required this.isSaved,
  });

  final String word;
  final String reading;
  final String meaning;
  final bool isSaved;
}

class LessonRelatedGrammarFixtureDto {
  const LessonRelatedGrammarFixtureDto({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;
}

class LessonArticleFixtureDto {
  const LessonArticleFixtureDto({
    required this.formulas,
    required this.meaning,
    required this.usageSteps,
    required this.examples,
    required this.importantNotes,
  });

  final List<String> formulas;
  final String meaning;
  final List<String> usageSteps;
  final List<LessonExampleFixtureDto> examples;
  final List<String> importantNotes;
}

class LessonExampleFixtureDto {
  const LessonExampleFixtureDto({
    required this.japanese,
    required this.reading,
    required this.translation,
  });

  final String japanese;
  final String reading;
  final String translation;
}

class LessonPrerequisiteFixtureDto {
  const LessonPrerequisiteFixtureDto({
    required this.routeId,
    required this.lessonNumber,
    required this.title,
    required this.focus,
    required this.progressPercent,
    required this.completedParts,
    required this.totalParts,
    required this.remainingMinutes,
  });

  final String routeId;
  final int lessonNumber;
  final String title;
  final String focus;
  final int progressPercent;
  final int completedParts;
  final int totalParts;
  final int remainingMinutes;
}

class LessonLinkFixtureDto {
  const LessonLinkFixtureDto({
    required this.routeId,
    required this.lessonNumber,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.level,
  });

  final String routeId;
  final int lessonNumber;
  final String title;
  final String subtitle;
  final int durationMinutes;
  final String level;
}

class LessonMasteryFixtureDto {
  const LessonMasteryFixtureDto({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}
