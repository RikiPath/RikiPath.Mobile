import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice.dart';

class KanaWritingQueueItemDto {
  const KanaWritingQueueItemDto({
    required this.kanaCharacterId,
    required this.character,
    required this.type,
    required this.romaji,
    required this.strokeCount,
    required this.isNew,
    this.strokeOrderImageUrl,
    this.audioUrl,
  });

  factory KanaWritingQueueItemDto.fromJson(Map<String, Object?> json) {
    return KanaWritingQueueItemDto(
      kanaCharacterId: _requiredPositiveInt(json, 'kanaCharacterId'),
      character: _requiredNonEmptyString(json, 'character'),
      type: switch (_requiredNonEmptyString(json, 'type')) {
        'Hiragana' => WritingScript.hiragana,
        'Katakana' => WritingScript.katakana,
        final value => throw FormatException('Unknown Kana type: $value.'),
      },
      romaji: _requiredNonEmptyString(json, 'romaji'),
      strokeCount: _requiredNonNegativeInt(json, 'strokeCount'),
      strokeOrderImageUrl: _optionalString(json, 'strokeOrderImageUrl'),
      audioUrl: _optionalString(json, 'audioUrl'),
      isNew: _requiredBool(json, 'isNew'),
    );
  }

  final int kanaCharacterId;
  final String character;
  final WritingScript type;
  final String romaji;
  final int strokeCount;
  final String? strokeOrderImageUrl;
  final String? audioUrl;
  final bool isNew;

  WritingCharacter toDomain() => WritingCharacter(
    id: kanaCharacterId,
    character: character,
    script: type,
    romaji: romaji,
    strokeCount: strokeCount,
    strokeOrderImageUrl: strokeOrderImageUrl,
    audioUrl: audioUrl,
    isNew: isNew,
  );
}

class KanjiWritingQueueItemDto {
  const KanjiWritingQueueItemDto({
    required this.kanjiId,
    required this.character,
    required this.meaning,
    required this.strokeCount,
    required this.isNew,
    this.onYomi,
    this.kunYomi,
    this.writingScore,
    this.writingPracticeMode,
  });

  factory KanjiWritingQueueItemDto.fromJson(Map<String, Object?> json) {
    return KanjiWritingQueueItemDto(
      kanjiId: _requiredPositiveInt(json, 'kanjiId'),
      character: _requiredNonEmptyString(json, 'character'),
      meaning: _requiredString(json, 'meaning'),
      onYomi: _optionalString(json, 'onYomi'),
      kunYomi: _optionalString(json, 'kunYomi'),
      strokeCount: _requiredNonNegativeInt(json, 'strokeCount'),
      writingScore: _optionalBoundedInt(
        json,
        'writingScore',
        minimum: 0,
        maximum: 100,
      ),
      writingPracticeMode: switch (_optionalString(
        json,
        'writingPracticeMode',
      )) {
        'guided' => WritingPracticeMode.guided,
        'free' => WritingPracticeMode.free,
        null => null,
        _ => null,
      },
      isNew: _requiredBool(json, 'isNew'),
    );
  }

  final int kanjiId;
  final String character;
  final String meaning;
  final String? onYomi;
  final String? kunYomi;
  final int strokeCount;
  final int? writingScore;
  final WritingPracticeMode? writingPracticeMode;
  final bool isNew;

  WritingCharacter toDomain() => WritingCharacter(
    id: kanjiId,
    character: character,
    script: WritingScript.kanji,
    meaning: meaning,
    onYomi: onYomi,
    kunYomi: kunYomi,
    strokeCount: strokeCount,
    writingScore: writingScore,
    writingPracticeMode: writingPracticeMode,
    isNew: isNew,
  );
}

class KanaWritingSubmissionDto {
  const KanaWritingSubmissionDto({
    required this.practiceCardId,
    required this.kanaCharacterId,
    required this.totalMistakes,
    required this.qualityScore,
    required this.repetitions,
    required this.intervalDays,
    required this.nextReviewDate,
  });

  factory KanaWritingSubmissionDto.fromJson(Map<String, Object?> json) {
    return KanaWritingSubmissionDto(
      practiceCardId: _requiredPositiveInt(json, 'practiceCardId'),
      kanaCharacterId: _requiredPositiveInt(json, 'kanaCharacterId'),
      totalMistakes: _requiredNonNegativeInt(json, 'totalMistakes'),
      qualityScore: _requiredNonNegativeInt(json, 'qualityScore'),
      repetitions: _requiredNonNegativeInt(json, 'repetitions'),
      intervalDays: _requiredNonNegativeInt(json, 'intervalDays'),
      nextReviewDate: _requiredDateTime(json, 'nextReviewDate'),
    );
  }

  final int practiceCardId;
  final int kanaCharacterId;
  final int totalMistakes;
  final int qualityScore;
  final int repetitions;
  final int intervalDays;
  final DateTime nextReviewDate;

  WritingSubmissionReceipt toDomain() => WritingSubmissionReceipt(
    characterId: kanaCharacterId,
    totalMistakes: totalMistakes,
    qualityScore: qualityScore,
    repetitions: repetitions,
    intervalDays: intervalDays,
    nextReviewDate: nextReviewDate,
  );
}

class KanjiWritingSubmissionDto {
  const KanjiWritingSubmissionDto({
    required this.reviewCardId,
    required this.totalMistakes,
    required this.qualityScore,
    required this.repetitions,
    required this.intervalDays,
    required this.nextReviewDate,
    required this.score,
  });

