class LearningDiscoveryDto {
  const LearningDiscoveryDto({
    required this.certificateLevelId,
    required this.levelCode,
    required this.totalLessons,
    required this.completedLessons,
    required this.overallProgressPercent,
    required this.lessons,
  });

  factory LearningDiscoveryDto.fromJson(Map<String, Object?> json) {
    return LearningDiscoveryDto(
      certificateLevelId: _requiredInt(json, 'certificateLevelId'),
      levelCode: _requiredString(json, 'levelCode'),
      totalLessons: _requiredInt(json, 'totalLessons'),
      completedLessons: _requiredInt(json, 'completedLessons'),
      overallProgressPercent: _requiredInt(json, 'overallProgressPercent'),
      lessons: _objectList(
        json['lessons'],
        'lessons',
      ).map(LearningLessonSummaryDto.fromJson).toList(growable: false),
    );
  }

  final int certificateLevelId;
  final String levelCode;
  final int totalLessons;
  final int completedLessons;
  final int overallProgressPercent;
  final List<LearningLessonSummaryDto> lessons;
}

class LearningLessonSummaryDto {
  const LearningLessonSummaryDto({
    required this.lessonId,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.languageSkillId,
    required this.languageSkillName,
    required this.progressPercent,
    required this.resumePositionSeconds,
    required this.isCompleted,
    required this.completedAt,
  });

  factory LearningLessonSummaryDto.fromJson(Map<String, Object?> json) {
    return LearningLessonSummaryDto(
      lessonId: _requiredInt(json, 'lessonId'),
      title: _requiredString(json, 'title'),
      description: _optionalString(json, 'description'),
      sortOrder: _requiredInt(json, 'sortOrder'),
      languageSkillId: _requiredInt(json, 'languageSkillId'),
      languageSkillName: _requiredString(json, 'languageSkillName'),
      progressPercent: _requiredInt(json, 'progressPercent'),
      resumePositionSeconds: _requiredInt(json, 'resumePositionSeconds'),
      isCompleted: _requiredBool(json, 'isCompleted'),
      completedAt: _optionalDateTime(json, 'completedAt'),
    );
  }

  final int lessonId;
  final String title;
  final String? description;
  final int sortOrder;
  final int languageSkillId;
  final String languageSkillName;
  final int progressPercent;
  final int resumePositionSeconds;
  final bool isCompleted;
  final DateTime? completedAt;
}

class LessonVocabularyDto {
  const LessonVocabularyDto({
    required this.vocabularyId,
    required this.word,
    required this.reading,
    required this.meaning,
    required this.exampleSentence,
    required this.exampleSentenceMeaning,
    required this.audioUrl,
  });

  factory LessonVocabularyDto.fromJson(Map<String, Object?> json) =>
      LessonVocabularyDto(
        vocabularyId: _requiredInt(json, 'vocabularyId'),
        word: _requiredString(json, 'word'),
        reading: _requiredString(json, 'reading'),
        meaning: _requiredString(json, 'meaning'),
        exampleSentence: _optionalString(json, 'exampleSentence'),
        exampleSentenceMeaning: _optionalString(json, 'exampleSentenceMeaning'),
        audioUrl: _optionalUri(json, 'audioUrl'),
      );

  final int vocabularyId;
  final String word;
  final String reading;
  final String meaning;
  final String? exampleSentence;
  final String? exampleSentenceMeaning;
  final Uri? audioUrl;
}

class LessonKanjiDto {
  const LessonKanjiDto({
    required this.kanjiId,
    required this.character,
    required this.meaning,
    required this.sinoVietnamese,
    required this.onYomi,
    required this.kunYomi,
    required this.strokeCount,
    required this.strokeOrderImageUrl,
    required this.audioUrl,
  });

  factory LessonKanjiDto.fromJson(Map<String, Object?> json) => LessonKanjiDto(
    kanjiId: _requiredInt(json, 'kanjiId'),
    character: _requiredString(json, 'character'),
    meaning: _requiredString(json, 'meaning'),
    sinoVietnamese: _optionalString(json, 'sinoVietnamese'),
    onYomi: _optionalString(json, 'onYomi'),
    kunYomi: _optionalString(json, 'kunYomi'),
    strokeCount: _requiredInt(json, 'strokeCount'),
    strokeOrderImageUrl: _optionalUri(json, 'strokeOrderImageUrl'),
    audioUrl: _optionalUri(json, 'audioUrl'),
  );

  final int kanjiId;
  final String character;
  final String meaning;
  final String? sinoVietnamese;
  final String? onYomi;
  final String? kunYomi;
  final int strokeCount;
  final Uri? strokeOrderImageUrl;
  final Uri? audioUrl;
}

class LessonGrammarDto {
  const LessonGrammarDto({
    required this.grammarPatternId,
    required this.title,
    required this.structure,
    required this.usageNotes,
    required this.exampleSentence,
    required this.exampleSentenceMeaning,
  });

