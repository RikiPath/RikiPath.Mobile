import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

enum LessonAvailability { available, locked }

enum LessonPartStatus { completed, current, locked }

enum LessonMediaSourceType { none, fixture, network }

@immutable
class LessonMediaSource {
  const LessonMediaSource.none()
    : type = LessonMediaSourceType.none,
      uri = null;

  const LessonMediaSource.fixture()
    : type = LessonMediaSourceType.fixture,
      uri = null;

  const LessonMediaSource.network(this.uri)
    : type = LessonMediaSourceType.network;

  final LessonMediaSourceType type;
  final Uri? uri;
}

@immutable
class Lesson {
  const Lesson({
    required this.routeId,
    required this.remoteLessonId,
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
    required this.mediaSource,
    this.lockedReason,
    this.prerequisite,
    this.nextLesson,
  });

  final String routeId;

  /// Null until a contract-derived backend lesson ID is available.
  final int? remoteLessonId;
  final String title;
  final String focus;
  final JlptLevel level;
  final String category;
  final String curriculum;
  final int chapterNumber;
  final int lessonNumber;
  final int durationSeconds;
  final String objective;
  final List<LessonPart> parts;
  final List<LessonVocabularyItem> vocabulary;
  final int detailVocabularyCount;
  final int videoVocabularyCount;
  final List<LessonRelatedGrammar> relatedGrammar;
  final LessonArticle article;
  final LessonProgress progress;
  final LessonAvailability availability;
  final int noteCount;
  final int streakDays;
  final int detailXp;
  final int completionXp;
  final List<LessonMasteryItem> masteryItems;
  final LessonMediaSource mediaSource;
  final String? lockedReason;
  final LessonPrerequisite? prerequisite;
  final LessonLink? nextLesson;

  int get durationMinutes => (durationSeconds / 60).ceil();

  int get currentPartNumber {
    for (final part in parts) {
      if (part.status == LessonPartStatus.current) {
        return part.number;
      }
    }
    return progress.isCompleted ? parts.length : 1;
  }

  Lesson copyWith({
    String? routeId,
    String? objective,
    List<LessonPart>? parts,
    JlptLevel? level,
    List<LessonVocabularyItem>? vocabulary,
    List<LessonRelatedGrammar>? relatedGrammar,
    LessonProgress? progress,
    LessonAvailability? availability,
    LessonLink? nextLesson,
    LessonPrerequisite? prerequisite,
    bool clearLockedReason = false,
    bool clearPrerequisite = false,
  }) {
    return Lesson(
      routeId: routeId ?? this.routeId,
      remoteLessonId: remoteLessonId,
      title: title,
      focus: focus,
      level: level ?? this.level,
      category: category,
      curriculum: curriculum,
      chapterNumber: chapterNumber,
      lessonNumber: lessonNumber,
      durationSeconds: durationSeconds,
      objective: objective ?? this.objective,
      parts: parts ?? this.parts,
      vocabulary: vocabulary ?? this.vocabulary,
      detailVocabularyCount: detailVocabularyCount,
      videoVocabularyCount: videoVocabularyCount,
      relatedGrammar: relatedGrammar ?? this.relatedGrammar,
      article: article,
      progress: progress ?? this.progress,
      availability: availability ?? this.availability,
      noteCount: noteCount,
      streakDays: streakDays,
      detailXp: detailXp,
      completionXp: completionXp,
      masteryItems: masteryItems,
      mediaSource: mediaSource,
      lockedReason: clearLockedReason ? null : lockedReason,
      prerequisite: clearPrerequisite
          ? null
          : prerequisite ?? this.prerequisite,
      nextLesson: nextLesson ?? this.nextLesson,
    );
  }
}

@immutable
class LessonProgress {
  const LessonProgress({
    required this.progressPercent,
    required this.resumePositionSeconds,
    required this.isCompleted,
    this.completedAt,
  });

  final int progressPercent;
  final int resumePositionSeconds;
  final bool isCompleted;
  final DateTime? completedAt;

  double get fraction => progressPercent.clamp(0, 100) / 100;
}

@immutable
class LessonPart {
  const LessonPart({
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
  final LessonPartStatus status;
}

@immutable
class LessonVocabularyItem {
  const LessonVocabularyItem({
    required this.word,
    required this.reading,
    required this.meaning,
    required this.isSaved,
  });

  final String word;
  final String reading;
  final String meaning;
  final bool isSaved;

  LessonVocabularyItem copyWith({bool? isSaved}) {
    return LessonVocabularyItem(
      word: word,
      reading: reading,
      meaning: meaning,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

@immutable
class LessonRelatedGrammar {
  const LessonRelatedGrammar({
    required this.number,
    required this.title,
    required this.description,
    this.isSaved = false,
  });

  final int number;
  final String title;
  final String description;
  final bool isSaved;

  LessonRelatedGrammar copyWith({bool? isSaved}) {
    return LessonRelatedGrammar(
      number: number,
      title: title,
      description: description,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

@immutable
class LessonArticle {
  const LessonArticle({
    required this.formulas,
    required this.meaning,
    required this.usageSteps,
    required this.examples,
    required this.importantNotes,
  });

  final List<String> formulas;
  final String meaning;
  final List<String> usageSteps;
  final List<LessonExample> examples;
  final List<String> importantNotes;
}

@immutable
class LessonExample {
  const LessonExample({
    required this.japanese,
    required this.reading,
    required this.translation,
  });

  final String japanese;
  final String reading;
  final String translation;
}

@immutable
class LessonPrerequisite {
  const LessonPrerequisite({
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

  LessonPrerequisite copyWith({String? routeId}) {
    return LessonPrerequisite(
      routeId: routeId ?? this.routeId,
      lessonNumber: lessonNumber,
      title: title,
      focus: focus,
      progressPercent: progressPercent,
      completedParts: completedParts,
      totalParts: totalParts,
      remainingMinutes: remainingMinutes,
    );
  }
}

@immutable
class LessonLink {
  const LessonLink({
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
  final JlptLevel level;

  LessonLink copyWith({String? routeId, JlptLevel? level}) {
    return LessonLink(
      routeId: routeId ?? this.routeId,
      lessonNumber: lessonNumber,
      title: title,
      subtitle: subtitle,
      durationMinutes: durationMinutes,
      level: level ?? this.level,
    );
  }
}

@immutable
class LessonMasteryItem {
  const LessonMasteryItem({required this.title, required this.description});

  final String title;
  final String description;
}
