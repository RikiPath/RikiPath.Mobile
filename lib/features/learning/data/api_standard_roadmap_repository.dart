import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap_repository.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

class ApiStandardRoadmapRepository implements StandardRoadmapRepository {
  const ApiStandardRoadmapRepository(this._client);

  final ApiClient _client;

  @override
  Future<StandardRoadmap> load() async {
    final response = await _client.get<Object?>('/api/StandardRoadmap');
    try {
      final envelope = _map(response.data);
      if (envelope['isSuccess'] != true) {
        throw const FormatException('Expected a successful API envelope.');
      }
      final result = _map(envelope['result']);
      final rawLessons = result['lessons'];
      if (rawLessons is! List<Object?>) {
        throw const FormatException('Expected roadmap lessons.');
      }
      final lessons = rawLessons.map((item) {
        final lesson = _map(item);
        final progress = _int(lesson, 'progressPercent');
        if (progress < 0 || progress > 100) {
          throw const FormatException('Invalid lesson progress.');
        }
        return StandardRoadmapLesson(
          lessonId: _positiveInt(lesson, 'lessonId'),
          title: _string(lesson, 'title'),
          sortOrder: _int(lesson, 'sortOrder'),
          progressPercent: progress,
          isCompleted: _bool(lesson, 'isCompleted'),
        );
      }).toList(growable: false);
      final total = _int(result, 'totalLessons');
      final completed = _int(result, 'completedLessons');
      if (total < 0 || completed < 0 || completed > total || lessons.length != total) {
        throw const FormatException('Invalid roadmap counts.');
      }
      final mode = _string(result, 'learningMode');
      return StandardRoadmap(
        currentStudyLevelId: _positiveInt(result, 'currentStudyLevelId'),
        currentStudyLevelName: _string(result, 'currentStudyLevelName'),
        targetJlptLevelId: _optionalPositiveInt(result, 'targetJlptLevelId'),
        targetJlptLevelName: _optionalString(result, 'targetJlptLevelName'),
        learningMode: switch (mode) {
          'STANDARD' => LearningMode.standard,
          'AI_PERSONALIZED' => LearningMode.aiPersonalized,
          _ => throw const FormatException('Unsupported learning mode.'),
        },
        totalLessons: total,
        completedLessons: completed,
        nextLessonId: _optionalPositiveInt(result, 'nextLessonId'),
        lessons: lessons,
      );
    } on FormatException {
      throw const UnknownError(
        message: 'The Standard Roadmap response did not match the contract.',
      );
    }
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map<Object?, Object?>) {
    throw const FormatException('Expected JSON object.');
  }
  return value.map((key, item) {
    if (key is! String) throw const FormatException('Expected JSON keys.');
    return MapEntry(key, item);
  });
}

int _int(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('Expected integer $key.');
}

int _positiveInt(Map<String, Object?> json, String key) {
  final value = _int(json, key);
  if (value > 0) return value;
  throw FormatException('Expected positive integer $key.');
}

int? _optionalPositiveInt(Map<String, Object?> json, String key) {
  if (json[key] == null) return null;
  return _positiveInt(json, key);
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Expected string $key.');
}

String? _optionalString(Map<String, Object?> json, String key) {
  if (json[key] == null) return null;
  return _string(json, key);
}

bool _bool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('Expected boolean $key.');
}
