class RecommendedLearningPathDto {
  const RecommendedLearningPathDto({
    required this.userId,
    required this.generatedAt,
    required this.summary,
    required this.strengths,
    required this.weaknesses,
    required this.feasibility,
    required this.isExamDateRealistic,
    required this.recommendedStudyDays,
    required this.suggestedExamDate,
    required this.focusTopics,
    required this.dailySchedules,
    this.pathId,
    this.version,
    this.status,
    this.startingJlptLevelId,
    this.targetJlptLevelId,
    this.baseActivePathId,
    this.previewExpiresAt,
    this.confirmedAt,
    this.horizon,
    this.planDurationDays,
    this.targetExamDate,
    this.daysUntilExam,
    this.hasTargetExamDate,
  });

  factory RecommendedLearningPathDto.fromJson(Map<String, Object?> json) {
    return RecommendedLearningPathDto(
      userId: _requiredPositiveInt(json, 'userId'),
      generatedAt: _requiredDateTime(json, 'generatedAt'),
      summary: _requiredString(json, 'summary'),
      strengths: _stringList(json, 'strengths'),
      weaknesses: _stringList(json, 'weaknesses'),
      feasibility: _requiredString(json, 'feasibility'),
      isExamDateRealistic: _optionalBool(json, 'isExamDateRealistic'),
      recommendedStudyDays: _requiredNonNegativeInt(
        json,
        'recommendedStudyDays',
      ),
      suggestedExamDate: _optionalDateTime(json, 'suggestedExamDate'),
      focusTopics: _stringList(json, 'focusTopics'),
      dailySchedules: _objectList(
        json,
        'dailySchedules',
      ).map(RecommendedLearningDayDto.fromJson).toList(growable: false),
      pathId: _optionalPositiveInt(json, 'pathId'),
      version: _optionalPositiveInt(json, 'version'),
      status: _optionalString(json, 'status'),
      startingJlptLevelId: _optionalPositiveInt(json, 'startingJlptLevelId'),
      targetJlptLevelId: _optionalPositiveInt(json, 'targetJlptLevelId'),
      baseActivePathId: _optionalPositiveInt(json, 'baseActivePathId'),
      previewExpiresAt: _optionalDateTime(json, 'previewExpiresAt'),
      confirmedAt: _optionalDateTime(json, 'confirmedAt'),
      horizon: _optionalString(json, 'horizon'),
      planDurationDays: _optionalNonNegativeInt(json, 'planDurationDays'),
      targetExamDate: _optionalDateTime(json, 'targetExamDate'),
      daysUntilExam: _optionalNonNegativeInt(json, 'daysUntilExam'),
      hasTargetExamDate: _optionalBool(json, 'hasTargetExamDate'),
    );
  }

  final int userId;
  final DateTime generatedAt;
  final String summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final String feasibility;
  final bool? isExamDateRealistic;
  final int recommendedStudyDays;
  final DateTime? suggestedExamDate;
  final List<String> focusTopics;
  final List<RecommendedLearningDayDto> dailySchedules;
  final int? pathId;
  final int? version;
  final String? status;
  final int? startingJlptLevelId;
  final int? targetJlptLevelId;
  final int? baseActivePathId;
  final DateTime? previewExpiresAt;
  final DateTime? confirmedAt;
  final String? horizon;
  final int? planDurationDays;
  final DateTime? targetExamDate;
  final int? daysUntilExam;
  final bool? hasTargetExamDate;
}

class RecommendedLearningDayDto {
  const RecommendedLearningDayDto({
    required this.day,
    required this.title,
    required this.focus,
    required this.lessonIds,
    required this.lessons,
    this.canStart,
    this.isStarted,
    this.isCompleted,
    this.startedAt,
    this.completedAt,
  });