  factory LessonGrammarDto.fromJson(Map<String, Object?> json) =>
      LessonGrammarDto(
        grammarPatternId: _requiredInt(json, 'grammarPatternId'),
        title: _requiredString(json, 'title'),
        structure: _requiredString(json, 'structure'),
        usageNotes: _optionalString(json, 'usageNotes'),
        exampleSentence: _optionalString(json, 'exampleSentence'),
        exampleSentenceMeaning: _optionalString(json, 'exampleSentenceMeaning'),
      );

  final int grammarPatternId;
  final String title;
  final String structure;
  final String? usageNotes;
  final String? exampleSentence;
  final String? exampleSentenceMeaning;
}

class LessonDetailDto {
  const LessonDetailDto({
    required this.lessonId,
    required this.certificateLevelId,
    required this.levelCode,
    required this.languageSkillId,
    required this.languageSkillName,
    required this.title,
    required this.content,
    required this.videoUrl,
    required this.attachmentUrl,
    required this.orderIndex,
    required this.progressPercent,
    required this.resumePositionSeconds,
    required this.isCompleted,
    required this.completedAt,
    this.vocabularies = const <LessonVocabularyDto>[],
    this.kanjis = const <LessonKanjiDto>[],
    this.grammars = const <LessonGrammarDto>[],
  });

  factory LessonDetailDto.fromJson(Map<String, Object?> json) {
    return LessonDetailDto(
      lessonId: _requiredInt(json, 'lessonId'),
      certificateLevelId: _requiredInt(json, 'certificateLevelId'),
      levelCode: _requiredString(json, 'levelCode'),
      languageSkillId: _requiredInt(json, 'languageSkillId'),
      languageSkillName: _requiredString(json, 'languageSkillName'),
      title: _requiredString(json, 'title'),
      content: _requiredString(json, 'content'),
      videoUrl: _optionalUri(json, 'videoUrl'),
      attachmentUrl: _optionalUri(json, 'attachmentUrl'),
      orderIndex: _requiredInt(json, 'orderIndex'),
      progressPercent: _requiredInt(json, 'progressPercent'),
      resumePositionSeconds: _requiredInt(json, 'resumePositionSeconds'),
      isCompleted: _requiredBool(json, 'isCompleted'),
      completedAt: _optionalDateTime(json, 'completedAt'),
      vocabularies: _optionalObjectList(
        json['vocabularies'],
        'vocabularies',
      ).map(LessonVocabularyDto.fromJson).toList(growable: false),
      kanjis: _optionalObjectList(
        json['kanjis'],
        'kanjis',
      ).map(LessonKanjiDto.fromJson).toList(growable: false),
      grammars: _optionalObjectList(
        json['grammars'],
        'grammars',
      ).map(LessonGrammarDto.fromJson).toList(growable: false),
    );
  }

  final int lessonId;
  final int certificateLevelId;
  final String levelCode;
  final int languageSkillId;
  final String languageSkillName;
  final String title;
  final String content;
  final Uri? videoUrl;
  final Uri? attachmentUrl;
  final int orderIndex;
  final int progressPercent;
  final int resumePositionSeconds;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<LessonVocabularyDto> vocabularies;
  final List<LessonKanjiDto> kanjis;
  final List<LessonGrammarDto> grammars;
}

LearningDiscoveryDto readLearningDiscovery(Object? body) =>
    LearningDiscoveryDto.fromJson(_successfulResult(body));

LessonDetailDto readLessonDetail(Object? body) =>
    LessonDetailDto.fromJson(_successfulResult(body));

Map<String, Object?> _successfulResult(Object? body) {
  final envelope = _stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const FormatException('Expected a successful learning envelope.');
  }
  return _stringKeyedMap(envelope['result']);
}

Map<String, Object?> _stringKeyedMap(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Expected a JSON object.');
  }
  return value.map((key, item) {
    if (key is! String) throw const FormatException('Expected string keys.');
    return MapEntry(key, item);
  });
}

List<Map<String, Object?>> _objectList(Object? value, String field) {
  if (value is! List<Object?>) {
    throw FormatException('Expected a list field named $field.');
  }
  return value.map(_stringKeyedMap).toList(growable: false);
}

List<Map<String, Object?>> _optionalObjectList(Object? value, String field) {
  if (value == null) return const <Map<String, Object?>>[];
  return _objectList(value, field);
}

int _requiredInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int) return value;
  throw FormatException('Expected an integer field named $field.');
}

String _requiredString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Expected a string field named $field.');
}

String? _optionalString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null || value is String) return value as String?;
  throw FormatException('Expected a nullable string field named $field.');
}

bool _requiredBool(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is bool) return value;
  throw FormatException('Expected a boolean field named $field.');
}

DateTime? _optionalDateTime(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toUtc();
  }
  throw FormatException('Expected a nullable timestamp field named $field.');
}

Uri? _optionalUri(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String) {
    final uri = Uri.tryParse(value.trim());
    if (uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http')) {
      return uri;
    }
  }
  throw FormatException('Expected a nullable HTTP URL field named $field.');
}
