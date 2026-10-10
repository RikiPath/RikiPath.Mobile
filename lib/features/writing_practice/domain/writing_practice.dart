import 'package:flutter/foundation.dart';

enum WritingScript { hiragana, katakana, kanji }

enum KanjiWritingCollection { due, all }

enum WritingPracticeMode { guided, free }

enum WritingSubmissionStatus { idle, submitting, succeeded, failed }

@immutable
class WritingQueueRequest {
  const WritingQueueRequest({
    required this.script,
    this.kanjiCollection = KanjiWritingCollection.due,
  });

  final WritingScript script;
  final KanjiWritingCollection kanjiCollection;

  int get count => 100;

  @override
  bool operator ==(Object other) =>
      other is WritingQueueRequest &&
      other.script == script &&
      other.kanjiCollection == kanjiCollection;

  @override
  int get hashCode => Object.hash(script, kanjiCollection);
}

@immutable
class WritingCharacter {
  const WritingCharacter({
    required this.id,
    required this.character,
    required this.script,
    required this.strokeCount,
    required this.isNew,
    this.romaji,
    this.meaning,
    this.onYomi,
    this.kunYomi,
    this.strokeOrderImageUrl,
    this.audioUrl,
    this.writingScore,
    this.writingPracticeMode,
  }) : assert(id > 0),
       assert(character != ''),
       assert(strokeCount >= 0);

  final int id;
  final String character;
  final WritingScript script;
  final int strokeCount;
  final bool isNew;
  final String? romaji;
  final String? meaning;
  final String? onYomi;
  final String? kunYomi;
  final String? strokeOrderImageUrl;
  final String? audioUrl;
  final int? writingScore;
  final WritingPracticeMode? writingPracticeMode;
}

@immutable
class WritingPracticeResult {
  const WritingPracticeResult({
    required this.totalMistakes,
    required this.correctStrokeCount,
    required this.totalStrokeCount,
  }) : assert(totalMistakes >= 0),
       assert(correctStrokeCount >= 0),
       assert(totalStrokeCount > 0);

  final int totalMistakes;
  final int correctStrokeCount;
  final int totalStrokeCount;

  int scoreFor(int verifiedStrokeCount) {
    final strokes = verifiedStrokeCount > 0
        ? verifiedStrokeCount
        : totalStrokeCount;
    return (100 - (totalMistakes / strokes) * 40).round().clamp(0, 100).toInt();
  }
}

@immutable
class WritingSubmissionReceipt {
  const WritingSubmissionReceipt({
    required this.characterId,
    required this.totalMistakes,
    required this.qualityScore,
    required this.repetitions,
    required this.intervalDays,
    required this.nextReviewDate,
    this.score,
  });

  final int characterId;
  final int totalMistakes;
  final int qualityScore;
  final int repetitions;
  final int intervalDays;
  final DateTime nextReviewDate;
  final int? score;
}

@immutable
class KanjiWritingScore {
  const KanjiWritingScore({
    required this.kanjiId,
    required this.score,
    required this.correctStrokeCount,
    required this.totalStrokeCount,
    required this.practiceMode,
    required this.completedAt,
  });

  final int kanjiId;
  final int score;
  final int correctStrokeCount;
  final int totalStrokeCount;
  final WritingPracticeMode practiceMode;
  final DateTime completedAt;
}

@immutable
class WritingPracticeState {
  const WritingPracticeState({
    required this.items,
    this.selectedCharacterId,
    this.practiceMode = WritingPracticeMode.guided,
    this.localResult,
    this.submissionStatus = WritingSubmissionStatus.idle,
    this.receipt,
    this.submissionError,
  });

  final List<WritingCharacter> items;
  final int? selectedCharacterId;
  final WritingPracticeMode practiceMode;
  final WritingPracticeResult? localResult;
  final WritingSubmissionStatus submissionStatus;
  final WritingSubmissionReceipt? receipt;
  final Object? submissionError;

  WritingCharacter? get selectedCharacter {
    final id = selectedCharacterId;
    if (id == null) return null;
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool get canRetrySubmission =>
      localResult != null && submissionStatus == WritingSubmissionStatus.failed;

  WritingPracticeState copyWith({
    int? selectedCharacterId,
    bool clearSelectedCharacter = false,
    WritingPracticeMode? practiceMode,
    WritingPracticeResult? localResult,
    bool clearLocalResult = false,
    WritingSubmissionStatus? submissionStatus,
    WritingSubmissionReceipt? receipt,
    bool clearReceipt = false,
    Object? submissionError,
    bool clearSubmissionError = false,
  }) {
    return WritingPracticeState(
      items: items,
      selectedCharacterId: clearSelectedCharacter
          ? null
          : selectedCharacterId ?? this.selectedCharacterId,
      practiceMode: practiceMode ?? this.practiceMode,
      localResult: clearLocalResult ? null : localResult ?? this.localResult,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      receipt: clearReceipt ? null : receipt ?? this.receipt,
      submissionError: clearSubmissionError
          ? null
          : submissionError ?? this.submissionError,
    );
  }
}