  factory KanjiWritingSubmissionDto.fromJson(Map<String, Object?> json) {
    return KanjiWritingSubmissionDto(
      reviewCardId: _requiredPositiveInt(json, 'reviewCardId'),
      totalMistakes: _requiredNonNegativeInt(json, 'totalMistakes'),
      qualityScore: _requiredNonNegativeInt(json, 'qualityScore'),
      repetitions: _requiredNonNegativeInt(json, 'repetitions'),
      intervalDays: _requiredNonNegativeInt(json, 'intervalDays'),
      nextReviewDate: _requiredDateTime(json, 'nextReviewDate'),
      score: _requiredBoundedInt(json, 'score', minimum: 0, maximum: 100),
    );
  }

  final int reviewCardId;
  final int totalMistakes;
  final int qualityScore;
  final int repetitions;
  final int intervalDays;
  final DateTime nextReviewDate;
  final int score;

  WritingSubmissionReceipt toDomain(int kanjiId) => WritingSubmissionReceipt(
    characterId: kanjiId,
    totalMistakes: totalMistakes,
    qualityScore: qualityScore,
    repetitions: repetitions,
    intervalDays: intervalDays,
    nextReviewDate: nextReviewDate,
    score: score,
  );
}

class KanjiWritingScoreDto {
  const KanjiWritingScoreDto({
    required this.kanjiId,
    required this.score,
    required this.correctStrokeCount,
    required this.totalStrokeCount,
    required this.practiceMode,
    required this.completedAt,
  });

  factory KanjiWritingScoreDto.fromJson(Map<String, Object?> json) {
    return KanjiWritingScoreDto(
      kanjiId: _requiredPositiveInt(json, 'kanjiId'),
      score: _requiredBoundedInt(json, 'score', minimum: 0, maximum: 100),
      correctStrokeCount: _requiredNonNegativeInt(json, 'correctStrokeCount'),
      totalStrokeCount: _requiredNonNegativeInt(json, 'totalStrokeCount'),
      practiceMode: switch (_requiredNonEmptyString(json, 'practiceMode')) {
        'free' => WritingPracticeMode.free,
        _ => WritingPracticeMode.guided,
      },
      completedAt: _requiredDateTime(json, 'completedAt'),
    );
  }

  final int kanjiId;
  final int score;
  final int correctStrokeCount;
  final int totalStrokeCount;
  final WritingPracticeMode practiceMode;
  final DateTime completedAt;

  KanjiWritingScore toDomain() => KanjiWritingScore(
    kanjiId: kanjiId,
    score: score,
    correctStrokeCount: correctStrokeCount,
    totalStrokeCount: totalStrokeCount,
    practiceMode: practiceMode,
    completedAt: completedAt,
  );
}

Map<String, Object?> readWritingResultObject(Object? body) {
  final envelope = _readEnvelope(body);
  final result = envelope['result'];
  if (result is! Map<Object?, Object?>) {
    throw const FormatException('Expected a Writing result object.');
  }
  return result.map((key, value) => MapEntry(key.toString(), value));
}

List<Map<String, Object?>> readWritingResultList(Object? body) {
  final envelope = _readEnvelope(body);
  final result = envelope['result'];
  if (result is! List<Object?>) {
    throw const FormatException('Expected a Writing result list.');
  }
  return result
      .map((item) {
        if (item is! Map<Object?, Object?>) {
          throw const FormatException('Expected a Writing result item.');
        }
        return item.map((key, value) => MapEntry(key.toString(), value));
      })
      .toList(growable: false);
}

Map<Object?, Object?> _readEnvelope(Object? body) {
  if (body is! Map<Object?, Object?> || body['isSuccess'] != true) {
    throw const FormatException('Expected a successful Writing API envelope.');
  }
  return body;
}

int _requiredPositiveInt(Map<String, Object?> json, String key) {
  final value = _readInt(json[key]);
  if (value == null || value <= 0) {
    throw FormatException('Expected a positive integer field: $key.');
  }
  return value;
}

int _requiredNonNegativeInt(Map<String, Object?> json, String key) {
  final value = _readInt(json[key]);
  if (value == null || value < 0) {
    throw FormatException('Expected a non-negative integer field: $key.');
  }
  return value;
}

int _requiredBoundedInt(
  Map<String, Object?> json,
  String key, {
  required int minimum,
  required int maximum,
}) {
  final value = _readInt(json[key]);
  if (value == null || value < minimum || value > maximum) {
    throw FormatException('Expected $key between $minimum and $maximum.');
  }
  return value;
}

int? _optionalBoundedInt(
  Map<String, Object?> json,
  String key, {
  required int minimum,
  required int maximum,
}) {
  if (json[key] == null) return null;
  return _requiredBoundedInt(json, key, minimum: minimum, maximum: maximum);
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  return null;
}

String _requiredNonEmptyString(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key).trim();
  if (value.isEmpty) {
    throw FormatException('Expected a non-empty string field: $key.');
  }
  return value;
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Expected a string field: $key.');
  }
  return value;
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Expected a string field: $key.');
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

bool _requiredBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('Expected a boolean field: $key.');
  }
  return value;
}

DateTime _requiredDateTime(Map<String, Object?> json, String key) {
  final value = _requiredNonEmptyString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('Expected an ISO-8601 timestamp field: $key.');
  }
  return parsed;
}
