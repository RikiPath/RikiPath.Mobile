class MockTestSummaryDto {
  const MockTestSummaryDto({
    required this.mockTestId,
    required this.title,
    required this.description,
    required this.jlptLevelName,
    required this.timeLimitMinutes,
  });

  factory MockTestSummaryDto.fromJson(Map<String, Object?> json) {
    return MockTestSummaryDto(
      mockTestId: _requiredInt(json, 'mockTestId'),
      title: _requiredString(json, 'title'),
      description: _optionalString(json, 'description') ?? '',
      jlptLevelName: _optionalString(json, 'jlptLevelName') ?? '',
      timeLimitMinutes: _requiredInt(json, 'timeLimitMinutes'),
    );
  }

  final int mockTestId;
  final String title;
  final String description;
  final String jlptLevelName;
  final int timeLimitMinutes;
}

class StartAttemptDto {
  const StartAttemptDto({
    required this.attemptId,
    required this.mockTestId,
    required this.startedAt,
    required this.timeLimitMinutes,
    required this.previouslyWrongQuestionIds,
    required this.questions,
  });

  factory StartAttemptDto.fromJson(Map<String, Object?> json) {
    return StartAttemptDto(
      attemptId: _requiredInt(json, 'attemptId'),
      mockTestId: _requiredInt(json, 'mockTestId'),
      startedAt: _requiredDateTime(json, 'startedAt'),
      timeLimitMinutes: _requiredInt(json, 'timeLimitMinutes'),
      previouslyWrongQuestionIds: _intList(
        json['previouslyWrongQuestionIds'],
        'previouslyWrongQuestionIds',
      ),
      questions: _objectList(
        json['questions'],
        'questions',
      ).map(StartAttemptQuestionDto.fromJson).toList(growable: false),
    );
  }

  final int attemptId;
  final int mockTestId;
  final DateTime startedAt;
  final int timeLimitMinutes;
  final List<int> previouslyWrongQuestionIds;
  final List<StartAttemptQuestionDto> questions;
}

class StartAttemptQuestionDto {
  const StartAttemptQuestionDto({
    required this.questionId,
    required this.mockTestSectionId,
    required this.sectionTitle,
    required this.sectionOrder,
    required this.order,
    required this.content,
    required this.audioUrl,
    required this.imageUrl,
    required this.options,
  });

  factory StartAttemptQuestionDto.fromJson(Map<String, Object?> json) {
    return StartAttemptQuestionDto(
      questionId: _requiredInt(json, 'questionId'),
      mockTestSectionId: _requiredInt(json, 'mockTestSectionId'),
      sectionTitle: _requiredString(json, 'sectionTitle'),
      sectionOrder: _requiredInt(json, 'sectionOrder'),
      order: _requiredInt(json, 'order'),
      content: _requiredString(json, 'content'),
      audioUrl: _optionalString(json, 'audioUrl'),
      imageUrl: _optionalString(json, 'imageUrl'),
      options: _objectList(
        json['options'],
        'options',
      ).map(StartAttemptOptionDto.fromJson).toList(growable: false),
    );
  }

  final int questionId;
  final int mockTestSectionId;
  final String sectionTitle;
  final int sectionOrder;
  final int order;
  final String content;
  final String? audioUrl;
  final String? imageUrl;
  final List<StartAttemptOptionDto> options;
}

class StartAttemptOptionDto {
  const StartAttemptOptionDto({
    required this.optionId,
    required this.content,
    required this.order,
  });

  factory StartAttemptOptionDto.fromJson(Map<String, Object?> json) {
    return StartAttemptOptionDto(
      optionId: _requiredInt(json, 'optionId'),
      content: _requiredString(json, 'content'),
      order: _requiredInt(json, 'order'),
    );
  }

  final int optionId;
  final String content;
  final int order;
}

class AttemptResultDto {
  const AttemptResultDto({
    required this.attemptId,
    required this.mockTestId,
    required this.status,
    required this.startedAt,
    required this.submittedAt,
    required this.totalScore,
    required this.wrongQuestionIds,
    required this.sections,
  });