  factory RecommendedLearningDayDto.fromJson(Map<String, Object?> json) {
    final lessonIds = _positiveIntList(json, 'lessonIds');
    final lessons = _stringList(json, 'lessons');
    if (lessonIds.length != lessons.length) {
      throw const FormatException(
        'Recommended lesson IDs and titles must have the same length.',
      );
    }
    return RecommendedLearningDayDto(
      day: _requiredPositiveInt(json, 'day'),
      title: _requiredString(json, 'title'),
      focus: _requiredString(json, 'focus'),
      lessonIds: lessonIds,
      lessons: lessons,
      canStart: _optionalBool(json, 'canStart'),
      isStarted: _optionalBool(json, 'isStarted'),
      isCompleted: _optionalBool(json, 'isCompleted'),
      startedAt: _optionalDateTime(json, 'startedAt'),
      completedAt: _optionalDateTime(json, 'completedAt'),
    );
  }

  final int day;
  final String title;
  final String focus;
  final List<int> lessonIds;
  final List<String> lessons;
  final bool? canStart;
  final bool? isStarted;
  final bool? isCompleted;
  final DateTime? startedAt;
  final DateTime? completedAt;
}

RecommendedLearningPathDto readRecommendedLearningPath(Object? body) {
  final envelope = _stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const FormatException(
      'Expected a successful learning-path envelope.',
    );
  }
  return RecommendedLearningPathDto.fromJson(
    _stringKeyedMap(envelope['result']),
  );
}

RecommendedLearningPathDto? readOptionalRecommendedLearningPath(Object? body) {
  final envelope = _stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const FormatException(
      'Expected a successful learning-path envelope.',
    );
  }
  final result = envelope['result'];
  if (result == null) return null;
  return RecommendedLearningPathDto.fromJson(_stringKeyedMap(result));
}

List<RecommendedLearningPathDto> readLearningPathHistory(Object? body) {
  final envelope = _stringKeyedMap(body);
  if (envelope['isSuccess'] != true) {
    throw const FormatException(
      'Expected a successful learning-path envelope.',
    );
  }
  final result = envelope['result'];
  if (result is! List<Object?>) {
    throw const FormatException('Expected a learning-path history list.');
  }
  return result
      .map((item) => RecommendedLearningPathDto.fromJson(_stringKeyedMap(item)))
      .toList(growable: false);
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

List<Map<String, Object?>> _objectList(
  Map<String, Object?> json,
  String field,
) {
  final value = json[field];
  if (value is! List<Object?>) {
    throw FormatException('Expected a list field named $field.');
  }
  return value.map(_stringKeyedMap).toList(growable: false);
}

List<String> _stringList(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! List<Object?> || value.any((item) => item is! String)) {
    throw FormatException('Expected a string list field named $field.');
  }
  return value.cast<String>().toList(growable: false);
}

List<int> _positiveIntList(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! List<Object?>) {
    throw FormatException('Expected an integer list field named $field.');
  }
  return value
      .map((item) {
        if (item is int && item > 0) return item;
        throw FormatException('Expected positive integers in $field.');
      })
      .toList(growable: false);
}

String _requiredString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Expected a string field named $field.');
}

String? _optionalString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Expected a nullable string field named $field.');
}

int? _optionalPositiveInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is int && value > 0) return value;
  throw FormatException(
    'Expected a nullable positive integer field named $field.',
  );
}

int _requiredPositiveInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int && value > 0) return value;
  throw FormatException('Expected a positive integer field named $field.');
}

int _requiredNonNegativeInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int && value >= 0) return value;
  throw FormatException('Expected a non-negative integer field named $field.');
}

bool? _optionalBool(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is bool) return value;
  throw FormatException('Expected a nullable boolean field named $field.');
}

int? _optionalNonNegativeInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is int && value >= 0) return value;
  throw FormatException(
    'Expected a nullable non-negative integer field named $field.',
  );
}

DateTime _requiredDateTime(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toUtc();
  }
  throw FormatException('Expected an ISO-8601 field named $field.');
}

DateTime? _optionalDateTime(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toUtc();
  }
  throw FormatException('Expected a nullable ISO-8601 field named $field.');
}
