class PlacementTestStatusDto {
  const PlacementTestStatusDto({
    required this.attemptType,
    required this.hasActiveAttempt,
    required this.activeAttemptId,
    required this.activeAttemptExpiresAt,
    required this.hasCompletedPlacementTest,
    required this.latestCompletedAttemptId,
    required this.latestSubmittedAt,
    required this.latestScorePercent,
    required this.assessedJlptLevelId,
    required this.assessedJlptLevelName,
    required this.recommendedTargetJlptLevelId,
    required this.recommendedTargetJlptLevelName,
    required this.targetJlptLevelId,
    required this.targetJlptLevelName,
    required this.dailyStudyMinutes,
    required this.targetExamDate,
    required this.isReadyForLearningPath,
    this.placementDecision = 'NOT_TAKEN',
  });

  factory PlacementTestStatusDto.fromJson(Map<String, Object?> json) {
    return PlacementTestStatusDto(
      attemptType: _requiredPlacementType(json),
      hasActiveAttempt: _optionalBool(json, 'hasActiveAttempt') ?? false,
      activeAttemptId: _optionalInt(json, 'activeAttemptId'),
      activeAttemptExpiresAt: _optionalDateTime(json, 'activeAttemptExpiresAt'),
      hasCompletedPlacementTest: _requiredBool(
        json,
        'hasCompletedPlacementTest',
      ),
      latestCompletedAttemptId:
          _optionalInt(json, 'latestCompletedAttemptId') ??
          _optionalInt(json, 'latestAttemptId'),
      latestSubmittedAt: _optionalDateTime(json, 'latestSubmittedAt'),
      latestScorePercent: _optionalDouble(json, 'latestScorePercent'),
      assessedJlptLevelId: _optionalInt(json, 'assessedJlptLevelId'),
      assessedJlptLevelName: _optionalString(json, 'assessedJlptLevelName'),
      recommendedTargetJlptLevelId: _optionalInt(
        json,
        'recommendedTargetJlptLevelId',
      ),
      recommendedTargetJlptLevelName: _optionalString(
        json,
        'recommendedTargetJlptLevelName',
      ),
      targetJlptLevelId: _optionalInt(json, 'targetJlptLevelId'),
      targetJlptLevelName: _optionalString(json, 'targetJlptLevelName'),
      dailyStudyMinutes: _optionalInt(json, 'dailyStudyMinutes') ?? 0,
      targetExamDate: _optionalDateTime(json, 'targetExamDate'),
      isReadyForLearningPath: json['isReadyForLearningPath'] is bool
          ? json['isReadyForLearningPath']! as bool
          : false,
      placementDecision:
          _optionalString(json, 'placementDecision') ?? 'NOT_TAKEN',
    );
  }

  final String attemptType;
  final bool hasActiveAttempt;
  final int? activeAttemptId;
  final DateTime? activeAttemptExpiresAt;
  final bool hasCompletedPlacementTest;
  final int? latestCompletedAttemptId;
  int? get latestAttemptId => latestCompletedAttemptId;
  final DateTime? latestSubmittedAt;
  final double? latestScorePercent;
  final int? assessedJlptLevelId;
  final String? assessedJlptLevelName;
  final int? recommendedTargetJlptLevelId;
  final String? recommendedTargetJlptLevelName;
  final int? targetJlptLevelId;
  final String? targetJlptLevelName;
  final int dailyStudyMinutes;
  final DateTime? targetExamDate;
  final bool isReadyForLearningPath;
  final String placementDecision;
}

class StartPlacementTestDto {
  const StartPlacementTestDto({
    required this.attemptId,
    required this.attemptType,
    required this.status,
    required this.isResumed,
    required this.startedAt,
    required this.expiresAt,
    required this.serverNow,
    required this.timeLimitMinutes,
    required this.totalQuestions,
    required this.questions,
  });

  factory StartPlacementTestDto.fromJson(Map<String, Object?> json) {
    final startedAt = _requiredDateTime(json, 'startedAt');
    final timeLimitMinutes = _requiredInt(json, 'timeLimitMinutes');
    return StartPlacementTestDto(
      attemptId: _requiredInt(json, 'attemptId'),
      attemptType: _requiredPlacementType(json),
      status: _optionalString(json, 'status') ?? 'inProgress',
      isResumed: _optionalBool(json, 'isResumed') ?? false,
      startedAt: startedAt,
      expiresAt:
          _optionalDateTime(json, 'expiresAt') ??
          startedAt.add(Duration(minutes: timeLimitMinutes)),
      serverNow: _requiredDateTime(json, 'serverNow'),
      timeLimitMinutes: timeLimitMinutes,
      totalQuestions: _requiredInt(json, 'totalQuestions'),
      questions: _objectList(
        json['questions'],
        'questions',
      ).map(PlacementTestQuestionDto.fromJson).toList(growable: false),
    );
  }

