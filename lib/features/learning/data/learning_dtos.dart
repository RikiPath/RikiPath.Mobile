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

class LessonDetailDto {
  const LessonDetailDto({
    required this.lessonId,
    required this.certificateLevelId,
    required this.levelCode,
    required this.languageSkillId,
    required this.languageSkillName,
    required this.title,
    required this.content,
    required this.orderIndex,
    required this.progressPercent,
    required this.resumePositionSeconds,
    required this.isCompleted,
    required this.completedAt,
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
      orderIndex: _requiredInt(json, 'orderIndex'),
      progressPercent: _requiredInt(json, 'progressPercent'),
      resumePositionSeconds: _requiredInt(json, 'resumePositionSeconds'),
      isCompleted: _requiredBool(json, 'isCompleted'),
      completedAt: _optionalDateTime(json, 'completedAt'),
    );
  }

  final int lessonId;
  final int certificateLevelId;
  final String levelCode;
  final int languageSkillId;
  final String languageSkillName;
  final String title;
  final String content;
  final int orderIndex;
  final int progressPercent;
  final int resumePositionSeconds;
  final bool isCompleted;
  final DateTime? completedAt;
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
