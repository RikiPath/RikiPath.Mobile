import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_practice.dart';

/// Sử dụng API PracticeExercise hiện có vì danh sách của endpoint này trả ID bài tập.
class ApiLessonPracticeRepository implements LessonPracticeRepository {
  const ApiLessonPracticeRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<LessonPracticeExercise>> loadForLesson(int lessonId) async {
    final response = await _client.get<Object?>(
      '/api/PracticeExercise/lesson/$lessonId',
    );
    final result = _result(response.data);
    if (result is! List<Object?>) {
      throw const FormatException('Practice exercise list is invalid.');
    }
    return result
        .map((item) {
          final json = _object(item);
          final exercise = LessonPracticeExercise(
            id: _positiveInt(json, 'id'),
            lessonId: _positiveInt(json, 'lessonId'),
            title: _string(json, 'title'),
            description: _optionalString(json, 'description'),
            questionCount: _nonNegativeInt(json, 'questionCount'),
            bestScorePercent: _optionalNumber(json, 'bestScorePercent'),
          );
          if (exercise.lessonId != lessonId) {
            throw const FormatException(
              'Practice exercise belongs to another lesson.',
            );
          }
          return exercise;
        })
        .toList(growable: false);
  }

  @override
  Future<LessonPracticeAttempt> start(int exerciseId) async {
    final response = await _client.post<Object?>(
      '/api/PracticeExercise/$exerciseId/start',
    );
    final json = _object(_result(response.data));
    final questions = _list(json, 'questions')
        .map((item) {
          final question = _object(item);
          return LessonPracticeQuestion(
            id: _positiveInt(question, 'id'),
            text: _string(question, 'questionText'),
            options: _list(question, 'options')
                .map((item) {
                  final option = _object(item);
                  return LessonPracticeOption(
                    id: _positiveInt(option, 'id'),
                    text: _string(option, 'optionText'),
                  );
                })
                .toList(growable: false),
          );
        })
        .toList(growable: false);
    final saved = <int, int>{};
    final savedText = <int, String>{};
    for (final item in _list(json, 'savedAnswers')) {
      final answer = _object(item);
      final questionId = _positiveInt(answer, 'questionId');
      final selectedId = answer['selectedOptionId'];
      if (selectedId is int && selectedId > 0) {
        saved[questionId] = selectedId;
      }
      final text = answer['textAnswer'];
      if (text is String && text.trim().isNotEmpty) {
        savedText[questionId] = text;
      }
    }
    final attempt = LessonPracticeAttempt(
      attemptId: _positiveInt(json, 'attemptId'),
      exerciseId: _positiveInt(json, 'practiceExerciseId'),
      title: _string(json, 'title'),
      questions: questions,
      savedOptionIds: saved,
      savedTextAnswers: savedText,
      resumed: json['resumed'] == true,
    );
    if (attempt.exerciseId != exerciseId) {
      throw const FormatException(
        'Practice attempt belongs to another exercise.',
      );
    }
    return attempt;
  }

  @override
  Future<LessonPracticeResult> submit({
    required int attemptId,
    required Map<int, int> selectedOptionIds,
    required Map<int, String> textAnswers,
  }) async {
    final response = await _client.post<Object?>(
      '/api/PracticeExercise/attempt/$attemptId/submit',
      data: <String, Object?>{
        'answers': <Map<String, Object?>>[
          for (final questionId in {
            ...selectedOptionIds.keys,
            ...textAnswers.keys,
          })
            <String, Object?>{
              'questionId': questionId,
              'selectedOptionId': selectedOptionIds[questionId],
              'textAnswer': textAnswers[questionId],
            },
        ],
      },
    );
    final json = _object(_result(response.data));
    final result = LessonPracticeResult(
      attemptId: _positiveInt(json, 'attemptId'),
      scorePercent: _number(json, 'scorePercent'),
      correctCount: _nonNegativeInt(json, 'correctCount'),
      gradedQuestions: _nonNegativeInt(json, 'gradedQuestions'),
      totalQuestions: _nonNegativeInt(json, 'totalQuestions'),
    );
    if (result.attemptId != attemptId) {
      throw const FormatException(
        'Practice result belongs to another attempt.',
      );
    }
    return result;
  }
}

Object? _result(Object? body) {
  final envelope = _object(body);
  if (envelope['isSuccess'] != true) {
    throw const FormatException('Practice response was not successful.');
  }
  return envelope['result'];
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map<Object?, Object?> ||
      value.keys.any((key) => key is! String)) {
    throw const FormatException('Expected a JSON object.');
  }
  return value.cast<String, Object?>();
}

List<Object?> _list(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! List<Object?>) {
    throw FormatException('Expected a list field named $field.');
  }
  return value;
}

int _positiveInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int && value > 0) return value;
  throw FormatException('Expected a positive integer field named $field.');
}

int _nonNegativeInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int && value >= 0) return value;
  throw FormatException('Expected a non-negative integer field named $field.');
}

String _string(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('Expected a string field named $field.');
}

String? _optionalString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null || value is String) return value as String?;
  throw FormatException('Expected a nullable string field named $field.');
}

double _number(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is num) return value.toDouble();
  throw FormatException('Expected a number field named $field.');
}

double? _optionalNumber(Map<String, Object?> json, String field) {
  if (json[field] == null) return null;
  return _number(json, field);
}