  final int attemptId;
  final String attemptType;
  final String status;
  final bool isResumed;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime serverNow;
  final int timeLimitMinutes;
  final int totalQuestions;
  final List<PlacementTestQuestionDto> questions;
}

class PlacementTestQuestionDto {
  const PlacementTestQuestionDto({
    required this.questionId,
    required this.mockTestId,
    required this.mockTestSectionId,
    required this.sectionTitle,
    required this.sectionOrder,
    required this.jlptLevelId,
    required this.jlptLevelName,
    required this.order,
    required this.content,
    required this.audioUrl,
    required this.imageUrl,
    required this.options,
  });

  factory PlacementTestQuestionDto.fromJson(Map<String, Object?> json) {
    return PlacementTestQuestionDto(
      questionId: _requiredInt(json, 'questionId'),
      mockTestId: _requiredInt(json, 'mockTestId'),
      mockTestSectionId: _requiredInt(json, 'mockTestSectionId'),
      sectionTitle: _requiredString(json, 'sectionTitle'),
      sectionOrder: _requiredInt(json, 'sectionOrder'),
      jlptLevelId: _requiredInt(json, 'jlptLevelId'),
      jlptLevelName: _requiredString(json, 'jlptLevelName'),
      order: _requiredInt(json, 'order'),
      content: _requiredString(json, 'content'),
      audioUrl: _optionalString(json, 'audioUrl'),
      imageUrl: _optionalString(json, 'imageUrl'),
      options: _objectList(
        json['options'],
        'options',
      ).map(PlacementTestOptionDto.fromJson).toList(growable: false),
    );
  }

  final int questionId;
  final int mockTestId;
  final int mockTestSectionId;
  final String sectionTitle;
  final int sectionOrder;
  final int jlptLevelId;
  final String jlptLevelName;
  final int order;
  final String content;
  final String? audioUrl;
  final String? imageUrl;
  final List<PlacementTestOptionDto> options;
}

class PlacementTestOptionDto {
  const PlacementTestOptionDto({
    required this.optionId,
    required this.content,
    required this.order,
  });

  factory PlacementTestOptionDto.fromJson(Map<String, Object?> json) {
    return PlacementTestOptionDto(
      optionId: _requiredInt(json, 'optionId'),
      content: _requiredString(json, 'content'),
      order: _requiredInt(json, 'order'),
    );
  }

  final int optionId;
  final String content;
  final int order;
}

class PlacementLevelBreakdownDto {
  const PlacementLevelBreakdownDto({
    required this.jlptLevelId,
    required this.jlptLevelName,
    required this.correctCount,
    required this.totalCount,
    required this.scorePercent,
  });

  factory PlacementLevelBreakdownDto.fromJson(Map<String, Object?> json) {
    return PlacementLevelBreakdownDto(
      jlptLevelId: _requiredInt(json, 'jlptLevelId'),
      jlptLevelName: _requiredString(json, 'jlptLevelName'),
      correctCount: _requiredInt(json, 'correctCount'),
      totalCount: _requiredInt(json, 'totalCount'),
      scorePercent: _requiredDouble(json, 'scorePercent'),
    );
  }

  final int jlptLevelId;
  final String jlptLevelName;
  final int correctCount;
  final int totalCount;
  final double scorePercent;
}

class PlacementSectionResultDto {
  const PlacementSectionResultDto({
    required this.mockTestSectionId,
    required this.sectionTitle,
    required this.languageSkillName,
    required this.correctCount,
    required this.totalCount,
    required this.score,
  });

  factory PlacementSectionResultDto.fromJson(Map<String, Object?> json) {
    return PlacementSectionResultDto(
      mockTestSectionId: _requiredInt(json, 'mockTestSectionId'),
      sectionTitle: _requiredString(json, 'sectionTitle'),
      languageSkillName: _requiredString(json, 'languageSkillName'),
      correctCount: _requiredInt(json, 'correctCount'),
      totalCount: _requiredInt(json, 'totalCount'),
      score: _requiredDouble(json, 'score'),
    );
  }

  final int mockTestSectionId;
  final String sectionTitle;
  final String languageSkillName;
  final int correctCount;
  final int totalCount;
  final double score;
}

class PlacementTestResultDto {
  const PlacementTestResultDto({
    required this.attemptId,
    required this.attemptType,
    required this.status,
    required this.startedAt,
    required this.submittedAt,
    required this.totalScore,
    required this.correctCount,
    required this.totalQuestions,
    required this.assessedJlptLevelId,
    required this.assessedJlptLevelName,
    required this.recommendedTargetJlptLevelId,
    required this.recommendedTargetJlptLevelName,
    required this.wrongQuestionIds,
    required this.levelBreakdowns,
    required this.sections,
  });