  factory AttemptResultDto.fromJson(Map<String, Object?> json) {
    return AttemptResultDto(
      attemptId: _requiredInt(json, 'attemptId'),
      mockTestId: _requiredInt(json, 'mockTestId'),
      status: _requiredString(json, 'status'),
      startedAt: _requiredDateTime(json, 'startedAt'),
      submittedAt: _optionalDateTime(json, 'submittedAt'),
      totalScore: _requiredDouble(json, 'totalScore'),
      wrongQuestionIds: _intList(json['wrongQuestionIds'], 'wrongQuestionIds'),
      sections: _objectList(
        json['sections'],
        'sections',
      ).map(MockTestSectionResultDto.fromJson).toList(growable: false),
    );
  }

  final int attemptId;
  final int mockTestId;
  final String status;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final double totalScore;
  final List<int> wrongQuestionIds;
  final List<MockTestSectionResultDto> sections;
}

class MockTestSectionResultDto {
  const MockTestSectionResultDto({
    required this.mockTestSectionId,
    required this.sectionTitle,
    required this.languageSkillName,
    required this.correctCount,
    required this.totalCount,
    required this.score,
  });

  factory MockTestSectionResultDto.fromJson(Map<String, Object?> json) {
    return MockTestSectionResultDto(
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

class DetailedAttemptResultDto {
  const DetailedAttemptResultDto({
    required this.attemptId,
    required this.mockTestId,
    required this.totalScore,
    required this.questions,
  });

  factory DetailedAttemptResultDto.fromJson(Map<String, Object?> json) {
    return DetailedAttemptResultDto(
      attemptId: _requiredInt(json, 'attemptId'),
      mockTestId: _requiredInt(json, 'mockTestId'),
      totalScore: _requiredDouble(json, 'totalScore'),
      questions: _objectList(
        json['questions'],
        'questions',
      ).map(MockTestQuestionReviewDto.fromJson).toList(growable: false),
    );
  }

  final int attemptId;
  final int mockTestId;
  final double totalScore;
  final List<MockTestQuestionReviewDto> questions;
}

class MockTestQuestionReviewDto {
  const MockTestQuestionReviewDto({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.selectedOptionId,
    required this.isCorrect,
    required this.explanation,
  });

  factory MockTestQuestionReviewDto.fromJson(Map<String, Object?> json) {
    return MockTestQuestionReviewDto(
      questionId: _requiredInt(json, 'questionId'),
      questionText: _requiredString(json, 'questionText'),
      options: _objectList(
        json['options'],
        'options',
      ).map(MockTestReviewOptionDto.fromJson).toList(growable: false),
      selectedOptionId: _optionalInt(json, 'selectedOptionId'),
      isCorrect: _requiredBool(json, 'isCorrect'),
      explanation: _optionalString(json, 'explanation'),
    );
  }

  final int questionId;
  final String questionText;
  final List<MockTestReviewOptionDto> options;
  final int? selectedOptionId;
  final bool isCorrect;
  final String? explanation;
}

class MockTestReviewOptionDto {
  const MockTestReviewOptionDto({
    required this.optionId,
    required this.optionText,
    required this.isCorrect,
  });

  factory MockTestReviewOptionDto.fromJson(Map<String, Object?> json) {
    return MockTestReviewOptionDto(
      optionId: _requiredInt(json, 'optionId'),
      optionText: _requiredString(json, 'optionText'),
      isCorrect: _requiredBool(json, 'isCorrect'),
    );
  }

  final int optionId;
  final String optionText;
  final bool isCorrect;
}

List<MockTestSummaryDto> readMockTestSummaries(Object? body) {
  return _objectList(
    _readEnvelopeResult(body),
    'result',
  ).map(MockTestSummaryDto.fromJson).toList(growable: false);
}

StartAttemptDto readStartAttempt(Object? body) {
  return StartAttemptDto.fromJson(
    _objectMap(_readEnvelopeResult(body), 'result'),
  );
}

AttemptResultDto readAttemptResult(Object? body) {
  return AttemptResultDto.fromJson(
    _objectMap(_readEnvelopeResult(body), 'result'),
  );
}

DetailedAttemptResultDto readDetailedAttemptResult(Object? body) {
  return DetailedAttemptResultDto.fromJson(
    _objectMap(_readEnvelopeResult(body), 'result'),
  );
}

Object? _readEnvelopeResult(Object? body) {
  final envelope = _objectMap(body, 'response');
  if (envelope['isSuccess'] != true) {
    throw const FormatException('Expected a successful Mock Test response.');
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

String _requiredString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Expected $field to be text.');
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