  factory PlacementTestResultDto.fromJson(Map<String, Object?> json) {
    return PlacementTestResultDto(
      attemptId: _requiredInt(json, 'attemptId'),
      attemptType: _requiredPlacementType(json),
      status: _requiredString(json, 'status'),
      startedAt: _requiredDateTime(json, 'startedAt'),
      submittedAt: _optionalDateTime(json, 'submittedAt'),
      totalScore: _requiredDouble(json, 'totalScore'),
      correctCount: _requiredInt(json, 'correctCount'),
      totalQuestions: _requiredInt(json, 'totalQuestions'),
      assessedJlptLevelId: _requiredInt(json, 'assessedJlptLevelId'),
      assessedJlptLevelName: _requiredString(json, 'assessedJlptLevelName'),
      recommendedTargetJlptLevelId: _requiredInt(
        json,
        'recommendedTargetJlptLevelId',
      ),
      recommendedTargetJlptLevelName: _requiredString(
        json,
        'recommendedTargetJlptLevelName',
      ),
      wrongQuestionIds: _intList(json['wrongQuestionIds'], 'wrongQuestionIds'),
      levelBreakdowns: _objectList(
        json['levelBreakdowns'],
        'levelBreakdowns',
      ).map(PlacementLevelBreakdownDto.fromJson).toList(growable: false),
      sections: _objectList(
        json['sections'],
        'sections',
      ).map(PlacementSectionResultDto.fromJson).toList(growable: false),
    );
  }

  final int attemptId;
  final String attemptType;
  final String status;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final double totalScore;
  final int correctCount;
  final int totalQuestions;
  final int assessedJlptLevelId;
  final String assessedJlptLevelName;
  final int recommendedTargetJlptLevelId;
  final String recommendedTargetJlptLevelName;
  final List<int> wrongQuestionIds;
  final List<PlacementLevelBreakdownDto> levelBreakdowns;
  final List<PlacementSectionResultDto> sections;
}

PlacementTestStatusDto readPlacementTestStatus(Object? body) {
  return PlacementTestStatusDto.fromJson(
    _objectMap(_readEnvelopeResult(body), 'result'),
  );
}

StartPlacementTestDto readStartPlacementTest(Object? body) {
  return StartPlacementTestDto.fromJson(
    _objectMap(_readEnvelopeResult(body), 'result'),
  );
}

StartPlacementTestDto? readActivePlacementTest(Object? body) {
  final result = _readEnvelopeResult(body);
  return result == null
      ? null
      : StartPlacementTestDto.fromJson(_objectMap(result, 'result'));
}

PlacementTestResultDto readPlacementTestResult(Object? body) {
  return PlacementTestResultDto.fromJson(
    _objectMap(_readEnvelopeResult(body), 'result'),
  );
}

Object? _readEnvelopeResult(Object? body) {
  final envelope = _objectMap(body, 'response');
  if (envelope['isSuccess'] != true) {
    throw const FormatException(
      'Expected a successful Placement Test response.',
    );
  }
  return envelope['result'];
}

Map<String, Object?> _objectMap(Object? value, String field) {
  if (value is! Map<Object?, Object?>) {
    throw FormatException('Expected $field to be an object.');
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<Map<String, Object?>> _objectList(Object? value, String field) {
  if (value is! List<Object?>) {
    throw FormatException('Expected $field to be an array.');
  }
  return value.map((item) => _objectMap(item, field)).toList(growable: false);
}

List<int> _intList(Object? value, String field) {
  if (value is! List<Object?>) {
    throw FormatException('Expected $field to be an array.');
  }
  return value
      .map((item) {
        if (item is int) return item;
        throw FormatException('Expected $field to contain integers.');
      })
      .toList(growable: false);
}

int _requiredInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  throw FormatException('Expected $field to be an integer.');
}

int? _optionalInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  return _requiredInt(json, field);
}

double _requiredDouble(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is num) return value.toDouble();
  throw FormatException('Expected $field to be numeric.');
}

double? _optionalDouble(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  return _requiredDouble(json, field);
}

String _requiredString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Expected $field to be text.');
}

String _requiredPlacementType(Map<String, Object?> json) {
  final value = _requiredString(json, 'attemptType');
  if (value != 'placement') {
    throw FormatException('Unsupported Placement Test attemptType: $value');
  }
  return value;
}

String? _optionalString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Expected $field to be text.');
}

bool _requiredBool(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is bool) return value;
  throw FormatException('Expected $field to be a boolean.');
}

bool? _optionalBool(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  return _requiredBool(json, field);
}

DateTime _requiredDateTime(Map<String, Object?> json, String field) {
  final value = _requiredString(json, field);
  return DateTime.tryParse(value)?.toUtc() ??
      (throw FormatException('Expected $field to be an ISO timestamp.'));
}

DateTime? _optionalDateTime(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  return _requiredDateTime(json, field);
}
